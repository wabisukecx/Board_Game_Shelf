import '../bgg/bgg_api_client.dart';
import '../bgg/bgg_token_provider.dart';
import '../bgg/bgg_xml_parser.dart';
import '../db/app_database.dart';
import '../../core/constants.dart';
import '../../domain/game_rank.dart';

class BggRegistrationRepository {
  BggRegistrationRepository({
    required AppDatabase database,
    required BggApi api,
    required BggXmlParser parser,
    required BggTokenProvider tokenProvider,
  }) : _database = database,
       _api = api,
       _parser = parser,
       _tokenProvider = tokenProvider;

  final AppDatabase _database;
  final BggApi _api;
  final BggXmlParser _parser;
  final BggTokenProvider _tokenProvider;

  Future<List<BggSearchResult>> search(
    String query, {
    bool exact = false,
  }) async {
    await _requireToken();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final source = await _api.searchGames(query: trimmed, exact: exact);
    return _parser.parseSearch(source);
  }

  Future<BggRegistrationResult> registerBggId(String bggId) async {
    final existing = await _database.findGame(bggId);
    if (existing != null) {
      return BggRegistrationAlreadyExists(existing);
    }

    final source = await _api.fetchThing(id: bggId);
    final details = _parser.parseThing(source);
    _validateDetails(details);

    final kind = await resolveGameKindWithLookup(
      details,
      api: _api,
      parser: _parser,
    );

    await _database.upsertBggGame(
      bggId: details.bggId,
      names: details.names,
      japaneseName: details.names.japanese,
      yearPublished: details.yearPublished,
      publisherMinPlayers: details.publisherMinPlayers,
      publisherMaxPlayers: details.publisherMaxPlayers,
      playingTime: details.playingTime,
      publisherMinAge: details.publisherMinAge,
      communityBestPlayers: details.communityBestPlayers,
      communityRecommendedPlayers: details.communityRecommendedPlayers,
      communityMinAge: details.communityMinAge,
      suggestedPlayerVotes: details.suggestedPlayerVotes,
      description: details.description,
      mechanics: [for (final value in details.mechanics) value.name],
      categories: [for (final value in details.categories) value.name],
      designers: [for (final value in details.designers) value.name],
      publishers: [for (final value in details.publishers) value.name],
      averageRating: details.averageRating,
      weight: double.tryParse(details.weight ?? ''),
      ranks: GameRanks(details.ranks),
      thumbnailUrl: details.thumbnailUrl,
      gameKind: kind.gameKind,
      parentGameKey: kind.parentGameKey,
    );

    if (await _database.findCollection(details.bggId) == null) {
      await _database.upsertCollection(
        CollectionEntriesCompanion.insert(gameKey: details.bggId),
      );
    }

    final game = await _database.findGame(details.bggId);
    if (game == null) {
      throw StateError('Registered game was not found: ${details.bggId}');
    }
    final expansionCandidates = <NamedBggValue>[];
    for (final candidate in details.expansionLinks) {
      final candidateId = candidate.bggId;
      if (candidateId == null || candidateId.isEmpty) {
        continue;
      }
      if (await _database.findGame(candidateId) == null) {
        expansionCandidates.add(candidate);
      }
    }
    return BggRegistrationCreated(
      game,
      expansionCandidates: expansionCandidates,
    );
  }

  Future<void> _requireToken() async {
    final token = await _tokenProvider.readToken();
    if (token == null || token.isEmpty) {
      throw const BggTokenRequiredException();
    }
  }

  void _validateDetails(BggGameDetails details) {
    if (details.bggId.trim().isEmpty) {
      throw const InvalidBggGameException('BGG ID is required');
    }
    final title = details.names.primary.trim();
    if (title.isEmpty || _placeholderTitles.contains(title)) {
      throw const InvalidBggGameException('A valid title is required');
    }
  }
}

GameKindResolution resolveGameKind(BggGameDetails details) {
  // BGG uses the same string for the item subtype (<item type="...">) and
  // expansion relationship links (<link type="...">). Treat an item as an
  // expansion only when its own subtype is boardgameexpansion.
  final isExpansionItem = details.itemType == AppConstants.bggExpansionLinkType;
  if (isExpansionItem && details.expandsGame != null) {
    return GameKindResolution(
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: details.expandsGame?.bggId,
    );
  }
  return const GameKindResolution(
    gameKind: AppConstants.gameKindBase,
    parentGameKey: null,
  );
}

Future<GameKindResolution> resolveGameKindWithLookup(
  BggGameDetails details, {
  required BggApi api,
  required BggXmlParser parser,
}) async {
  final fallback = resolveGameKind(details);
  if (details.itemType != AppConstants.bggExpansionLinkType) {
    return fallback;
  }

  final seen = <String>{};
  final candidates = [
    for (final candidate in details.expansionRelationshipLinks)
      if (candidate.bggId case final id?)
        if (id.isNotEmpty && id != details.bggId && seen.add(id)) candidate,
  ];
  if (candidates.isEmpty) {
    return fallback;
  }

  for (final candidate in candidates) {
    final id = candidate.bggId;
    if (id == null || id.isEmpty) {
      continue;
    }
    try {
      final source = await api.fetchThing(id: id, stats: false);
      final candidateDetails = parser.parseThing(source);
      if (candidateDetails.itemType == AppConstants.bggCollectionSubtype) {
        return GameKindResolution(
          gameKind: AppConstants.gameKindExpansion,
          parentGameKey: id,
        );
      }
    } catch (_) {
      continue;
    }
  }

  return fallback;
}

class GameKindResolution {
  const GameKindResolution({required this.gameKind, this.parentGameKey});

  final String gameKind;
  final String? parentGameKey;
}

sealed class BggRegistrationResult {
  const BggRegistrationResult(this.game);

  final Game game;
}

class BggRegistrationCreated extends BggRegistrationResult {
  const BggRegistrationCreated(
    super.game, {
    this.expansionCandidates = const [],
  });

  final List<NamedBggValue> expansionCandidates;
}

class BggRegistrationAlreadyExists extends BggRegistrationResult {
  const BggRegistrationAlreadyExists(super.game);

  List<NamedBggValue> get expansionCandidates => const [];
}

class BggTokenRequiredException implements Exception {
  const BggTokenRequiredException();

  @override
  String toString() => 'BggTokenRequiredException';
}

class InvalidBggGameException implements Exception {
  const InvalidBggGameException(this.message);

  final String message;

  @override
  String toString() => 'InvalidBggGameException: $message';
}

const _placeholderTitles = {'不明なゲーム', 'Unknown', 'Unknown Game'};
