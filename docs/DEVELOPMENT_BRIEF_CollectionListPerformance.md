# Board Game Shelf 改修ブリーフ：コレクション一覧の表示・スクロールパフォーマンス改善（Codex向け）

## 前提・対象
- 対象: `C:\Users\tucon\StudioProjects\bg_shelf_scanner`（Flutter / Riverpod / Drift）
- 不具合（性能）: ゲームを100件以上登録すると、コレクション一覧のスクロールがなめらかでなくなる、という申告。事前調査で原因を4点特定済み（うち2点はDB層のN+1クエリ、2点はUI層の無駄な描画コスト）。
- 各タスクは独立コミット可能な粒度。既存テストを壊さないこと。各タスク完了時に `flutter analyze` と `flutter test` を実行。

## 重要な背景（調査済みの事実 — これに合わせて実装すること）

### 原因1: `_Thumbnail`（`lib/src/ui/pages/collection_list_page.dart`）が画像をソース解像度のままデコードしている
`Image.network(source, width: size, height: size, fit: BoxFit.cover, ...)` に `cacheWidth`/`cacheHeight` を指定していない。BGGの `<thumbnail>` URL（`bgg_xml_parser.dart` の `thumbnailUrl: item.getElement('thumbnail')?.innerText`）はそこそこのサイズがあり、それを一覧では44px・グリッドでは120px相当に縮小表示している。`cacheWidth`/`cacheHeight` 未指定だとソース解像度のままデコード→ImageCacheに保持され、件数が増えるほどデコード回数とメモリ消費が増え、Flutterのデフォルト100MB ImageCacheの入れ替わり（evict→再デコード）がスクロール中のフレーム落ちとして現れる。

**注意（グリッド表示の罠）**: グリッドの `_Thumbnail(url: ..., size: 120)` は `Positioned.fill` の中にあり、`Stack` の実際のセル幅（`SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, ...)` なので最大180px相当）まで引き伸ばされて表示される。`size: 120` という引数は `Positioned.fill` の tight constraints で実質無視されるため、`cacheWidth` を `size`（120）基準で計算すると実際の表示サイズより小さくデコードしてしまい、ぼやける／結局再デコードが起きる可能性がある。デコードサイズは「実際にレイアウトされる物理ピクセルサイズ」基準で計算すること。

### 原因2: `AnimatedCrossFade`（`_CollectionList`内）が、折りたたみ中の拡張タイルも常にビルド・レイアウト・ペイントしている
```dart
AnimatedCrossFade(
  ...
  firstChild: const SizedBox.shrink(),
  secondChild: Column(
    children: [
      for (final expansion in group.expansions)
        _CollectionListTile(item: expansion, ...), // _Thumbnail（Image.network）含む
    ],
  ),
)
```
`AnimatedCrossFade` は仕様上、`crossFadeState` に関わらず両方の子を常にビルド・レイアウト・ペイントする（透明度で隠しているだけでマウントは外れない）。拡張セットを多く持つゲーム（Dominionシリーズ等）が多いコレクションほど、画面に見えていない拡張タイルの `Image.network` まで毎回デコード・ペイントされ、原因1を増幅させている。

なお `_CollectionGrid` 側は `visibleItems` の組み立て時点で `if (expandedGameKeys.contains(...))` の条件分岐により、折りたたみ中の拡張エントリをそもそもリストに含めていない。**グリッド表示はこの問題を持たない。直すのはリスト表示（`_CollectionList`）のみでよい。**

### 原因3: `CollectionRepository.list()` と `facets()` のN+1クエリ（`lib/src/data/repo/collection_repository.dart`）
```dart
final games = await _database.select(_database.games).get();
for (final game in games) {
  final collection = await _database.findCollection(game.gameKey);       // 1件ずつ
  final sessionRecords = ... await _playSessions.listForGame(game.gameKey); // 1件ずつ（listのみ）
  ...
}
```
`list()` は100件のコレクションで最大200回、`facets()`（同じく `findCollection` を1件ずつ呼んでいる）も最大100回、SQLite（バックグラウンドIsolate）への往復が**forループ内で逐次**発生する。両テーブルともインデックス（`collection_game_key_idx` / `play_sessions_game_key_idx`）はあるので1クエリ自体は速いが、Isolate間メッセージのオーバーヘッドが件数分積み上がる。

