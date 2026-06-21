import 'package:drift/drift.dart' show OrderingTerm, Value;

import '../../core/constants.dart';
import '../db/app_database.dart';

class PlaySessionRepository {
  PlaySessionRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<int> recordSession(PlaySessionInput input) async {
    final game = await _database.findGame(input.gameKey);
    if (game == null) {
      throw const PlaySessionValidationException('Game not found');
    }
    if (game.gameKind == AppConstants.gameKindExpansion) {
      throw const PlaySessionValidationException(
        'Play sessions must be recorded on a base game',
      );
    }
    if (DateTime.tryParse(input.playedDate) == null) {
      throw const PlaySessionValidationException('Played date is invalid');
    }
    _validateIntRange(
      value: input.rating,
      min: AppConstants.playRatingMin,
      max: AppConstants.playRatingMax,
      field: 'rating',
    );
    _validateIntRange(
      value: input.replayDesire,
      min: AppConstants.playReplayDesireMin,
      max: AppConstants.playReplayDesireMax,
      field: 'replayDesire',
    );
    _validateDoubleRange(
      value: input.perceivedWeight,
      min: AppConstants.playPerceivedWeightMin,
      max: AppConstants.playPerceivedWeightMax,
      field: 'perceivedWeight',
    );

    final expansionGameKeys = _dedupe(input.expansionGameKeys);
    for (final expansionGameKey in expansionGameKeys) {
      final expansion = await _database.findGame(expansionGameKey);
      if (expansion == null ||
          expansion.gameKind != AppConstants.gameKindExpansion ||
          expansion.parentGameKey != input.gameKey) {
        throw const PlaySessionValidationException(
          'Expansion does not belong to the recorded game',
        );
      }
    }

    return _database.transaction(() async {
      final id = await _database
          .into(_database.playSessions)
          .insert(
            PlaySessionsCompanion.insert(
              gameKey: input.gameKey,
              playedDate: input.playedDate,
              playerCount: Value(input.playerCount),
              actualPlayingTime: Value(input.actualPlayingTime),
              notes: Value(input.notes),
              rating: Value(input.rating),
              replayDesire: Value(input.replayDesire),
              perceivedWeight: Value(input.perceivedWeight),
              winnerMemo: Value(input.winnerMemo),
            ),
          );
      for (final expansionGameKey in expansionGameKeys) {
        await _database
            .into(_database.playSessionExpansions)
            .insert(
              PlaySessionExpansionsCompanion.insert(
                playSessionId: id,
                expansionGameKey: expansionGameKey,
              ),
            );
      }
      return id;
    });
  }

  Future<List<PlaySessionRecord>> listForGame(String gameKey) async {
    final sessions =
        await (_database.select(_database.playSessions)
              ..where((session) => session.gameKey.equals(gameKey))
              ..orderBy([
                (session) => OrderingTerm.desc(session.playedDate),
                (session) => OrderingTerm.desc(session.id),
              ]))
            .get();

    return _recordsFromSessions(sessions);
  }

  Future<List<PlaySessionRecord>> listAll() async {
    final sessions =
        await (_database.select(_database.playSessions)..orderBy([
              (session) => OrderingTerm.desc(session.playedDate),
              (session) => OrderingTerm.desc(session.id),
            ]))
            .get();

    return _recordsFromSessions(sessions);
  }

  Future<List<PlaySessionRecord>> _recordsFromSessions(
    List<PlaySession> sessions,
  ) async {
    if (sessions.isEmpty) {
      return const [];
    }
    final allExpansions = await _database
        .select(_database.playSessionExpansions)
        .get();
    final expansionsBySessionId = <int, List<String>>{};
    for (final expansion in allExpansions) {
      expansionsBySessionId
          .putIfAbsent(expansion.playSessionId, () => [])
          .add(expansion.expansionGameKey);
    }
    for (final expansions in expansionsBySessionId.values) {
      expansions.sort();
    }
    return [
      for (final session in sessions)
        PlaySessionRecord(
          id: session.id,
          gameKey: session.gameKey,
          playedDate: session.playedDate,
          playerCount: session.playerCount,
          actualPlayingTime: session.actualPlayingTime,
          notes: session.notes,
          rating: session.rating,
          replayDesire: session.replayDesire,
          perceivedWeight: session.perceivedWeight,
          winnerMemo: session.winnerMemo,
          createdAt: session.createdAt,
          expansionGameKeys:
              expansionsBySessionId[session.id] ?? const <String>[],
        ),
    ];
  }

  Future<void> deleteSession(int id) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.playSessionExpansions,
      )..where((expansion) => expansion.playSessionId.equals(id))).go();
      await (_database.delete(
        _database.playSessions,
      )..where((session) => session.id.equals(id))).go();
    });
  }

  Future<int> countForGame(String gameKey) async {
    final sessions = await (_database.select(
      _database.playSessions,
    )..where((session) => session.gameKey.equals(gameKey))).get();
    return sessions.length;
  }

  void _validateIntRange({
    required int? value,
    required int min,
    required int max,
    required String field,
  }) {
    if (value == null) {
      return;
    }
    if (value < min || value > max) {
      throw PlaySessionValidationException('$field is out of range');
    }
  }

  void _validateDoubleRange({
    required double? value,
    required double min,
    required double max,
    required String field,
  }) {
    if (value == null) {
      return;
    }
    if (value < min || value > max) {
      throw PlaySessionValidationException('$field is out of range');
    }
  }

  List<String> _dedupe(List<String> values) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (value.trim().isNotEmpty && seen.add(value.trim())) value.trim(),
    ];
  }
}

class PlaySessionInput {
  const PlaySessionInput({
    required this.gameKey,
    required this.playedDate,
    this.playerCount,
    this.actualPlayingTime,
    this.notes,
    this.rating,
    this.replayDesire,
    this.perceivedWeight,
    this.winnerMemo,
    this.expansionGameKeys = const [],
  });

  final String gameKey;
  final String playedDate;
  final int? playerCount;
  final int? actualPlayingTime;
  final String? notes;
  final int? rating;
  final int? replayDesire;
  final double? perceivedWeight;
  final String? winnerMemo;
  final List<String> expansionGameKeys;
}

class PlaySessionRecord {
  const PlaySessionRecord({
    required this.id,
    required this.gameKey,
    required this.playedDate,
    required this.createdAt,
    this.playerCount,
    this.actualPlayingTime,
    this.notes,
    this.rating,
    this.replayDesire,
    this.perceivedWeight,
    this.winnerMemo,
    this.expansionGameKeys = const [],
  });

  final int id;
  final String gameKey;
  final String playedDate;
  final int? playerCount;
  final int? actualPlayingTime;
  final String? notes;
  final int? rating;
  final int? replayDesire;
  final double? perceivedWeight;
  final String? winnerMemo;
  final DateTime createdAt;
  final List<String> expansionGameKeys;
}

class PlaySessionValidationException implements Exception {
  const PlaySessionValidationException(this.message);

  final String message;

  @override
  String toString() => 'PlaySessionValidationException: $message';
}
