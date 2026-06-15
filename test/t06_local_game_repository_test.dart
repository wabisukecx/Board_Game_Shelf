import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/local_game_repository.dart';

void main() {
  late AppDatabase database;
  late LocalGameRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalGameRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('registers with title only and exposes local badge state', () async {
    final result = await repository.register(title: '同人ゲーム');

    expect(result.game.gameKey, 'L00001');
    expect(result.game.localId, 'L00001');
    expect(result.game.bggId, isNull);
    expect(result.game.name, '同人ゲーム');
    expect(result.game.japaneseName, '同人ゲーム');
    expect(result.isLocal, isTrue);

    final collection = await database.findCollection('L00001');
    expect(collection?.owned, isTrue);
  });

  test('stores optional players time mechanics and categories', () async {
    final result = await repository.register(
      title: 'カード試作',
      publisherMinPlayers: 2,
      publisherMaxPlayers: 5,
      playingTime: 45,
      mechanics: ['Trick-taking', 'Trick-taking', '  Drafting  ', ''],
      categories: ['Card Game', 'Print & Play'],
    );

    expect(result.game.publisherMinPlayers, 2);
    expect(result.game.publisherMaxPlayers, 5);
    expect(result.game.playingTime, 45);
    expect(result.game.mechanics, ['Trick-taking', 'Drafting']);
    expect(result.game.categories, ['Card Game', 'Print & Play']);
  });

  test('local records are not BGG refresh targets', () async {
    final result = await repository.register(title: 'ローカルのみ');

    expect(await database.isBggRefreshTarget(result.game.gameKey), isFalse);
  });

  test('rejects empty title', () async {
    await expectLater(
      repository.register(title: '   '),
      throwsA(isA<InvalidLocalGameException>()),
    );

    expect(await database.findGame('L00001'), isNull);
  });
}
