import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/app/providers.dart';
import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/play_session_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/i18n/i18n.dart';
import 'package:bg_shelf_scanner/src/ui/pages/game_detail_page.dart';
import 'package:bg_shelf_scanner/src/ui/pages/play_session_form_page.dart';

void main() {
  late AppDatabase database;
  late I18n i18n;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    i18n = I18n.fromJsonString(File('assets/i18n/en.json').readAsStringSync());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('base game detail shows play sessions and add action', (
    tester,
  ) async {
    await _insertGame(database, key: '13', title: 'CATAN');

    await tester.pumpWidget(
      _wrap(
        database: database,
        i18n: i18n,
        child: const GameDetailPage(gameKey: '13'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Play sessions'), findsOneWidget);
    expect(find.text('No play sessions yet'), findsOneWidget);
    expect(find.text('Add play session'), findsOneWidget);
  });

  testWidgets('expansion detail only shows the play session notice', (
    tester,
  ) async {
    await _insertGame(database, key: '13', title: 'CATAN');
    await _insertGame(
      database,
      key: '1301',
      title: 'Seafarers',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '13',
    );

    await tester.pumpWidget(
      _wrap(
        database: database,
        i18n: i18n,
        child: const GameDetailPage(gameKey: '1301'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Play sessions'), findsOneWidget);
    expect(
      find.text('Record play sessions from the base game.'),
      findsOneWidget,
    );
    expect(find.text('Add play session'), findsNothing);
  });

  testWidgets('form saves a session with selected expansions', (tester) async {
    await _insertGame(database, key: '13', title: 'CATAN');
    await _insertGame(
      database,
      key: '1301',
      title: 'Seafarers',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '13',
    );

    await tester.pumpWidget(
      _wrap(
        database: database,
        i18n: i18n,
        child: const PlaySessionFormPage(gameKey: '13'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seafarers'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextField).at(0), '4');
    await tester.enterText(find.byType(TextField).at(1), '75');
    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final records = await PlaySessionRepository(
      database: database,
    ).listForGame('13');
    expect(records, hasLength(1));
    expect(records.single.playerCount, 4);
    expect(records.single.actualPlayingTime, 75);
    expect(records.single.expansionGameKeys, ['1301']);
  });
}

Widget _wrap({
  required AppDatabase database,
  required I18n i18n,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      i18nProvider.overrideWithValue(i18n),
    ],
    child: MaterialApp(home: child),
  );
}

Future<void> _insertGame(
  AppDatabase database, {
  required String key,
  required String title,
  String gameKind = AppConstants.gameKindBase,
  String? parentGameKey,
}) {
  return database.upsertBggGame(
    bggId: key,
    names: GameNames(primary: title),
    gameKind: gameKind,
    parentGameKey: parentGameKey,
  );
}
