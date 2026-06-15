import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/collection_repository.dart';
import 'package:bg_shelf_scanner/src/data/repo/play_session_repository.dart';
import 'package:bg_shelf_scanner/src/domain/collection_analytics.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;
  late CollectionRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CollectionRepository(
      database: database,
      playSessions: PlaySessionRepository(database: database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('empty input returns zero summary without throwing', () {
    final summary = const CollectionAnalytics().summarize(const []);

    expect(summary.totalCount, 0);
    expect(summary.weight.average, isNull);
    expect(summary.rating.average, isNull);
    expect(summary.purchasePrice.sum, 0);
    expect(summary.mechanicsTop, isEmpty);
  });

  test(
    'excludes null and unparsable values from averages with counts',
    () async {
      await _insertGame(
        database,
        key: '1',
        title: 'Complete',
        weight: 2,
        averageRating: '7.5',
        purchasePrice: 6000,
      );
      await _insertGame(
        database,
        key: '2',
        title: 'Missing',
        averageRating: 'not-a-number',
      );

      final summary = const CollectionAnalytics().summarize(
        await repository.list(),
      );

      expect(summary.weight.average, 2);
      expect(summary.weight.includedCount, 1);
      expect(summary.weight.excludedCount, 1);
      expect(summary.rating.average, 7.5);
      expect(summary.rating.includedCount, 1);
      expect(summary.rating.excludedCount, 1);
      expect(summary.purchasePrice.sum, 6000);
      expect(summary.purchasePrice.average, 6000);
      expect(summary.purchasePrice.includedCount, 1);
      expect(summary.purchasePrice.excludedCount, 1);
    },
  );

  test('excludes expansions from analysis population and averages', () async {
    await _insertGame(
      database,
      key: 'base',
      title: 'Base Game',
      weight: 2,
      playingTime: 60,
      mechanics: const ['Drafting'],
    );
    await _insertGame(
      database,
      key: 'expansion',
      title: 'Base Game Expansion',
      weight: 5,
      playingTime: 240,
      mechanics: const ['Expansion Mechanic'],
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: 'base',
    );

    final items = await repository.list();
    final analysisItems = collectionItemsForAnalysis(items);
    final summary = const CollectionAnalytics().summarize(items);

    expect(analysisItems.map((item) => item.game.gameKey), ['base']);
    expect(summary.totalCount, 1);
    expect(summary.weight.average, 2);
    expect(summary.playingTimeDistribution.includedCount, 1);
    expect(summary.mechanicsTop.map((entry) => entry.label), ['Drafting']);
  });

  test(
    'assigns weight and playing time boundary values to defined buckets',
    () async {
      final weights = [1.49, 1.5, 2.5, 3.5, 4.5];
      final times = [30, 31, 61, 91, 121];
      for (var index = 0; index < weights.length; index += 1) {
        await _insertGame(
          database,
          key: '${index + 1}',
          title: 'Boundary $index',
          weight: weights[index],
          playingTime: times[index],
        );
      }

      final summary = const CollectionAnalytics().summarize(
        await repository.list(),
      );

      expect(_counts(summary.weightDistribution), {
        '<1.5': 1,
        '1.5-2.5': 1,
        '2.5-3.5': 1,
        '3.5-4.5': 1,
        '>=4.5': 1,
      });
      expect(_counts(summary.playingTimeDistribution), {
        '<=30': 1,
        '31-60': 1,
        '61-90': 1,
        '91-120': 1,
        '>120': 1,
      });
    },
  );

  test(
    'counts player coverage for each player count from one to eight',
    () async {
      await _insertGame(
        database,
        key: '1',
        title: 'Solo to Three',
        minPlayers: 1,
        maxPlayers: 3,
      );
      await _insertGame(
        database,
        key: '2',
        title: 'Three to Eight',
        minPlayers: 3,
        maxPlayers: 8,
      );
      await _insertGame(database, key: '3', title: 'Unknown Players');

      final summary = const CollectionAnalytics().summarize(
        await repository.list(),
      );

      expect(summary.playerCoverage.includedCount, 2);
      expect(summary.playerCoverage.excludedCount, 1);
      expect(_counts(summary.playerCoverage), {
        '1': 1,
        '2': 1,
        '3': 2,
        '4': 1,
        '5': 1,
        '6': 1,
        '7': 1,
        '8': 1,
      });
    },
  );

  test(
    'top rankings sort by frequency then label and limit to top ten',
    () async {
      await _insertGame(
        database,
        key: 'base',
        title: 'Base',
        mechanics: ['B', 'A'],
      );
      for (var index = 0; index < 12; index += 1) {
        await _insertGame(
          database,
          key: 'x$index',
          title: 'X $index',
          mechanics: ['M${index.toString().padLeft(2, '0')}'],
        );
      }
      await _insertGame(database, key: 'a2', title: 'A2', mechanics: ['A']);
      await _insertGame(database, key: 'b2', title: 'B2', mechanics: ['B']);

      final summary = const CollectionAnalytics().summarize(
        await repository.list(),
      );

      expect(summary.mechanicsTop, hasLength(AppConstants.analyticsTopN));
      expect(summary.mechanicsTop[0].label, 'A');
      expect(summary.mechanicsTop[0].count, 2);
      expect(summary.mechanicsTop[1].label, 'B');
      expect(summary.mechanicsTop[1].count, 2);
    },
  );

  test(
    'includeNotOwned false uses owned only and true uses all records',
    () async {
      await _insertGame(database, key: '1', title: 'Owned', owned: true);
      await _insertGame(database, key: '2', title: 'Not Owned', owned: false);

      final items = await repository.list();
      final ownedOnly = const CollectionAnalytics().summarize(items);
      final all = const CollectionAnalytics().summarize(
        items,
        includeNotOwned: true,
      );

      expect(ownedOnly.totalCount, 1);
      expect(ownedOnly.ownedCount, 1);
      expect(ownedOnly.notOwnedCount, 0);
      expect(all.totalCount, 2);
      expect(all.ownedCount, 1);
      expect(all.notOwnedCount, 1);
    },
  );

  test('groups decades ratings storage and acquisition months', () async {
    await _insertGame(
      database,
      key: '1',
      title: 'Old',
      yearPublished: '1999',
      averageRating: '6.9',
      storageLocation: 'Shelf A',
      acquiredDate: '2026-01-05',
    );
    await _insertGame(
      database,
      key: '2',
      title: 'New',
      yearPublished: '2024',
      averageRating: '8.1',
      acquiredDate: '2026-01-20',
    );

    final summary = const CollectionAnalytics().summarize(
      await repository.list(),
    );

    expect(_counts(summary.decadeDistribution), {'1990s': 1, '2020s': 1});
    expect(_counts(summary.ratingDistribution), {'6s': 1, '8s': 1});
    expect(
      {for (final entry in summary.storageLocations) entry.label: entry.count},
      {'Shelf A': 1, CountEntry.unspecifiedLabel: 1},
    );
    expect(_counts(summary.acquisitionsByMonth), {'2026-01': 2});
  });
}

Map<String, int> _counts(DistributionSummary distribution) {
  return {for (final entry in distribution.entries) entry.label: entry.count};
}

Future<void> _insertGame(
  AppDatabase database, {
  required String key,
  required String title,
  bool owned = true,
  String? yearPublished,
  int? minPlayers,
  int? maxPlayers,
  int? playingTime,
  String? averageRating,
  double? weight,
  List<String> mechanics = const [],
  List<String> categories = const [],
  List<String> designers = const [],
  List<String> publishers = const [],
  double? purchasePrice,
  String? storageLocation,
  String? acquiredDate,
  String gameKind = AppConstants.gameKindBase,
  String? parentGameKey,
}) async {
  await database.upsertBggGame(
    bggId: key,
    names: GameNames(primary: title, english: title),
    yearPublished: yearPublished,
    publisherMinPlayers: minPlayers,
    publisherMaxPlayers: maxPlayers,
    playingTime: playingTime,
    mechanics: mechanics,
    categories: categories,
    designers: designers,
    publishers: publishers,
    averageRating: averageRating,
    weight: weight,
    gameKind: gameKind,
    parentGameKey: parentGameKey,
  );
  await database.upsertCollection(
    CollectionEntriesCompanion.insert(
      gameKey: key,
      owned: Value(owned),
      purchasePrice: Value(purchasePrice),
      storageLocation: Value(storageLocation),
      acquiredDate: Value(acquiredDate),
    ),
  );
}
