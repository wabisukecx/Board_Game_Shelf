import '../bgg/bgg_api_client.dart';
import '../bgg/bgg_relationship_source.dart';
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
    required BggRelationshipSource relationshipSource,
    required BggTokenProvider tokenProvider,
  }) : _database = database,
       _api = api,
       _parser = parser,
       _relationshipSource = relationshipSource,
       _tokenProvider = tokenProvider;

  final AppDatabase _database;
  final BggApi _api;
  final BggXmlParser _parser;
  final BggRelationshipSource _relationshipSource;
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

    List<NamedBggValue>? relationshipCandidates;
    if (details.itemType == AppConstants.bggExpansionLinkType) {
      try {
        relationshipCandidates = await _relationshipSource
            .registrationCandidates(details.bggId);
      } catch (_) {
        // Parent resolution falls back to XML relationship links when the
        // relationship endpoint is temporarily unavailable.
      }
    }
    final kind = await resolveGameKindWithLookup(
      details,
      api: _api,
      parser: _parser,
      relationshipCandidates:
          relationshipCandidates ?? details.expansionRelationshipLinks,
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
    return BggRegistrationCreated(
      game,
      parentCandidates: kind.parentCandidates,
    );
  }

  Future<void> setParentGameKey(String gameKey, String parentGameKey) {
    return _database.updateParentGameKey(gameKey, parentGameKey);
  }

  Future<List<NamedBggValue>> fetchParentCandidates(String bggId) {
    return _relationshipSource.registrationCandidates(bggId);
  }

  Future<List<NamedBggValue>> fetchExpansionCandidates(String bggId) async {
    final candidates = await _relationshipSource.registrationCandidates(bggId);
    return _filterUnregisteredCandidates(bggId, candidates);
  }

  Future<List<NamedBggValue>> _filterUnregisteredCandidates(
    String selfBggId,
    List<NamedBggValue> candidates,
  ) async {
    final result = <NamedBggValue>[];
    final seenCandidateIds = <String>{};
    for (final candidate in candidates) {
      final candidateId = candidate.bggId;
      if (candidateId == null ||
          candidateId.isEmpty ||
          candidateId == selfBggId ||
          !seenCandidateIds.add(candidateId)) {
        continue;
      }
      if (await _database.findGame(candidateId) == null) {
        result.add(candidate);
      }
    }
    return result;
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
  required List<NamedBggValue> relationshipCandidates,
}) async {
  final fallback = resolveGameKind(details);
  if (details.itemType != AppConstants.bggExpansionLinkType) {
    return fallback;
  }

  final seen = <String>{};
  final candidates = [
    for (final candidate in relationshipCandidates)
      if (candidate.bggId case final id?)
        if (id.isNotEmpty && id != details.bggId && seen.add(id)) candidate,
  ];
  if (candidates.isEmpty) {
    return fallback;
  }

  final confirmedParents = <NamedBggValue>[];
  for (final candidate in candidates) {
    final id = candidate.bggId;
    if (id == null || id.isEmpty) {
      continue;
    }
    try {
      final source = await api.fetchThing(id: id, stats: false);
      final candidateDetails = parser.parseThing(source);
      if (candidateDetails.itemType == AppConstants.bggCollectionSubtype) {
        confirmedParents.add(candidate);
      }
    } catch (_) {
      continue;
    }
  }

  return switch (confirmedParents.length) {
    0 => fallback,
    1 => GameKindResolution(
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: confirmedParents.single.bggId,
    ),
    _ => GameKindResolution(
      gameKind: AppConstants.gameKindExpansion,
      parentCandidates: confirmedParents,
    ),
  };
}

class GameKindResolution {
  const GameKindResolution({
    required this.gameKind,
    this.parentGameKey,
    this.parentCandidates = const [],
  });

  final String gameKind;
  final String? parentGameKey;
  final List<NamedBggValue> parentCandidates;
}

sealed class BggRegistrationResult {
  const BggRegistrationResult(this.game);

  final Game game;
}

class BggRegistrationCreated extends BggRegistrationResult {
  const BggRegistrationCreated(super.game, {this.parentCandidates = const []});

  final List<NamedBggValue> parentCandidates;
}

class BggRegistrationAlreadyExists extends BggRegistrationResult {
  const BggRegistrationAlreadyExists(super.game);
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
