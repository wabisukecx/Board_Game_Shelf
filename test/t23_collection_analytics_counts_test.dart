import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/collection_repository.dart';
import 'package:bg_shelf_scanner/src/data/repo/play_session_repository.dart';
import 'package:bg_shelf_scanner/src/domain/collection_analytics.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  test('summarizes analysis population with base games only', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CollectionRepository(
      database: database,
      playSessions: PlaySessionRepository(database: database),
    );

    await _insert(database, key: '13', title: 'CATAN');
    await _insert(
      database,
      key: '111',
      title: 'Seafarers',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '13',
    );

    final summary = const CollectionAnalytics().summarize(
      await repository.list(),
    );

    expect(summary.totalCount, 1);
    expect(summary.baseCount, 1);
    expect(summary.expansionCount, 0);
  });
}

Future<void> _insert(
  AppDatabase database, {
  required String key,
  required String title,
  String gameKind = AppConstants.gameKindBase,
  String? parentGameKey,
}) async {
  await database.upsertBggGame(
    bggId: key,
    names: GameNames(primary: title, english: title),
    gameKind: gameKind,
    parentGameKey: parentGameKey,
  );
  await database.upsertCollection(
    CollectionEntriesCompanion.insert(gameKey: key),
  );
}
