import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/domain/display_names.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('uses Japanese name for Japanese locale and English subtitle', () async {
    final game = await _game(
      database,
      primary: 'CATAN',
      japanese: 'カタン',
      english: 'CATAN',
    );

    expect(resolveDisplayName(game, 'ja', fallback: '名称不明'), 'カタン');
    expect(resolveSubtitle(game, 'ja'), 'CATAN');
  });

  test('falls back to English primary when Japanese name is missing', () async {
    final game = await _game(database, primary: 'Azul');

    expect(resolveDisplayName(game, 'ja-JP', fallback: '名称不明'), 'Azul');
    expect(resolveSubtitle(game, 'ja-JP'), isNull);
  });

  test('uses English name for English locale and Japanese subtitle', () async {
    final game = await _game(
      database,
      primary: 'Scout',
      japanese: 'スカウト',
      english: 'Scout',
    );

    expect(resolveDisplayName(game, 'en', fallback: 'Unknown title'), 'Scout');
    expect(resolveSubtitle(game, 'en'), 'スカウト');
  });

  test(
    'does not show subtitle when English and Japanese names match',
    () async {
      final game = await _game(
        database,
        primary: 'Local Title',
        japanese: 'Local Title',
        english: 'Local Title',
      );

      expect(
        resolveDisplayName(game, 'en-US', fallback: 'Unknown title'),
        'Local Title',
      );
      expect(resolveSubtitle(game, 'en-US'), isNull);
    },
  );

  test('returns fallback when every name is empty', () async {
    final game = await _game(database, primary: '');

    expect(resolveDisplayName(game, 'ja', fallback: '名称不明'), '名称不明');
    expect(
      resolveDisplayName(game, 'en', fallback: 'Unknown title'),
      'Unknown title',
    );
    expect(resolveSubtitle(game, 'ja'), isNull);
  });

  test('uses English priority for unsupported locale', () async {
    final game = await _game(
      database,
      primary: 'Brass: Birmingham',
      japanese: 'ブラス: バーミンガム',
      english: 'Brass: Birmingham',
    );

    expect(
      resolveDisplayName(game, 'fr', fallback: 'Unknown title'),
      'Brass: Birmingham',
    );
    expect(resolveSubtitle(game, 'fr'), 'ブラス: バーミンガム');
  });
}

Future<Game> _game(
  AppDatabase database, {
  required String primary,
  String? japanese,
  String? english,
}) async {
  await database.upsertBggGame(
    bggId: '1',
    names: GameNames(
      primary: primary,
      japanese: japanese,
      english: english ?? primary,
    ),
    japaneseName: japanese,
  );
  return (await database.findGame('1'))!;
}
