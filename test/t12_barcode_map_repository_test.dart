import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/barcode.dart';
import 'package:bg_shelf_scanner/src/core/clock.dart';
import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/barcode_map_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;
  late BarcodeMapRepository repository;
  late FixedClock clock;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    clock = FixedClock(DateTime(2026, 6, 13, 10, 30));
    repository = BarcodeMapRepository(database: database, clock: clock);
  });

  tearDown(() async {
    await database.close();
  });

  test('resolve returns miss for unknown JAN and hit after learn', () async {
    await database.upsertBggGame(
      bggId: '13',
      names: const GameNames(primary: 'CATAN'),
    );

    final before = await repository.resolve('4901234567894');
    await repository.learn(
      rawJan: '4901234567894',
      gameKey: '13',
      source: AppConstants.barcodeSourceScan,
    );
    final after = await repository.resolve('4901234567894');

    expect(before.status, BarcodeResolutionStatus.miss);
    expect(before.jan, '4901234567894');
    expect(after.status, BarcodeResolutionStatus.hit);
    expect(after.game!.gameKey, '13');
    expect(after.mapping!.source, AppConstants.barcodeSourceScan);
    expect(after.mapping!.resolvedAt, clock.value);
  });

  test('learn upserts the same JAN to the latest game and source', () async {
    await database.upsertBggGame(
      bggId: '13',
      names: const GameNames(primary: 'CATAN'),
    );
    await database.upsertBggGame(
      bggId: '14',
      names: const GameNames(primary: 'Modern Art'),
    );
    await repository.learn(
      rawJan: '4901234567894',
      gameKey: '13',
      source: AppConstants.barcodeSourceScan,
    );

    clock.value = DateTime(2026, 6, 13, 11);
    await repository.learn(
      rawJan: '4901234567894',
      gameKey: '14',
      source: AppConstants.barcodeSourceManual,
    );
    final resolution = await repository.resolve('4901234567894');

    expect(resolution.status, BarcodeResolutionStatus.hit);
    expect(resolution.game!.gameKey, '14');
    expect(resolution.mapping!.source, AppConstants.barcodeSourceManual);
    expect(resolution.mapping!.resolvedAt, clock.value);
  });

  test('resolve reports invalid JAN without touching DB', () async {
    final result = await repository.resolve('4901234567895');

    expect(result.status, BarcodeResolutionStatus.invalid);
    expect(result.invalidReason, BarcodeInvalidReason.invalidCheckDigit);
  });

  test('learn rejects invalid source and missing game', () async {
    expect(
      () => repository.learn(
        rawJan: '4901234567894',
        gameKey: 'missing',
        source: AppConstants.barcodeSourceScan,
      ),
      throwsA(isA<BarcodeMapException>()),
    );

    await database.upsertBggGame(
      bggId: '13',
      names: const GameNames(primary: 'CATAN'),
    );
    expect(
      () => repository.learn(
        rawJan: '4901234567894',
        gameKey: '13',
        source: 'seed',
      ),
      throwsA(isA<BarcodeMapException>()),
    );
  });
}

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}
