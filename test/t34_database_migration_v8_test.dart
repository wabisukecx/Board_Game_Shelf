import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:bg_shelf_scanner/src/data/db/app_database.dart';

void main() {
  test('migrates schema 7 database by adding GameUPC cache table', () async {
    final dir = await Directory.systemTemp.createTemp('bg_shelf_phase8_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');
    _createSchema7Database(file);

    final database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);

    final tableNames = await database
        .customSelect("select name from sqlite_master where type = 'table'")
        .get();
    expect(
      tableNames.map((row) => row.read<String>('name')),
      contains('gameupc_cache'),
    );
  });
}

void _createSchema7Database(File file) {
  final db = sqlite3.sqlite3.open(file.path);
  try {
    db
      ..execute('''
CREATE TABLE settings (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NULL
);
''')
      ..execute('PRAGMA user_version = 7;');
  } finally {
    db.dispose();
  }
}
