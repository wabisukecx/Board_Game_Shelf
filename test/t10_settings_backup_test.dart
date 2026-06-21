import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bg_shelf_scanner/src/app/providers.dart';
import 'package:bg_shelf_scanner/src/core/clock.dart';
import 'package:bg_shelf_scanner/src/data/backup/backup_service.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/export/yaml_exporter.dart';
import 'package:bg_shelf_scanner/src/data/settings/secret_store.dart';
import 'package:bg_shelf_scanner/src/data/settings/secure_settings_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/i18n/i18n.dart';
import 'package:bg_shelf_scanner/src/ui/pages/settings_page.dart';

void main() {
  late AppDatabase database;
  late MemorySecretStore secretStore;
  late SecureSettingsRepository settings;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    secretStore = MemorySecretStore();
    settings = SecureSettingsRepository(secretStore: secretStore);
  });

  tearDown(() async {
    await database.close();
  });

  test('stores BGG and Gemini secrets outside DB and YAML export', () async {
    const bggToken = 'unit-bgg-token';
    const geminiKey = 'unit-gemini-key';
    await settings.saveBggBearerToken(bggToken);
    await settings.saveGeminiApiKey(geminiKey);
    await database.upsertBggGame(
      bggId: '13',
      names: const GameNames(primary: 'CATAN'),
      description: 'Trade resources.',
    );

    final settingRows = await database.select(database.settingsEntries).get();
    final exported = await YamlExporter(database: database).exportOne('13');

    expect(await settings.readToken(), bggToken);
    expect(await settings.readGeminiApiKey(), geminiKey);
    expect(settingRows.map((row) => row.value), isNot(contains(bggToken)));
    expect(settingRows.map((row) => row.value), isNot(contains(geminiKey)));
    expect(exported.content, isNot(contains(bggToken)));
    expect(exported.content, isNot(contains(geminiKey)));
  });

  test('creates stable GameUPC user id for votes', () async {
    final first = await settings.readOrCreateGameUpcUserId();
    final second = await settings.readOrCreateGameUpcUserId();

    expect(first, second);
    expect(first.length, greaterThanOrEqualTo(8));
  });

  test(
    'stores and clears non-secret BGG username through settings repository',
    () async {
      await settings.saveBggUsername('  player-one  ');

      expect(await settings.readBggUsername(), 'player-one');

      await settings.deleteBggUsername();

      expect(await settings.readBggUsername(), isNull);
    },
  );

  testWidgets('labels the Gemini key as photo and shelf recognition', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final i18n = I18n.fromJsonString('''
      {
        "settings": {
          "title": "設定",
          "geminiVisionOption": "写真・棚画像の認識"
        }
      }
    ''');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          secureSettingsProvider.overrideWithValue(settings),
          i18nProvider.overrideWithValue(i18n),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('写真・棚画像の認識'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('写真・棚画像の認識'), findsOneWidget);
    expect(find.text('settings.translationOption'), findsNothing);
  });

  test('backup names follow C-18', () {
    final service = BackupService(
      clock: FixedClock(DateTime(2026, 6, 13, 14, 5, 6)),
    );

    expect(service.automaticBackupName(), '260613.sqlite');
    expect(service.manualBackupName(), 'backup_20260613_140506.sqlite');
  });

  test('copies database backup with manual name', () async {
    final root = await Directory.systemTemp.createTemp('bg_backup_test_');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    final databaseFile = File('${root.path}/source.sqlite')
      ..writeAsStringSync('db');
    final backupDirectory = Directory('${root.path}/backups');
    final service = BackupService(
      clock: FixedClock(DateTime(2026, 6, 13, 14, 5, 6)),
    );

    final backup = await service.copyDatabaseBackup(
      databaseFile: databaseFile,
      backupDirectory: backupDirectory,
      kind: BackupKind.manual,
    );

    expect(backup.path.endsWith('backup_20260613_140506.sqlite'), isTrue);
    expect(backup.readAsStringSync(), 'db');
  });
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

class FixedClock implements Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
