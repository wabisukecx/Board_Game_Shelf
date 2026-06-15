import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';

void main() {
  test('migrates schema 5 games to base kind with no parent key', () async {
    final dir = await Directory.systemTemp.createTemp('bg_shelf_phase5_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');
    _createSchema5Database(file);

    final database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);

    final game = await database.findGame('13');

    expect(game, isNotNull);
    expect(game?.gameKind, AppConstants.gameKindBase);
    expect(game?.parentGameKey, isNull);
  });
}

void _createSchema5Database(File file) {
  final db = sqlite3.sqlite3.open(file.path);
  try {
    db
      ..execute('''
CREATE TABLE games (
  game_key TEXT NOT NULL PRIMARY KEY,
  bgg_id TEXT NULL,
  local_id TEXT NULL,
  names TEXT NOT NULL,
  name TEXT NOT NULL,
  japanese_name TEXT NULL,
  year_published TEXT NULL,
  publisher_min_players INTEGER NULL,
  publisher_max_players INTEGER NULL,
  playing_time INTEGER NULL,
  publisher_min_age INTEGER NULL,
  community_best_players TEXT NULL,
  community_recommended_players TEXT NULL,
  community_min_age TEXT NULL,
  suggested_player_votes TEXT NOT NULL DEFAULT '[]',
  description TEXT NULL,
  description_ja TEXT NULL,
  mechanics TEXT NOT NULL DEFAULT '[]',
  categories TEXT NOT NULL DEFAULT '[]',
  designers TEXT NOT NULL DEFAULT '[]',
  publishers TEXT NOT NULL DEFAULT '[]',
  average_rating TEXT NULL,
  weight REAL NULL,
  ranks TEXT NOT NULL DEFAULT '[]',
  update_history TEXT NOT NULL DEFAULT '[]',
  thumbnail_url TEXT NULL,
  raw_yaml TEXT NULL,
  updated_at INTEGER NOT NULL
);
''')
      ..execute('''
CREATE TABLE collection (
  game_key TEXT NOT NULL PRIMARY KEY REFERENCES games(game_key),
  owned INTEGER NOT NULL DEFAULT 1,
  acquired_date TEXT NULL,
  condition TEXT NULL,
  storage_location TEXT NULL,
  memo TEXT NULL,
  purchase_price REAL NULL,
  updated_at INTEGER NOT NULL
);
''')
      ..execute('''
CREATE TABLE barcode_map (
  jan_code TEXT NOT NULL PRIMARY KEY,
  game_key TEXT NOT NULL REFERENCES games(game_key),
  resolved_at INTEGER NOT NULL,
  source TEXT NOT NULL
);
''')
      ..execute('''
CREATE TABLE api_cache (
  cache_key TEXT NOT NULL PRIMARY KEY,
  payload TEXT NOT NULL,
  expires_at INTEGER NOT NULL
);
''')
      ..execute('''
CREATE TABLE settings (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NULL
);
''')
      ..execute('''
INSERT INTO games (
  game_key, bgg_id, names, name, suggested_player_votes, mechanics,
  categories, designers, publishers, ranks, update_history, updated_at
) VALUES (
  '13',
  '13',
  '{"primary":"CATAN"}',
  'CATAN',
  '[]',
  '[]',
  '[]',
  '[]',
  '[]',
  '[]',
  '[]',
  0
);
''')
      ..execute('PRAGMA user_version = 5;');
  } finally {
    db.dispose();
  }
}
