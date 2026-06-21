import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/clock.dart';
import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/gameupc/game_upc_csv_transport.dart';
import 'package:bg_shelf_scanner/src/data/repo/game_upc_cache_repository.dart';

void main() {
  late AppDatabase database;
  late GameUpcCacheRepository repository;
  late FixedClock clock;
  late MemoryAssetBundle bundle;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    clock = FixedClock(DateTime(2026, 6, 21, 12, 30));
    bundle = MemoryAssetBundle(_sampleCsv);
    repository = GameUpcCacheRepository(
      database: database,
      transport: FakeGameUpcCsvTransport(_sampleCsv),
      clock: clock,
      bundle: bundle,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('normalizes UPC-A and keeps leading zero EAN-13 values', () async {
    final summary = await repository.importCsv(
      _sampleCsv,
      source: AppConstants.gameUpcCacheSourceRemote,
    );

    expect(summary.importedCount, 3);
    expect(await repository.lookup('0091039056052'), isNotNull);
    expect(await repository.lookup('0853533008506'), isNotNull);
  });

  test(
    'keeps comma-containing names and lets the last duplicate win',
    () async {
      await repository.importCsv(
        _sampleCsv,
        source: AppConstants.gameUpcCacheSourceRemote,
      );

      final result = await repository.lookup('5011921968923');
      expect(result?.bggId, '194991');
      expect(
        result?.name,
        'Warhammer 40,000 (Third Edition): Codex – Eldar revised',
      );
    },
  );

  test('skips all-zero, invalid-check-digit, and missing BGG rows', () async {
    final summary = await repository.importCsv(
      _sampleCsv,
      source: AppConstants.gameUpcCacheSourceRemote,
    );

    expect(summary.skippedCount, 3);
    expect(await repository.lookup('0000000000000'), isNull);
    expect(await repository.lookup('4901234567895'), isNull);
  });

  test('bundled import is idempotent and status reports metadata', () async {
    final first = await repository.importBundledSeedIfEmpty();
    final second = await repository.importBundledSeedIfEmpty();
    final status = await repository.status();

    expect(first.importedCount, 3);
    expect(second.importedCount, 0);
    expect(bundle.loadCount, 1);
    expect(status.count, 3);
    expect(status.source, AppConstants.gameUpcCacheSourceBundled);
    expect(status.importedAt, clock.value);
  });

  test('failed remote refresh preserves existing cache', () async {
    await repository.importBundledSeedIfEmpty();
    final failing = GameUpcCacheRepository(
      database: database,
      transport: const FakeGameUpcCsvTransport('barcode,bgg_id,name\n'),
      clock: clock,
      bundle: bundle,
    );

    await expectLater(failing.refreshFromRemote(), throwsA(isA<Exception>()));

    final status = await repository.status();
    expect(status.count, 3);
    expect(status.source, AppConstants.gameUpcCacheSourceBundled);
  });
}

const _sampleCsv = '''
barcode,bgg_id,version_id,name
"0091039056052",19095,30887,"Star Fleet Battles: Module K – Fast Patrol Ships"
"853533008506",31260,,"Agricola"
"5011921968923",194990,,"Warhammer 40,000 (Third Edition): Codex – Eldar"
"000000000000",111341,132676,"The Great Zimbabwe"
"4901234567895",13,,"Invalid checksum"
"0655132003049",,,"Missing BGG"
"5011921968923",194991,,"Warhammer 40,000 (Third Edition): Codex – Eldar revised"
''';

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class FakeGameUpcCsvTransport implements GameUpcCsvTransport {
  const FakeGameUpcCsvTransport(this.csv);

  final String csv;

  @override
  Future<String> fetchCsv() async => csv;
}

class MemoryAssetBundle extends CachingAssetBundle {
  MemoryAssetBundle(this.csv);

  final String csv;
  int loadCount = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCount += 1;
    final bytes = Uint8List.fromList(utf8.encode(csv));
    return ByteData.sublistView(bytes);
  }
}
