import '../../core/clock.dart';
import '../../core/constants.dart';
import '../../domain/game_rank.dart';
import '../../domain/update_history.dart';
import '../bgg/bgg_api_client.dart';
import '../bgg/bgg_xml_parser.dart';
import '../db/app_database.dart';
import 'bgg_registration_repository.dart';

class InformationUpdateRepository {
  InformationUpdateRepository({
    required AppDatabase database,
    required BggApi api,
    required BggXmlParser parser,
    required Clock clock,
  }) : _database = database,
       _api = api,
       _parser = parser,
       _clock = clock;

  final AppDatabase _database;
  final BggApi _api;
  final BggXmlParser _parser;
  final Clock _clock;

  Future<InformationUpdatePreview> preview(String gameKey) async {
    final game = await _database.findGame(gameKey);
    if (game == null) {
      throw InformationUpdateException('Game not found: $gameKey');
    }
    if (game.bggId == null || game.localId != null) {
      throw InformationUpdateException(
        'Local records cannot be refreshed: $gameKey',
      );
    }

    final source = await _api.fetchThing(id: game.bggId!);
    final details = _parser.parseThing(source);
    final kind = await resolveGameKindWithLookup(
      details,
      api: _api,
      parser: _parser,
      relationshipCandidates: details.expansionRelationshipLinks,
    );
    final changes = _buildChanges(game, details, kind);
    final snapshot = _buildSnapshot(game, details);

    if (changes.isEmpty) {
      return InformationUpdateNoChanges(
        game: game,
        fetched: details,
        kind: kind,
      );
    }

    return InformationUpdateChanges(
      game: game,
      fetched: details,
      kind: kind,
      changes: changes,
      snapshot: snapshot,
    );
  }

  Future<void> apply(InformationUpdateChanges preview) async {
    final current = await _database.findGame(preview.game.gameKey);
    if (current == null) {
      throw InformationUpdateException(
        'Game not found: ${preview.game.gameKey}',
      );
    }

    final history = current.updateHistory.append(preview.snapshot);
    final fetched = preview.fetched;
    final kind = preview.kind;
    await _database.upsertBggGame(
      bggId: current.bggId!,
      names: fetched.names,
      japaneseName: fetched.names.japanese,
      yearPublished: fetched.yearPublished,
      publisherMinPlayers: fetched.publisherMinPlayers,
      publisherMaxPlayers: fetched.publisherMaxPlayers,
      playingTime: fetched.playingTime,
      publisherMinAge: fetched.publisherMinAge,
      communityBestPlayers: fetched.communityBestPlayers,
      communityRecommendedPlayers: fetched.communityRecommendedPlayers,
      communityMinAge: fetched.communityMinAge,
      suggestedPlayerVotes: fetched.suggestedPlayerVotes,
      description: fetched.description,
      descriptionJa: current.descriptionJa,
      mechanics: [for (final value in fetched.mechanics) value.name],
      categories: [for (final value in fetched.categories) value.name],
      designers: [for (final value in fetched.designers) value.name],
      publishers: [for (final value in fetched.publishers) value.name],
      averageRating: fetched.averageRating,
      weight: double.tryParse(fetched.weight ?? ''),
      ranks: GameRanks(fetched.ranks),
      updateHistory: history,
      thumbnailUrl: fetched.thumbnailUrl,
      gameKind: kind.gameKind,
      parentGameKey: kind.parentGameKey,
    );
  }

  List<InformationChange> _buildChanges(
    Game game,
    BggGameDetails fetched,
    GameKindResolution kind,
  ) {
    final changes = <InformationChange>[];
    _addChange(changes, 'game_kind', game.gameKind, kind.gameKind);
    _addChange(
      changes,
      'parent_game_key',
      game.parentGameKey,
      kind.parentGameKey,
    );
    _addChange(changes, 'name', game.name, fetched.names.primary);
    _addChange(
      changes,
      'japanese_name',
      game.japaneseName,
      fetched.names.japanese,
    );
    _addChange(
      changes,
      'year_published',
      game.yearPublished,
      fetched.yearPublished,
    );
    _addChange(
      changes,
      'average_rating',
      game.averageRating,
      fetched.averageRating,
    );
    _addChange(
      changes,
      'weight',
      game.weight,
      double.tryParse(fetched.weight ?? ''),
    );
    _addSetChanges(changes, 'mechanics', game.mechanics, [
      for (final value in fetched.mechanics) value.name,
    ]);
    _addSetChanges(changes, 'categories', game.categories, [
      for (final value in fetched.categories) value.name,
    ]);

    final oldRanks = _rankMap(game.ranks.values);
    final newRanks = _rankMap(fetched.ranks);
    for (final type in {...oldRanks.keys, ...newRanks.keys}) {
      if (_valuesDiffer(oldRanks[type], newRanks[type])) {
        changes.add(
          InformationChange(
            field: 'rank:$type',
            oldValue: oldRanks[type],
            newValue: newRanks[type],
          ),
        );
      }
    }

    return changes;
  }

