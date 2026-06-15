import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/app/app.dart';
import 'package:bg_shelf_scanner/src/app/providers.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
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
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          i18nProvider.overrideWithValue(I18n.fromJsonString(_i18nSource)),
        ],
        child: const BgShelfScannerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('コレクション'), findsOneWidget);
    expect(find.text('まだ登録がありません。'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