`collectionListProvider`/`collectionFacetsProvider` は `collectionFilterProvider` 等を `watch` しており、検索ボックスへの1文字入力や、他画面から戻るたびの `ref.invalidate(...)`（`collection_list_page.dart` の `_openAndRefresh`）で再計算される。**件数に比例して悪化するため、「100件を超えたあたりから」という申告と最も整合する原因。**

### 原因4: `PlaySessionRepository._recordsFromSessions()`（`lib/src/data/repo/play_session_repository.dart`）にも同型のN+1がある
```dart
Future<List<PlaySessionRecord>> _recordsFromSessions(List<PlaySession> sessions) async {
  for (final session in sessions) {
    final expansions = await (_database.select(_database.playSessionExpansions)
          ..where((expansion) => expansion.playSessionId.equals(session.id)))
        .get(); // セッション1件ずつ
    ...
  }
}
```
**重要**: 原因3の修正で `CollectionRepository.list()` を「ゲームごとに `listForGame()`」から「全体を1回 `listAll()`」に変えても、`listAll()` 内部のこのループが直っていなければ、N+1の母数が「ゲーム件数」から「プレイ記録件数」に移るだけで問題は解消しない。プレイ記録をまめに付けているユーザーほど影響が残るため、**原因3とセットで直すこと。**

---

## タスク0: 現状確認（実装前）
`test/t07_collection_repository_test.dart`、`test/t26_play_session_repository_test.dart`、`test/widget_test.dart` を読み、現在のテストパターンとアサーション粒度を把握してから着手する。特に t07 の `'lists one thousand seed records'`（件数のみ検証）と t26 の `'listAll returns sessions across games with expansion keys'`（順序とexpansionGameKeysを検証）は、今回のリファクタで**振る舞いを変えずに**通す必要がある。

---

## タスク1: サムネイルのデコードサイズ最適化（`lib/src/ui/pages/collection_list_page.dart`）
1. `_Thumbnail` に、実際の表示物理ピクセルサイズを指定するための引数を追加する:
   ```dart
   class _Thumbnail extends StatelessWidget {
     const _Thumbnail({required this.url, this.size = 44, this.cacheSize});
     final String? url;
     final double size;       // 元のレイアウトヒント（list側はそのまま使われる）
     final double? cacheSize; // 実際に表示される論理ピクセルサイズ。未指定時は size を使う
     ...
   }
   ```
2. `build()` 内で `MediaQuery.devicePixelRatioOf(context)` を使い、`cacheWidth`/`cacheHeight` を計算して `Image.network` に渡す:
   ```dart
   final dpr = MediaQuery.devicePixelRatioOf(context);
   final targetPx = ((cacheSize ?? size) * dpr).round();
   return Image.network(
     source,
     width: size,
     height: size,
     fit: BoxFit.cover,
     cacheWidth: targetPx,
     cacheHeight: targetPx,
     errorBuilder: (_, __, ___) => placeholder,
   );
   ```
3. 呼び出し側を更新する:
   - `_CollectionListTile`（リスト表示の `leading: _Thumbnail(url: ...)`）: 引数なし（`size: 44` のデフォルトのまま、ListTileのleadingはtight 44x44なのでこれで正しい）。
   - `_CollectionGrid` の `_Thumbnail(url: item.game.thumbnailUrl, size: 120)`: `cacheSize: 180` を追加する（`SliverGridDelegateWithMaxCrossAxisExtent` の `maxCrossAxisExtent: 180` と同じ値。値がズレないよう、できれば両方が参照する `static const double _gridMaxCrossAxisExtent = 180;` のような共有定数を `_CollectionGrid` 内に用意し、`gridDelegate` と `cacheSize` の両方で使う）。

---

