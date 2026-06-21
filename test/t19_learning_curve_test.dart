import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/clock.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/domain/complexity_tables.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/domain/game_rank.dart';
import 'package:bg_shelf_scanner/src/domain/learning_curve.dart';

void main() {
  late AppDatabase database;
  late ComplexityTables tables;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    tables = _tables();
  });

  tearDown(() async {
    await database.close();
  });

  test('analyzes a game into bounded deterministic metrics', () async {
    final game = await _insertAndFind(
      database,
      yearPublished: '2020',
      mechanics: [
        'Action Points',
        'Engine Building',
        'Dice Rolling',
        'Variable Player Powers',
      ],
      categories: ['Strategy', 'Family'],
      ranks: const GameRanks([GameRank(type: 'boardgame', rank: '100')]),
      weight: 3.4,
      minPlayers: 1,
      maxPlayers: 5,
      playingTime: 90,
      minAge: 12,
    );
    final analyzer = LearningCurveAnalyzer(
      tables: tables,
      clock: const _FixedClock(2026),
    );

    final first = analyzer.analyze(game);
    final second = analyzer.analyze(game);

    expect(first.initialBarrier, second.initialBarrier);
    expect(first.strategicDepth, inInclusiveRange(1.0, 5.0));
    expect(first.replayability, inInclusiveRange(1.0, 5.0));
    expect(first.decisionPoints, inInclusiveRange(1.0, 5.0));
    expect(first.interactionComplexity, inInclusiveRange(1.0, 5.0));
    expect(first.rulesComplexity, inInclusiveRange(1.0, 5.0));
    expect(first.soloSuitability, 3.0);
    expect(first.playerScalability, 4.0);
    expect(first.luckDependence, 2.7);
    expect(first.playerTypes, contains('experienced'));
  });

  test('longevity factor uses injected clock instead of wall clock', () async {
    final game = await _insertAndFind(
      database,
      yearPublished: '2000',
      mechanics: ['Variable Player Powers'],
      categories: ['Strategy'],
      ranks: const GameRanks([GameRank(type: 'boardgame', rank: '1000')]),
      playingTime: 60,
    );

    final oldClockReplayability = LearningCurveAnalyzer(
      tables: tables,
      clock: const _FixedClock(2026),
    ).analyze(game).replayability;
    final nearReleaseReplayability = LearningCurveAnalyzer(
      tables: tables,
      clock: const _FixedClock(2001),
    ).analyze(game).replayability;

    expect(oldClockReplayability, greaterThan(nearReleaseReplayability));
  });

  test('missing data falls back to documented defaults', () async {
    final game = await _insertAndFind(database);
    final result = LearningCurveAnalyzer(
      tables: tables,
      clock: const _FixedClock(2026),
    ).analyze(game);

    expect(result.mechanicComplexity, 3.0);
    expect(result.categoryComplexity, 2.5);
    expect(result.rankComplexity, 3.0);
    expect(result.soloSuitability, 1.0);
    expect(result.playerScalability, 3.0);
  });

  test(
    'strategic depth applies weight once without a final playtime multiplier',
    () async {
      final light = await _insertAndFind(
        database,
        id: 'weight-light',
        weight: 2.0,
        playingTime: 60,
      );
      final heavy = await _insertAndFind(
        database,
        id: 'weight-heavy',
        weight: 5.0,
        playingTime: 60,
      );
      final analyzer = LearningCurveAnalyzer(
        tables: tables,
        clock: const _FixedClock(2026),
      );

      final difference =
          analyzer.analyze(heavy).strategicDepth -
          analyzer.analyze(light).strategicDepth;

      expect(difference, closeTo(0.9, 0.15));
    },
  );

  test(
    'six or more mechanics makes very deep games take longer to master',
    () async {
      final fiveMechanics = await _insertAndFind(
        database,
        id: 'five-mechanics',
        mechanics: const ['High 1', 'High 2', 'High 3', 'High 4', 'High 5'],
        categories: const ['Strategy'],
        weight: 5.0,
        minAge: 14,
        maxPlayers: 5,
        playingTime: 120,
      );
      final sixMechanics = await _insertAndFind(
        database,
        id: 'six-mechanics',
        mechanics: const [
          'High 1',
          'High 2',
          'High 3',
          'High 4',
          'High 5',
          'High 6',
        ],
        categories: const ['Strategy'],
        weight: 5.0,
        minAge: 14,
        maxPlayers: 5,
        playingTime: 120,
      );
      final analyzer = LearningCurveAnalyzer(
        tables: tables,
        clock: const _FixedClock(2026),
      );
      final fiveResult = analyzer.analyze(fiveMechanics);
      final sixResult = analyzer.analyze(sixMechanics);

      expect(fiveResult.strategicDepth, greaterThan(4.3));
      expect(sixResult.strategicDepth, greaterThan(4.3));
      expect(fiveResult.masteryTime, 'medium_to_long');
      expect(sixResult.masteryTime, 'long');
    },
  );

  test(
    'mastery time uses the same 3.5 strategic depth threshold as labels',
    () async {
      final game = await _insertAndFind(
        database,
        id: 'threshold',
        weight: 5.0,
        playingTime: 60,
      );
      final result = LearningCurveAnalyzer(
        tables: tables,
        clock: const _FixedClock(2026),
      ).analyze(game);

      expect(result.strategicDepth, inInclusiveRange(3.2, 3.5));
      expect(result.strategicDepthLabel, 'medium');
      expect(result.masteryTime, 'short');
    },
  );

  test(
    'unranked games do not receive a longevity replayability bonus',
    () async {
      final oldUnranked = await _insertAndFind(
        database,
        id: 'old-unranked',
        yearPublished: '2000',
        mechanics: const ['Variable Player Powers'],
        categories: const ['Strategy'],
        playingTime: 60,
      );
      final recentUnranked = await _insertAndFind(
        database,
        id: 'recent-unranked',
        yearPublished: '2025',
        mechanics: const ['Variable Player Powers'],
        categories: const ['Strategy'],
        playingTime: 60,
      );
      final analyzer = LearningCurveAnalyzer(
        tables: tables,
        clock: const _FixedClock(2026),
      );

      expect(
        analyzer.analyze(oldUnranked).replayability,
        analyzer.analyze(recentUnranked).replayability,
      );
    },
  );
}

