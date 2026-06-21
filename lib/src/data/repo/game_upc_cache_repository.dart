import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/barcode.dart';
import '../../core/clock.dart';
import '../../core/constants.dart';
import '../db/app_database.dart';
import '../gameupc/game_upc_csv_transport.dart';

class GameUpcCacheRepository {
  GameUpcCacheRepository({
    required AppDatabase database,
    required GameUpcCsvTransport transport,
    Clock clock = const SystemClock(),
    AssetBundle? bundle,
  }) : _database = database,
       _transport = transport,
       _clock = clock,
       _bundle = bundle ?? rootBundle;

  final AppDatabase _database;
  final GameUpcCsvTransport _transport;
  final Clock _clock;
  final AssetBundle _bundle;

  Future<GameUpcCacheLookupResult?> lookup(String normalizedJan) async {
    await importBundledSeedIfEmpty();
    final entry = await _database.findGameUpcCache(normalizedJan);
    if (entry == null) {
      return null;
    }
    return GameUpcCacheLookupResult(
      barcode: entry.barcode,
      bggId: entry.bggId,
      versionId: entry.versionId,
      name: entry.name,
    );
  }

  Future<GameUpcCacheImportSummary> importCsv(
    String csvContent, {
    required String source,
  }) async {
    if (source != AppConstants.gameUpcCacheSourceBundled &&
        source != AppConstants.gameUpcCacheSourceRemote) {
      throw ArgumentError.value(source, 'source', 'Unsupported cache source');
    }

    final parsed = await compute(_parseGameUpcCsv, csvContent);
    if (parsed.entries.isEmpty) {
      throw const GameUpcCacheException('CSV contains no valid entries');
    }

    final importedAt = _clock.now();
    final companions = [
      for (final entry in parsed.entries)
        GameUpcCacheEntriesCompanion.insert(
          barcode: entry.barcode,
          bggId: entry.bggId,
          versionId: Value(entry.versionId),
          name: entry.name,
        ),
    ];

    await _database.transaction(() async {
      await _database.delete(_database.gameUpcCacheEntries).go();
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _database.gameUpcCacheEntries,
          companions,
        );
        batch.insertAllOnConflictUpdate(_database.settingsEntries, [
          SettingsEntriesCompanion.insert(
            key: AppConstants.gameUpcCacheImportedAtKey,
            value: Value(importedAt.toIso8601String()),
          ),
          SettingsEntriesCompanion.insert(
            key: AppConstants.gameUpcCacheSourceKey,
            value: Value(source),
          ),
        ]);
      });
    });

    return GameUpcCacheImportSummary(
      importedCount: companions.length,
      skippedCount: parsed.skippedCount,
      source: source,
      importedAt: importedAt,
    );
  }

  Future<GameUpcCacheImportSummary> importBundledSeedIfEmpty() async {
    final count = await _database.countGameUpcCacheEntries();
    if (count > 0) {
      return GameUpcCacheImportSummary(
        importedCount: 0,
        skippedCount: 0,
        source:
            await _database.readSetting(AppConstants.gameUpcCacheSourceKey) ??
            AppConstants.gameUpcCacheSourceBundled,
        importedAt:
            DateTime.tryParse(
              await _database.readSetting(
                    AppConstants.gameUpcCacheImportedAtKey,
                  ) ??
                  '',
            ) ??
            _clock.now(),
      );
    }
    final csv = await _bundle.loadString(AppConstants.gameUpcSeedAsset);
    return importCsv(csv, source: AppConstants.gameUpcCacheSourceBundled);
  }

  Future<GameUpcCacheImportSummary> refreshFromRemote() async {
    final csv = await _transport.fetchCsv();
    return importCsv(csv, source: AppConstants.gameUpcCacheSourceRemote);
  }

  Future<GameUpcCacheStatus> status() async {
    await importBundledSeedIfEmpty();
    final importedAt = DateTime.tryParse(
      await _database.readSetting(AppConstants.gameUpcCacheImportedAtKey) ?? '',
    );
    return GameUpcCacheStatus(
      count: await _database.countGameUpcCacheEntries(),
      importedAt: importedAt,
      source: await _database.readSetting(AppConstants.gameUpcCacheSourceKey),
    );
  }
}

class GameUpcCacheLookupResult {
  const GameUpcCacheLookupResult({
    required this.barcode,
    required this.bggId,
    required this.versionId,
    required this.name,
  });

  final String barcode;
  final String bggId;
  final String? versionId;
  final String name;
}

class GameUpcCacheImportSummary {
  const GameUpcCacheImportSummary({
    required this.importedCount,
    required this.skippedCount,
    required this.source,
    required this.importedAt,
  });

  final int importedCount;
  final int skippedCount;
  final String source;
  final DateTime importedAt;
}

class GameUpcCacheStatus {
  const GameUpcCacheStatus({
    required this.count,
    required this.importedAt,
    required this.source,
  });

  final int count;
  final DateTime? importedAt;
  final String? source;
}

class GameUpcCacheException implements Exception {
  const GameUpcCacheException(this.message);

  final String message;

  @override
  String toString() => 'GameUpcCacheException: $message';
}

class _ParsedGameUpcCsv {
  const _ParsedGameUpcCsv({required this.entries, required this.skippedCount});

  final List<_ParsedGameUpcEntry> entries;
  final int skippedCount;
}

class _ParsedGameUpcEntry {
  const _ParsedGameUpcEntry({
    required this.barcode,
    required this.bggId,
    required this.versionId,
    required this.name,
  });

  final String barcode;
  final String bggId;
  final String? versionId;
  final String name;
}

_ParsedGameUpcCsv _parseGameUpcCsv(String source) {
  final rows = Csv(dynamicTyping: false).decode(source);
  if (rows.isEmpty) {
    return const _ParsedGameUpcCsv(entries: [], skippedCount: 0);
  }

  final header = rows.first
      .map((value) => value.toString().trim().toLowerCase())
      .toList();
  const expectedHeader = ['barcode', 'bgg_id', 'version_id', 'name'];
  if (!listEquals(header, expectedHeader)) {
    debugPrint(
      'Unexpected GameUPC CSV header: ${header.join(',')}; continuing.',
    );
  }

  const normalizer = BarcodeNormalizer();
  final entriesByBarcode = <String, _ParsedGameUpcEntry>{};
  var skippedCount = 0;
  for (final row in rows.skip(1)) {
    if (row.length < 4) {
      skippedCount += 1;
      continue;
    }
    final normalized = normalizer.normalize(row[0].toString());
    final barcode = normalized.ean13;
    final bggId = row[1].toString().trim();
    final parsedBggId = int.tryParse(bggId);
    final versionId = row[2].toString().trim();
    final name = row[3].toString().trim();
    if (barcode == null ||
        barcode == '0000000000000' ||
        parsedBggId == null ||
        parsedBggId <= 0 ||
        name.isEmpty) {
      skippedCount += 1;
      continue;
    }
    entriesByBarcode[barcode] = _ParsedGameUpcEntry(
      barcode: barcode,
      bggId: bggId,
      versionId: versionId.isEmpty ? null : versionId,
      name: name,
    );
  }
  return _ParsedGameUpcCsv(
    entries: entriesByBarcode.values.toList(growable: false),
    skippedCount: skippedCount,
  );
}