## タスク2: 折りたたみ中の拡張タイルを実体化しない（`_CollectionList`）
1. `AnimatedCrossFade` を、折りたたみ中は子を一切ビルドしない形に置き換える。アニメーションの滑らかさは `AnimatedSize` で高さ遷移を維持しつつ確保する:
   ```dart
   AnimatedSize(
     duration: const Duration(milliseconds: 180),
     child: isExpanded
         ? Column(
             key: const ValueKey('expanded'),
             children: [
               for (final expansion in group.expansions)
                 Padding(
                   padding: const EdgeInsets.only(left: 32),
                   child: _CollectionListTile(item: expansion, onTap: onTap, showExpansionBadge: true),
                 ),
             ],
           )
         : const SizedBox.shrink(key: ValueKey('collapsed')),
   )
   ```
   （クロスフェードの透明度アニメーションは無くなるが、高さの滑らかな開閉は維持される。元の見た目の差は許容範囲とする。）
2. トグルアイコンの回転アニメーション（`_CollectionListTile` 内の `AnimatedRotation`）は変更しない。
3. `_CollectionGrid` 側は既に遅延構築になっているため変更不要（念のため `visibleItems` 組み立てロジックに手を入れないこと）。

---

## タスク3: `CollectionRepository.list()` と `facets()` のN+1解消（`lib/src/data/repo/collection_repository.dart`）
1. `list()` をゲームごとのループから一括取得＋メモリ上のマップ参照に変更する:
   ```dart
   final games = await _database.select(_database.games).get();
   final collectionRows = await _database.select(_database.collectionEntries).get();
   final collectionByKey = {for (final c in collectionRows) c.gameKey: c};
   final allSessions = await _playSessions.listAll();
   final sessionsByGameKey = <String, List<PlaySessionRecord>>{};
   for (final session in allSessions) {
     sessionsByGameKey.putIfAbsent(session.gameKey, () => []).add(session);
   }

   final parentKeysWithExpansions = { ... }; // 既存のまま
   final items = <CollectionListItem>[];
   for (final game in games) {
     final collection = collectionByKey[game.gameKey];
     if (collection == null) {
       continue;
     }
     final sessionRecords = game.gameKind == AppConstants.gameKindExpansion
         ? const <PlaySessionRecord>[]
         : (sessionsByGameKey[game.gameKey] ?? const <PlaySessionRecord>[]);
     final item = CollectionListItem(
       ...,
       playCount: sessionRecords.length,
       lastPlayedDate: sessionRecords.isEmpty ? null : sessionRecords.first.playedDate,
     );
     if (_matches(item, filter, parentKeysWithExpansions)) {
       items.add(item);
     }
   }
   ```
   **正しさの根拠**: `_playSessions.listAll()` は `playedDate desc, id desc` でソート済み（`t26` で保証）。`putIfAbsent...add()` によるグルーピングは元の順序を保つため、`sessionsByGameKey[key]` も同じゲーム内では「最新が先頭」のまま。よって `sessionRecords.first.playedDate` は従来の `listForGame()` 単体呼び出しと同じ値になる。`playCount`/フィルタ条件（`unplayedOnly` 等）にも影響しない。
2. `facets()` も同じパターンで `findCollection` の逐次呼び出しをやめ、`collectionByKey` を使う形にする（`list()` と同様、ゲーム1件ずつではなく一括取得した `collectionEntries` をマップ化して参照する）。

---

## タスク4: `PlaySessionRepository._recordsFromSessions()` のN+1解消（`lib/src/data/repo/play_session_repository.dart`）
1. セッションごとに `playSessionExpansions` を取りに行くループをやめ、一括取得＋グルーピングに変更する:
   ```dart
   Future<List<PlaySessionRecord>> _recordsFromSessions(List<PlaySession> sessions) async {
     if (sessions.isEmpty) {
       return const [];
     }
     final allExpansions = await _database.select(_database.playSessionExpansions).get();
     final expansionsBySessionId = <int, List<String>>{};
     for (final expansion in allExpansions) {
       expansionsBySessionId
           .putIfAbsent(expansion.playSessionId, () => [])
           .add(expansion.expansionGameKey);
     }
     return [
       for (final session in sessions)
         PlaySessionRecord(
           id: session.id,
           gameKey: session.gameKey,
           playedDate: session.playedDate,
           playerCount: session.playerCount,
           actualPlayingTime: session.actualPlayingTime,
           notes: session.notes,
           rating: session.rating,
           replayDesire: session.replayDesire,
           perceivedWeight: session.perceivedWeight,
           winnerMemo: session.winnerMemo,
           createdAt: session.createdAt,
           expansionGameKeys: (expansionsBySessionId[session.id] ?? const [])
             ..sort(),
         ),
     ];
   }
   ```
