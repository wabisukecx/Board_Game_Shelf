import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/clock.dart';
import 'package:bg_shelf_scanner/src/data/backup/backup_service.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/export/yaml_exporter.dart';
import 'package:bg_shelf_scanner/src/data/settings/secret_store.dart';
import 'package:bg_shelf_scanner/src/data/settings/secure_settings_repository.dart';
import 'package:bg_shelf_scanner/src/data/translation/gemini_translation_service.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;
  late MemorySecretStore secretStore;
  late SecureSettingsRepository settings;
  late FakeTranslationClient client;
  late DescriptionTranslationRepository translations;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    secretStore = MemorySecretStore();
    settings = SecureSettingsRepository(secretStore: secretStore);
    client = FakeTranslationClient();
    translations = DescriptionTranslationRepository(
      database: database,
      settings: settings,
      client: client,
    );
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

  test(
    'skips Gemini call when Japanese ratio is greater than 20 percent',
    () async {
      await settings.saveGeminiApiKey('unit-gemini-key');
      await database.upsertBggGame(
        bggId: '14',
        names: const GameNames(primary: 'Japanese Game'),
        description: 'これは日本語の説明文です。Already localized.',
      );

      final result = await translations.translateIfNeeded('14');

      expect(result.status, DescriptionTranslationStatus.skippedJapaneseText);
      expect(client.callCount, 0);
      expect((await database.findGame('14'))!.descriptionJa, isNull);
    },
  );

  test('missing Gemini key keeps original description without error', () async {
    await database.upsertBggGame(
      bggId: '15',
      names: const GameNames(primary: 'No Key Game'),
      description: 'Explore a cave and collect gems.',
    );

    final result = await translations.translateIfNeeded('15');

    expect(result.status, DescriptionTranslationStatus.missingApiKey);
    expect(result.displayDescription, 'Explore a cave and collect gems.');
    expect(client.callCount, 0);
  });

  test('Gemini failure keeps original description without DB update', () async {
    await settings.saveGeminiApiKey('unit-gemini-key');
    client.shouldThrow = true;
    await database.upsertBggGame(
      bggId: '16',
      names: const GameNames(primary: 'Failure Game'),
      description: 'Build a city with cards.',
    );

    final result = await translations.translateIfNeeded('16');

    expect(result.status, DescriptionTranslationStatus.failed);
    expect(result.displayDescription, 'Build a city with cards.');
    expect((await database.findGame('16'))!.descriptionJa, isNull);
  });

  test('successful translation is saved per game key', () async {
    await settings.saveGeminiApiKey('unit-gemini-key');
    client.translation = 'カードで街を作ります。';
    await database.upsertBggGame(
      bggId: '17',
      names: const GameNames(primary: 'Translated Game'),
      description: 'Build a city with cards.',
    );

    final result = await translations.translateIfNeeded('17');

    expect(result.status, DescriptionTranslationStatus.translated);
    expect(result.descriptionJa, 'カードで街を作ります。');
    expect((await database.findGame('17'))!.descriptionJa, 'カードで街を作ります。');
    expect(client.lastPrompt, DescriptionTranslationRepository.prompt);
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

class FakeTranslationClient implements TranslationClient {
  int callCount = 0;
  String? lastPrompt;
  String translation = 'translated';
  bool shouldThrow = false;

  @override
  Future<String> translate({
    required String apiKey,
    required String prompt,
    required String text,
  }) async {
    callCount += 1;
    lastPrompt = prompt;
    if (shouldThrow) {
      throw const TranslationException('failure');
    }
    return translation;
  }
}

class FixedClock implements Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