  UpdateHistoryEntry _buildSnapshot(Game game, BggGameDetails fetched) {
    final changedRanks = <GameRank>[];
    final oldRanks = _rankMap(game.ranks.values);
    final newRanks = _rankMap(fetched.ranks);
    for (final entry in newRanks.entries) {
      if (_valuesDiffer(oldRanks[entry.key], entry.value)) {
        changedRanks.add(GameRank(type: entry.key, rank: entry.value));
      }
    }

    return UpdateHistoryEntry(
      date: _todayIso(),
      averageRating: _valuesDiffer(game.averageRating, fetched.averageRating)
          ? fetched.averageRating
          : null,
      weight: _valuesDiffer(game.weight, double.tryParse(fetched.weight ?? ''))
          ? fetched.weight
          : null,
      ranks: changedRanks,
    );
  }

  String _todayIso() => _clock.now().toIso8601String().substring(0, 10);

  void _addChange(
    List<InformationChange> changes,
    String field,
    Object? oldValue,
    Object? newValue,
  ) {
    if (_valuesDiffer(oldValue, newValue)) {
      changes.add(
        InformationChange(field: field, oldValue: oldValue, newValue: newValue),
      );
    }
  }

  void _addSetChanges(
    List<InformationChange> changes,
    String field,
    List<String> oldValues,
    List<String> newValues,
  ) {
    final oldSet = oldValues.toSet();
    final newSet = newValues.toSet();
    final added = newSet.difference(oldSet).toList()..sort();
    final removed = oldSet.difference(newSet).toList()..sort();
    if (added.isNotEmpty) {
      changes.add(
        InformationChange(
          field: '$field.added',
          oldValue: null,
          newValue: added,
        ),
      );
    }
    if (removed.isNotEmpty) {
      changes.add(
        InformationChange(
          field: '$field.removed',
          oldValue: removed,
          newValue: null,
        ),
      );
    }
  }

  Map<String, String> _rankMap(Iterable<GameRank> ranks) {
    return {
      for (final rank in ranks)
        if (rank.type.isNotEmpty) rank.type: rank.rank,
    };
  }

  bool _valuesDiffer(Object? oldValue, Object? newValue) {
    if (oldValue == null && newValue == null) {
      return false;
    }
    if (oldValue == null || newValue == null) {
      return true;
    }

    final oldNumber = _asNumber(oldValue);
    final newNumber = _asNumber(newValue);
    if (oldNumber != null && newNumber != null) {
      return (oldNumber - newNumber).abs() > AppConstants.numericDiffTolerance;
    }

    return '$oldValue' != '$newValue';
  }

  double? _asNumber(Object value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value');
  }
}

sealed class InformationUpdatePreview {
  const InformationUpdatePreview({
    required this.game,
    required this.fetched,
    required this.kind,
  });

  final Game game;
  final BggGameDetails fetched;
  final GameKindResolution kind;
}

class InformationUpdateNoChanges extends InformationUpdatePreview {
  const InformationUpdateNoChanges({
    required super.game,
    required super.fetched,
    required super.kind,
  });
}

class InformationUpdateChanges extends InformationUpdatePreview {
  const InformationUpdateChanges({
    required super.game,
    required super.fetched,
    required super.kind,
    required this.changes,
    required this.snapshot,
  });

  final List<InformationChange> changes;
  final UpdateHistoryEntry snapshot;
}

class InformationChange {
  const InformationChange({
    required this.field,
    required this.oldValue,
    required this.newValue,
  });

  final String field;
  final Object? oldValue;
  final Object? newValue;

  String get displayValue => '${_format(oldValue)} → ${_format(newValue)}';

  String _format(Object? value) {
    if (value == null) {
      return '';
    }
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number != null) {
      return number.toStringAsFixed(2);
    }
    return '$value';
  }
}

class InformationUpdateException implements Exception {
  InformationUpdateException(this.message);

  final String message;

  @override
  String toString() => 'InformationUpdateException: $message';
}
