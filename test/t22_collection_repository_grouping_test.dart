import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/collection_repository.dart';
import 'package:bg_shelf_scanner/src/data/repo/play_session_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;
  late CollectionRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CollectionRepository(
      database: database,
      playSessions: PlaySessionRepository(database: database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'groups expansions under parent and leaves missing-parent expansion orphaned',
    () async {
      await _insert(database, key: '13', title: 'CATAN');
      await _insert(
        database,
        key: '111',
        title: 'Seafarers',
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '13',
      );
      await _insert(
        database,
        key: '999',
        title: 'Orphan Expansion',
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '404',
      );

      final groups = groupCollectionItems(await repository.list());

      final catan = groups.firstWhere(
        (group) => group.parent.game.gameKey == '13',
      );
      expect(catan.expansions.map((item) => item.game.gameKey), ['111']);
      final orphan = groups.firstWhere(
        (group) => group.parent.game.gameKey == '999',
      );
      expect(orphan.isOrphanExpansion, isTrue);
      expect(orphan.expansions, isEmpty);
    },
  );
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
