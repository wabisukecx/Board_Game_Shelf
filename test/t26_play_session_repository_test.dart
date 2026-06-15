import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/play_session_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;
  late PlaySessionRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = PlaySessionRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'records a base game session with expansions and returns a positive id',
    () async {
      await _insertGame(database, key: '13', title: 'CATAN');
      await _insertGame(
        database,
        key: '111',
        title: 'Seafarers',
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '13',
      );

      final id = await repository.recordSession(
        const PlaySessionInput(
          gameKey: '13',
          playedDate: '2026-06-14',
          playerCount: 4,
          actualPlayingTime: 90,
          notes: 'Good table.',
          rating: 8,
          replayDesire: 5,
          perceivedWeight: 2.5,
          winnerMemo: 'Blue won by 2 points.',
          expansionGameKeys: ['111'],
        ),
      );

      expect(id, isPositive);
      final records = await repository.listForGame('13');
      expect(records, hasLength(1));
      expect(records.single.expansionGameKeys, ['111']);
      expect(records.single.rating, 8);
      expect(records.single.replayDesire, 5);
      expect(records.single.perceivedWeight, 2.5);
      expect(records.single.winnerMemo, 'Blue won by 2 points.');
    },
  );

  test(
    'rejects missing games and expansion game keys as session targets',
    () async {
      await _insertGame(
        database,
        key: '111',
        title: 'Seafarers',
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '13',
      );

      await expectLater(
        repository.recordSession(
          const PlaySessionInput(gameKey: '404', playedDate: '2026-06-14'),
        ),
        throwsA(isA<PlaySessionValidationException>()),
      );
      await expectLater(
        repository.recordSession(
          const PlaySessionInput(gameKey: '111', playedDate: '2026-06-14'),
        ),
        throwsA(isA<PlaySessionValidationException>()),
      );
    },
  );

  test('validates date and optional rating scales', () async {
    await _insertGame(database, key: '13', title: 'CATAN');

    await expectLater(
      repository.recordSession(
        const PlaySessionInput(gameKey: '13', playedDate: 'not-a-date'),
      ),
      throwsA(isA<PlaySessionValidationException>()),
    );
    await expectLater(
      repository.recordSession(
        const PlaySessionInput(
          gameKey: '13',
          playedDate: '2026-06-14',
          rating: 11,
        ),
      ),
      throwsA(isA<PlaySessionValidationException>()),
    );
    await expectLater(
      repository.recordSession(
        const PlaySessionInput(
          gameKey: '13',
          playedDate: '2026-06-14',
          replayDesire: 0,
        ),
      ),
      throwsA(isA<PlaySessionValidationException>()),
    );
    await expectLater(
      repository.recordSession(
        const PlaySessionInput(
          gameKey: '13',
          playedDate: '2026-06-14',
          perceivedWeight: 5.1,
        ),
      ),
      throwsA(isA<PlaySessionValidationException>()),
    );

    await repository.recordSession(
      const PlaySessionInput(
        gameKey: '13',
        playedDate: '2026-06-14',
        rating: 1,
        replayDesire: 5,
        perceivedWeight: 1.0,
      ),
    );
    expect(await repository.countForGame('13'), 1);
  });

  test('rejects unrelated expansions without inserting partial rows', () async {
    await _insertGame(database, key: '13', title: 'CATAN');
    await _insertGame(database, key: '20', title: 'Dominion');
    await _insertGame(
      database,
      key: '201',
      title: 'Dominion: Intrigue',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '20',
    );

    await expectLater(
      repository.recordSession(
        const PlaySessionInput(
          gameKey: '13',
          playedDate: '2026-06-14',
          expansionGameKeys: ['201'],
        ),
      ),
      throwsA(isA<PlaySessionValidationException>()),
    );

    expect(await repository.countForGame('13'), 0);
    expect(await _expansionLinkCount(database), 0);
  });

  test('lists sessions by played date desc then id desc', () async {
    await _insertGame(database, key: '13', title: 'CATAN');
    await _insertGame(
      database,
      key: '111',
      title: 'Seafarers',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '13',
    );
    final first = await repository.recordSession(
      const PlaySessionInput(gameKey: '13', playedDate: '2026-06-13'),
    );
    final second = await repository.recordSession(
      const PlaySessionInput(
        gameKey: '13',
        playedDate: '2026-06-14',
        expansionGameKeys: ['111'],
      ),
    );
    final third = await repository.recordSession(
      const PlaySessionInput(gameKey: '13', playedDate: '2026-06-14'),
    );

    final records = await repository.listForGame('13');

    expect(records.map((record) => record.id), [third, second, first]);
    expect(records[1].expansionGameKeys, ['111']);
  });

  test('listAll returns sessions across games with expansion keys', () async {
    await _insertGame(database, key: '13', title: 'CATAN');
    await _insertGame(database, key: '20', title: 'Dominion');
    await _insertGame(
      database,
      key: '111',
      title: 'Seafarers',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '13',
    );
    final first = await repository.recordSession(
      const PlaySessionInput(gameKey: '20', playedDate: '2026-06-13'),
    );
    final second = await repository.recordSession(
      const PlaySessionInput(
        gameKey: '13',
        playedDate: '2026-06-14',
        expansionGameKeys: ['111'],
      ),
    );
    final third = await repository.recordSession(
      const PlaySessionInput(gameKey: '20', playedDate: '2026-06-14'),
    );

    final records = await repository.listAll();

    expect(records.map((record) => record.id), [third, second, first]);
    expect(records[1].gameKey, '13');
    expect(records[1].expansionGameKeys, ['111']);
  });

  test('deleteSession removes session and expansion links', () async {
    await _insertGame(database, key: '13', title: 'CATAN');
    await _insertGame(
      database,
      key: '111',
      title: 'Seafarers',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '13',
    );
    final id = await repository.recordSession(
      const PlaySessionInput(
        gameKey: '13',
        playedDate: '2026-06-14',
        expansionGameKeys: ['111'],
      ),
    );

    await repository.deleteSession(id);

    expect(await repository.countForGame('13'), 0);
    expect(await _expansionLinkCount(database), 0);
  });
}

Future<void> _insertGame(
  AppDatabase database, {
  required String key,
  required String title,
  String gameKind = AppConstants.gameKindBase,
  String? parentGameKey,
}) async {
  await database.upsertBggGame(
    bggId: key,
    names: GameNames(primary: title, english: title),
    gameKind: gameKind,
    parentGameKey: parentGameKey,
  );
}

Future<int> _expansionLinkCount(AppDatabase database) async {
  final rows = await database.select(database.playSessionExpansions).get();
  return rows.length;
}