2. 元のSQL側 `OrderingTerm.asc(expansion.expansionGameKey)` をDart側の `..sort()`（文字列の自然順序）で代替している点に注意。`listForGame()`/`listAll()` どちらの経路からもこのメソッドを通るため、修正は1箇所で両方に効く。

---

## タスク5: テストの更新・追加
1. `test/t07_collection_repository_test.dart`:
   - 新規テスト「Gamesテーブルに存在するがCollectionEntriesに行がないゲームは `list()` と `facets()` の両方から除外される」を追加する（`database.upsertBggGame(...)` のみ呼び、`database.upsertCollection(...)` を呼ばないケース）。現状の `_insertBgg` ヘルパーは常に両方呼ぶため、この分岐は既存テストでカバーされていない。
   - 既存テスト（特に `'lists one thousand seed records'`、`'adds play counts last played dates and facets to list items'`、`'filters by mechanics designers expansions and unplayed status'`）が green のままであることを確認する。
2. `test/t26_play_session_repository_test.dart`:
   - 新規テスト「同一ゲームの複数セッションがそれぞれ複数の拡張キーを持つ場合でも、セッションをまたいで拡張キーが混ざらないこと、かつ各セッション内では昇順ソートされること」を追加する（既存テストは単一拡張キーのケースのみのため）。
   - 既存テスト `'lists sessions by played date desc then id desc'`、`'listAll returns sessions across games with expansion keys'` が green のままであることを確認する。
3. `test/widget_test.dart`（または新規 `test/t33_collection_list_widget_test.dart`、プロジェクトの番号付け規則に合わせてどちらか選択）:
   - 拡張セットを持つゲームをDBに登録した状態でコレクション一覧を表示し、**折りたたみ状態では拡張タイル（`showExpansionBadge` を持つ `_CollectionListTile` 相当のウィジェット、または拡張ゲームのタイトルテキスト）が `find` できないこと**、トグルボタンをタップした後は見つかることを確認するwidgetテストを追加する。

---

## タスク6: 手動確認（プロファイリング）
1. 既存の `'lists one thousand seed records'` テスト相当のシードデータ（または実機で100〜200件程度のコレクション）を用意し、修正前後で以下を比較する:
   - コレクション一覧の初回表示までの体感速度
   - 検索ボックスへの入力時のもたつき
   - ゲーム詳細画面から戻ったときの再描画の重さ
   - リスト表示で拡張グループが多いコレクションをスクロールしたときのなめらかさ
2. 可能であれば Flutter DevTools の Performance / Memory タブで、スクロール中のフレーム時間とImageCacheサイズを修正前後で比較する。

---

## 実装順序
タスク0（現状確認）→ タスク1（画像デコード）→ タスク2（AnimatedCrossFade）→ タスク4（PlaySessionRepositoryのN+1）→ タスク3（CollectionRepositoryのN+1、タスク4に依存）→ タスク5（テスト）→ タスク6（手動確認）

## 完了条件
- 折りたたみ中の拡張グループはウィジェットツリーに実体化されない（widgetテストで確認）
- サムネイルの `cacheWidth`/`cacheHeight` が実際の表示物理ピクセルサイズに基づいて設定されている
- `CollectionRepository.list()`/`facets()` のDB往復回数がコレクション件数に依存しない定数オーダーになっている
- `PlaySessionRepository.listAll()`/`listForGame()` のDB往復回数がプレイ記録件数に依存しない定数オーダーになっている
- Gamesテーブルに存在するがCollectionEntriesに行がないゲームが、従来通り `list()`/`facets()` から除外される（回帰テストで担保）
- 既存テスト（t07, t22, t23, t26, t28, t29系, t30, t31, t32, widget_test）が全てgreen
- 新規ユニットテスト・widgetテストが追加されている
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス
- 各タスク独立コミット、コミットメッセージにタスク番号を記載
