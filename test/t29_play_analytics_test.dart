import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/collection_repository.dart';
import 'package:bg_shelf_scanner/src/data/repo/play_session_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/domain/play_analytics.dart';

void main() {
  late AppDatabase database;
  late PlaySessionRepository sessions;
  late CollectionRepository collection;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    sessions = PlaySessionRepository(database: database);
    collection = CollectionRepository(
      database: database,
      playSessions: sessions,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'summarizes play records by mechanics designers expansions and ratings',
    () async {
      await _insertBgg(
        database,
        bggId: '1',
        primary: 'Ark Nova',
        playingTime: 150,
        mechanics: const ['Drafting', 'Card Play'],
        designers: const ['Mathias Wigge'],
      );
      await _insertBgg(
        database,
        bggId: '2',
        primary: 'Cascadia',
        playingTime: 45,
        mechanics: const ['Drafting', 'Tile Placement'],
        designers: const ['Randy Flynn'],
      );
      await _insertBgg(
        database,
        bggId: '11',
        primary: 'Ark Nova: Marine Worlds',
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '1',
      );

      await sessions.recordSession(
        const PlaySessionInput(
          gameKey: '1',
          playedDate: '2026-06-01',
          playerCount: 2,
          actualPlayingTime: 180,
          rating: 9,
          expansionGameKeys: ['11'],
        ),
      );
      await sessions.recordSession(
        const PlaySessionInput(
          gameKey: '1',
          playedDate: '2026-06-10',
          playerCount: 3,
          actualPlayingTime: 140,
          rating: 7,
        ),
      );
      await sessions.recordSession(
        const PlaySessionInput(
          gameKey: '2',
          playedDate: '2026-06-05',
          playerCount: 2,
          actualPlayingTime: 40,
          rating: 6,
        ),
      );

      final summary = const PlayAnalytics().summarize(
        await collection.list(),
        await sessions.listAll(),
      );

      expect(summary.totalSessions, 3);
      expect(summary.actualPlayingTime.average, closeTo(120, 0.001));
      expect(summary.actualVsNominalPlayingTime.average, closeTo(5, 0.001));
      expect(
        summary.actualPlayingTimeDistribution.entries.map(
          (entry) => entry.count,
        ),
        [0, 1, 0, 0, 2],
      );
      expect(summary.mechanicsPlayCounts.first.label, 'Drafting');
      expect(summary.mechanicsPlayCounts.first.count, 3);
      expect(summary.designerPlayCounts.map((entry) => entry.label), [
        'Mathias Wigge',
        'Randy Flynn',
      ]);
      expect(summary.mechanicRatings.first.label, 'Card Play');
      expect(summary.mechanicRatings.first.average, closeTo(8, 0.001));
      expect(summary.expansionUsage.single.label, 'Ark Nova: Marine Worlds');
      expect(summary.expansionUsage.single.count, 1);
      expect(summary.ratingByPlayerCount.map((entry) => entry.label), [
        '2',
        '3',
      ]);
      expect(summary.ratingByPlayerCount.first.average, closeTo(7.5, 0.001));
      expect(summary.forgottenFavorites.single.gameKey, '1');
      expect(summary.forgottenFavorites.single.lastPlayedDate, '2026-06-10');
    },
  );

  test('keeps empty and missing data summaries stable', () async {
    await _insertBgg(database, bggId: '1', primary: 'No Metadata');
    await sessions.recordSession(
      const PlaySessionInput(gameKey: '1', playedDate: '2026-06-01'),
    );

    final summary = const PlayAnalytics().summarize(
      await collection.list(),
      await sessions.listAll(),
    );

    expect(summary.totalSessions, 1);
    expect(summary.actualPlayingTime.average, isNull);
    expect(summary.actualPlayingTime.excludedCount, 1);
    expect(summary.actualVsNominalPlayingTime.excludedCount, 0);
    expect(summary.mechanicsPlayCounts, isEmpty);
    expect(summary.ratingByPlayerCount, isEmpty);
    expect(summary.forgottenFavorites, isEmpty);
  });

  test('excludes expansion games from play analysis population', () async {
    await _insertBgg(
      database,
      bggId: '1',
      primary: 'Base',
      mechanics: const ['A'],
    );
    await _insertBgg(
      database,
      bggId: '11',
      primary: 'Expansion',
      mechanics: const ['B'],
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '1',
    );

    final items = await collection.list();
    final summary = const PlayAnalytics().summarize(items, [
      PlaySessionRecord(
        id: 1,
        gameKey: '1',
        playedDate: '2026-06-01',
        createdAt: DateTime.utc(2026, 6, 1),
        rating: 8,
      ),
      PlaySessionRecord(
        id: 2,
        gameKey: '11',
        playedDate: '2026-06-02',
        createdAt: DateTime.utc(2026, 6, 2),
        rating: 10,
      ),
    ]);

    expect(summary.totalSessions, 1);
    expect(summary.mechanicsPlayCounts.map((entry) => entry.label), ['A']);
  });
}

Future<void> _insertBgg(
  AppDatabase database, {
  required String bggId,
  required String primary,
  int? playingTime,
  List<String> designers = const [],
  List<String> mechanics = const [],
  String gameKind = AppConstants.gameKindBase,
  String? parentGameKey,
}) async {
  await database.upsertBggGame(
    bggId: bggId,
    names: GameNames(primary: primary, english: primary),
    playingTime: playingTime,
    mechanics: mechanics,
    designers: designers,
    gameKind: gameKind,
    parentGameKey: parentGameKey,
  );
  await database.upsertCollection(
    CollectionEntriesCompanion.insert(gameKey: bggId),
  );
}