Future<Game> _insertAndFind(
  AppDatabase database, {
  String id = '1',
  String yearPublished = '2020',
  List<String> mechanics = const [],
  List<String> categories = const [],
  GameRanks ranks = const GameRanks([]),
  double? weight,
  int? minPlayers,
  int? maxPlayers,
  int? playingTime,
  int? minAge,
}) async {
  await database.upsertBggGame(
    bggId: id,
    names: const GameNames(primary: 'Test Game', english: 'Test Game'),
    yearPublished: yearPublished,
    publisherMinPlayers: minPlayers,
    publisherMaxPlayers: maxPlayers,
    playingTime: playingTime,
    publisherMinAge: minAge,
    mechanics: mechanics,
    categories: categories,
    weight: weight,
    ranks: ranks,
  );
  return (await database.findGame(id))!;
}

ComplexityTables _tables() {
  return ComplexityTables.fromYamlStrings(
    mechanicsYaml: '''
Action Points:
  complexity: 3.1
  strategic_value: 4.0
  interaction_value: 2.5
Engine Building:
  complexity: 3.5
  strategic_value: 4.3
  interaction_value: 2.8
Dice Rolling:
  complexity: 1.8
  strategic_value: 2.0
  interaction_value: 3.0
Variable Player Powers:
  complexity: 3.2
  strategic_value: 4.1
  interaction_value: 3.2
High 1:
  complexity: 5.0
  strategic_value: 5.0
  interaction_value: 5.0
High 2:
  complexity: 5.0
  strategic_value: 5.0
  interaction_value: 5.0
High 3:
  complexity: 5.0
  strategic_value: 5.0
  interaction_value: 5.0
High 4:
  complexity: 5.0
  strategic_value: 5.0
  interaction_value: 5.0
High 5:
  complexity: 5.0
  strategic_value: 5.0
  interaction_value: 5.0
High 6:
  complexity: 5.0
  strategic_value: 5.0
  interaction_value: 5.0
''',
    categoriesYaml: '''
Strategy:
  complexity: 4.0
  strategic_value: 4.5
  interaction_value: 3.0
Family:
  complexity: 2.0
  strategic_value: 2.5
  interaction_value: 3.5
''',
    rankTypesYaml: '''
boardgame:
  complexity: 3.0
strategygames:
  complexity: 4.2
familygames:
  complexity: 2.3
''',
  );
}

class _FixedClock implements Clock {
  const _FixedClock(this.year);

  final int year;

  @override
  DateTime now() => DateTime(year, 1, 1);
}
