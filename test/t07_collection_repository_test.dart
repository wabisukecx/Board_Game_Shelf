import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/collection_repository.dart';
import 'package:bg_shelf_scanner/src/data/repo/play_session_repository.dart';
import 'package:bg_shelf_scanner/src/domain/community_players.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/domain/play_audience.dart';

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

  test(
    'excludes four-vote player counts from best players badge but keeps saved data',
    () async {
      await _insertBgg(
        database,
        bggId: '1',
        primary: 'Votes Game',
        communityBestPlayers: '2',
        votes: const SuggestedPlayerVotes([
          SuggestedPlayerVote(
            label: '2',
            best: 3,
            recommended: 1,
            notRecommended: 0,
          ),
        ]),
      );

      final items = await repository.list();

      expect(items.single.bestPlayersBadge, isNull);
      expect(items.single.game.communityBestPlayers, '2');
    },
  );

  test('formats adopted best player range', () async {
    await _insertBgg(
      database,
      bggId: '2',
      primary: 'Good Votes',
      votes: const SuggestedPlayerVotes([
        SuggestedPlayerVote(
          label: '2',
          best: 6,
          recommended: 2,
          notRecommended: 0,
        ),
        SuggestedPlayerVote(
          label: '4+',
          best: 4,
          recommended: 4,
          notRecommended: 0,
        ),
      ]),
    );

    final items = await repository.list();

    expect(items.single.bestPlayersBadge, '2–4+人');
  });

  test(
    'falls back to English name without subtitle when japanese name is missing',
    () async {
      await _insertBgg(database, bggId: '3', primary: 'Azul');

      final items = await repository.list();

      expect(items.single.displayName, 'Azul');
      expect(items.single.subtitle, isNull);
    },
  );

  test(
    'uses Japanese display name and English subtitle when available',
    () async {
      await _insertBgg(database, bggId: '4', primary: 'CATAN', japanese: 'カタン');

      final items = await repository.list();

      expect(items.single.displayName, 'カタン');
      expect(items.single.subtitle, 'CATAN');
    },
  );

  test(
    'uses English display name and Japanese subtitle for English locale',
    () async {
      await _insertBgg(
        database,
        bggId: '401',
        primary: 'CATAN',
        japanese: 'カタン',
      );

      final items = await repository.list(displayLocaleCode: 'en');

      expect(items.single.displayName, 'CATAN');
      expect(items.single.subtitle, 'カタン');
    },
  );

  test('searches all language names regardless of display locale', () async {
    await _insertBgg(
      database,
      bggId: '402',
      primary: 'Scout',
      japanese: 'スカウト',
    );

    final japaneseQuery = await repository.list(
      filter: const CollectionFilter(titleQuery: 'スカウト'),
      displayLocaleCode: 'en',
    );
    final englishQuery = await repository.list(
      filter: const CollectionFilter(titleQuery: 'Scout'),
      displayLocaleCode: 'ja',
    );

    expect(japaneseQuery.single.displayName, 'Scout');
    expect(englishQuery.single.displayName, 'スカウト');
  });

  test('lists searches filters and edits collection fully offline', () async {
    await _insertBgg(
      database,
      bggId: '5',
      primary: 'Ark Nova',
      japanese: 'アーク・ノヴァ',
      minPlayers: 1,
      maxPlayers: 4,
      playingTime: 150,
    );
    await database.insertLocalGame(
      title: 'ローカル短時間',
      publisherMinPlayers: 2,
      publisherMaxPlayers: 3,
      playingTime: 30,
    );
    await database.upsertCollection(
      CollectionEntriesCompanion.insert(gameKey: 'L00001'),
    );

    expect(
      await repository.list(filter: const CollectionFilter(titleQuery: 'ノヴァ')),
      hasLength(1),
    );
    expect(
      await repository.list(filter: const CollectionFilter(playerCount: 4)),
      hasLength(1),
    );
    expect(
      await repository.list(filter: const CollectionFilter(maxPlayingTime: 45)),
      hasLength(1),
    );
    expect(
      await repository.list(filter: const CollectionFilter(localOnly: true)),
      hasLength(1),
    );

    await repository.updateMetadata(
      gameKey: '5',
      storageLocation: '棚A-2',
      memo: 'ソロ用',
      purchasePrice: 6800,
    );
    final updated = await database.findCollection('5');
    expect(updated?.storageLocation, '棚A-2');
    expect(updated?.memo, 'ソロ用');
    expect(updated?.purchasePrice, 6800);
  });

  test('delete requires confirmation when user metadata exists', () async {
    await _insertBgg(database, bggId: '6', primary: 'Memo Game');
    await repository.updateMetadata(
      gameKey: '6',
      memo: 'Do not delete lightly',
    );

    expect(
      await repository.deleteRequirement('6'),
      DeleteRequirement.confirmationRequired,
    );
    await expectLater(
      repository.deleteGame('6'),
      throwsA(isA<DeleteConfirmationRequiredException>()),
    );

    await repository.deleteGame('6', confirmed: true);
    expect(await database.findGame('6'), isNull);
    expect(await database.findCollection('6'), isNull);
  });

  test(
    'sorts by designer then display name and keeps missing designers last',
    () async {
      await _insertBgg(
        database,
        bggId: '7',
        primary: 'Zoo Game',
        designers: const ['Bruno Cathala'],
      );
      await _insertBgg(
        database,
        bggId: '8',
        primary: 'Alpha Game',
        designers: const ['Bruno Cathala'],
      );
      await _insertBgg(
        database,
        bggId: '9',
        primary: 'Middle Game',
        designers: const ['Alexander Pfister'],
      );
      await _insertBgg(database, bggId: '10', primary: 'No Designer Game');

      final items = await repository.list(
        sortOrder: CollectionSortOrder.designer,
      );

      expect(items.map((item) => item.displayName), [
        'Middle Game',
        'Alpha Game',
        'Zoo Game',
        'No Designer Game',
      ]);
    },
  );

  test('delete requires confirmation when play sessions exist', () async {
    await _insertBgg(database, bggId: '11', primary: 'Played Game');
    final sessions = PlaySessionRepository(database: database);
    await sessions.recordSession(
      const PlaySessionInput(gameKey: '11', playedDate: '2026-06-14'),
    );

    expect(
      await repository.deleteRequirement('11'),
      DeleteRequirement.confirmationRequired,
    );
    await expectLater(
      repository.deleteGame('11'),
      throwsA(isA<DeleteConfirmationRequiredException>()),
    );
  });

  test(
    'deleting base game cascades play sessions and expansion links',
    () async {
      await _insertBgg(database, bggId: '12', primary: 'Base Game');
      await _insertBgg(
        database,
        bggId: '121',
        primary: 'Base Game Expansion',
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '12',
      );
      final sessions = PlaySessionRepository(database: database);
      await sessions.recordSession(
        const PlaySessionInput(
          gameKey: '12',
          playedDate: '2026-06-14',
          expansionGameKeys: ['121'],
        ),
      );

      await repository.deleteGame('12', confirmed: true);

      expect(await database.findGame('12'), isNull);
      expect(await sessions.countForGame('12'), 0);
      expect(
        await database.select(database.playSessionExpansions).get(),
        isEmpty,
      );
    },
  );

  test(
    'deleting expansion removes only its play session expansion links',
    () async {
      await _insertBgg(database, bggId: '13', primary: 'Another Base');
      await _insertBgg(
        database,
        bggId: '131',
        primary: 'Another Expansion',
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '13',
      );
      final sessions = PlaySessionRepository(database: database);
      await sessions.recordSession(
        const PlaySessionInput(
          gameKey: '13',
          playedDate: '2026-06-14',
          expansionGameKeys: ['131'],
        ),
      );

      await repository.deleteGame('131');

      expect(await database.findGame('131'), isNull);
      expect(await sessions.countForGame('13'), 1);
      expect(
        (await sessions.listForGame('13')).single.expansionGameKeys,
        isEmpty,
      );
    },
  );

  test('adds play counts last played dates and facets to list items', () async {
    await _insertBgg(
      database,
      bggId: '14',
      primary: 'Played Base',
      mechanics: const ['Worker Placement', 'Drafting'],
      designers: const ['Designer A'],
    );
    await _insertBgg(
      database,
      bggId: '141',
      primary: 'Played Expansion',
      mechanics: const ['Drafting'],
      designers: const ['Designer B'],
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '14',
    );
    final sessions = PlaySessionRepository(database: database);
    await sessions.recordSession(
      const PlaySessionInput(gameKey: '14', playedDate: '2026-06-01'),
    );
    await sessions.recordSession(
      const PlaySessionInput(gameKey: '14', playedDate: '2026-06-10'),
    );

    final items = await repository.list();
    final base = items.singleWhere((item) => item.game.gameKey == '14');
    final expansion = items.singleWhere((item) => item.game.gameKey == '141');
    final facets = await repository.facets();

    expect(base.playCount, 2);
    expect(base.lastPlayedDate, '2026-06-10');
    expect(expansion.playCount, 0);
    expect(expansion.lastPlayedDate, isNull);
    expect(facets.mechanics, ['Drafting', 'Worker Placement']);
    expect(facets.designers, ['Designer A', 'Designer B']);
  });

  test(
    'filters by mechanics designers expansions and unplayed status',
    () async {
      await _insertBgg(
        database,
        bggId: '15',
        primary: 'Trick Game',
        mechanics: const ['Trick-taking'],
        designers: const ['Designer A'],
      );
      await _insertBgg(
        database,
        bggId: '16',
        primary: 'Draft Game',
        mechanics: const ['Drafting'],
        designers: const ['Designer B'],
      );
      await _insertBgg(
        database,
        bggId: '161',
        primary: 'Draft Expansion',
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '16',
      );
      final sessions = PlaySessionRepository(database: database);
      await sessions.recordSession(
        const PlaySessionInput(gameKey: '15', playedDate: '2026-06-01'),
      );

      expect(
        (await repository.list(
          filter: const CollectionFilter(
            mechanics: ['Trick-taking', 'Area Majority'],
          ),
        )).map((item) => item.game.gameKey),
        ['15'],
      );
      expect(
        (await repository.list(
          filter: const CollectionFilter(designers: ['Designer B']),
        )).map((item) => item.game.gameKey),
        ['16'],
      );
      expect(
        (await repository.list(
          filter: const CollectionFilter(hasExpansionsOnly: true),
        )).map((item) => item.game.gameKey),
        ['16'],
      );
      expect(
        (await repository.list(
          filter: const CollectionFilter(unplayedOnly: true),
        )).map((item) => item.game.gameKey),
        ['161', '16'],
      );
    },
  );

  test('sorts by oldest last played date with unplayed first', () async {
    await _insertBgg(database, bggId: '17', primary: 'Never Played');
    await _insertBgg(database, bggId: '18', primary: 'Older Played');
    await _insertBgg(database, bggId: '19', primary: 'Recent Played');
    final sessions = PlaySessionRepository(database: database);
    await sessions.recordSession(
      const PlaySessionInput(gameKey: '19', playedDate: '2026-06-10'),
    );
    await sessions.recordSession(
      const PlaySessionInput(gameKey: '18', playedDate: '2026-06-01'),
    );

    final items = await repository.list(
      sortOrder: CollectionSortOrder.lastPlayed,
    );

    expect(items.map((item) => item.displayName), [
      'Never Played',
      'Older Played',
      'Recent Played',
    ]);
  });

  test('filters by play audience from weight', () async {
    await _insertBgg(database, bggId: '20', primary: 'Light Game', weight: 1.5);
    await _insertBgg(database, bggId: '21', primary: 'Heavy Game', weight: 3.5);
    await _insertBgg(database, bggId: '22', primary: 'Unknown Weight Game');

    expect(
      (await repository.list(
        filter: const CollectionFilter(playAudience: PlayAudience.beginner),
      )).map((item) => item.game.gameKey),
      ['20'],
    );
    expect(
      (await repository.list(
        filter: const CollectionFilter(playAudience: PlayAudience.advanced),
      )).map((item) => item.game.gameKey),
      ['21'],
    );
    expect(
      (await repository.list(
        filter: const CollectionFilter(playAudience: PlayAudience.unknown),
      )).map((item) => item.game.gameKey),
      ['22'],
    );
  });

  test('lists one thousand seed records', () async {
    for (var index = 0; index < 1000; index += 1) {
      final bggId = '${10000 + index}';
      await _insertBgg(database, bggId: bggId, primary: 'Game $index');
    }

    final items = await repository.list();

    expect(items, hasLength(1000));
  });

  test(
    'excludes games without collection entries from list and facets',
    () async {
      await _insertBgg(
        database,
        bggId: '20001',
        primary: 'Collected Game',
        mechanics: const ['Collected Mechanic'],
        designers: const ['Collected Designer'],
      );
      await database.upsertBggGame(
        bggId: '20002',
        names: const GameNames(
          primary: 'Uncollected Game',
          english: 'Uncollected Game',
        ),
        mechanics: const ['Uncollected Mechanic'],
        designers: const ['Uncollected Designer'],
      );

      final items = await repository.list();
      final facets = await repository.facets();

      expect(items.map((item) => item.game.gameKey), ['20001']);
      expect(facets.mechanics, ['Collected Mechanic']);
      expect(facets.designers, ['Collected Designer']);
    },
  );
}

Future<void> _insertBgg(
  AppDatabase database, {
  required String bggId,
  required String primary,
  String? japanese,
  int? minPlayers,
  int? maxPlayers,
  int? playingTime,
  String? communityBestPlayers,
  SuggestedPlayerVotes votes = const SuggestedPlayerVotes([]),
  List<String> designers = const [],
  List<String> mechanics = const [],
  double? weight,
  String gameKind = AppConstants.gameKindBase,
  String? parentGameKey,
}) async {
  await database.upsertBggGame(
    bggId: bggId,
    names: GameNames(primary: primary, japanese: japanese, english: primary),
    publisherMinPlayers: minPlayers,
    publisherMaxPlayers: maxPlayers,
    playingTime: playingTime,
    communityBestPlayers: communityBestPlayers,
    suggestedPlayerVotes: votes,
    mechanics: mechanics,
    designers: designers,
    weight: weight,
    gameKind: gameKind,
    parentGameKey: parentGameKey,
  );
  await database.upsertCollection(
    CollectionEntriesCompanion.insert(gameKey: bggId),
  );
}
