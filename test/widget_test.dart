import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/app/app.dart';
import 'package:bg_shelf_scanner/src/app/providers.dart';
import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/i18n/i18n.dart';

const _i18nSource = '''
{
  "collection": {
    "title": "コレクション",
    "add": "登録",
    "searchHint": "タイトルで絞り込み",
    "empty": "まだ登録がありません。",
    "listView": "リスト表示",
    "gridView": "グリッド表示",
    "filterLocalOnly": "ローカルのみ",
    "filterPlayerCount": "人数",
    "filterMaxTime": "時間",
    "playersUnit": "人",
    "minutesUnit": "分"
  },
  "nav": {"settings": "設定", "export": "エクスポート"}
}
''';

void main() {
  testWidgets('collection list renders the empty state with no exceptions', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final i18n = I18n.fromJsonString(_i18nSource);
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          i18nProvider.overrideWithValue(i18n),
          languageBootstrapProvider.overrideWith((ref) async => i18n),
        ],
        child: const BgShelfScannerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('コレクション'), findsOneWidget);
    expect(find.text('まだ登録がありません。'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales, const [Locale('ja'), Locale('en')]);
    expect(app.localizationsDelegates, isNotEmpty);
  });

  testWidgets('collapsed expansion tiles are built only after expanding', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final i18n = I18n.fromJsonString(_i18nSource);
    addTearDown(database.close);
    await database.upsertBggGame(
      bggId: '30001',
      names: const GameNames(primary: 'Base Game', english: 'Base Game'),
    );
    await database.upsertCollection(
      CollectionEntriesCompanion.insert(gameKey: '30001'),
    );
    await database.upsertBggGame(
      bggId: '30002',
      names: const GameNames(
        primary: 'Hidden Expansion',
        english: 'Hidden Expansion',
      ),
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '30001',
    );
    await database.upsertCollection(
      CollectionEntriesCompanion.insert(gameKey: '30002'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          i18nProvider.overrideWithValue(i18n),
          languageBootstrapProvider.overrideWith((ref) async => i18n),
        ],
        child: const BgShelfScannerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Base Game'), findsOneWidget);
    expect(find.text('Hidden Expansion'), findsNothing);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.text('Hidden Expansion'), findsOneWidget);
  });
}
