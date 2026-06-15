import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the five phase 0 tables', () async {
    final tables = await database
        .customSelect("select name from sqlite_master where type = 'table'")
        .get();

    final names = tables.map((row) => row.read<String>('name')).toSet();
    expect(
      names,
      containsAll({
        'games',
        'collection',
        'barcode_map',
        'api_cache',
        'settings',
      }),
    );
  });

  test('updating BGG game data does not modify collection metadata', () async {
    await database.upsertBggGame(
      bggId: '13',
      names: const GameNames(primary: 'CATAN'),
      weight: 2.3,
    );
    await database.upsertCollection(
      CollectionEntriesCompanion.insert(
        gameKey: '13',
        storageLocation: const Value('Shelf A'),
        memo: const Value('Keep this note'),
      ),
    );

    await database.upsertBggGame(
      bggId: '13',
      names: const GameNames(primary: 'CATAN'),
      weight: 2.4,
    );

    final game = await database.findGame('13');
    final collection = await database.findCollection('13');

    expect(game?.weight, 2.4);
    expect(collection?.storageLocation, 'Shelf A');
    expect(collection?.memo, 'Keep this note');
  });

  test(
    'allocates local ids from L00001 without colliding with BGG ids',
    () async {
      await database.upsertBggGame(
        bggId: '1',
        names: const GameNames(primary: 'BGG One'),
      );

      final first = await database.insertLocalGame(title: 'Local One');
      final second = await database.insertLocalGame(title: 'Local Two');

      expect(first, 'L00001');
      expect(second, 'L00002');
      expect(await database.findGame('1'), isA<Game>());
      expect(await database.findGame('L00001'), isA<Game>());
      expect(await database.findGame('L00002'), isA<Game>());
    },
  );

  test('game names keep ordered unique alternates as JSON', () async {
    await database.upsertBggGame(
      bggId: '42',
      names: const GameNames(
        primary: 'Primary',
        japanese: '日本語名',
        english: 'Primary',
        alternates: ['A', 'B', 'A'],
      ),
    );

    final game = await database.findGame('42');

    expect(game?.names.primary, 'Primary');
    expect(game?.names.japanese, '日本語名');
    expect(game?.names.alternates, ['A', 'B']);
  });
}
