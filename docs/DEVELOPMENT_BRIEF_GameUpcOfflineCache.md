# Board Game Shelf 改修ブリーフ：GameUPCオフラインキャッシュ化（Codex向け）

## 前提・対象
- 対象: `C:\Users\tucon\StudioProjects\bg_shelf_scanner`（Flutter / Riverpod / Drift）
- 目的: バーコード解決をライブの `api.gameupc.com` 呼び出しに依存させず、GameUPCが公開しているCSVダンプをローカルSQLiteに取り込んでオフラインキャッシュとして使う。GameUPC側の無償提供に契約的な保証はないため、ランタイム依存を下げて長期的な安定性を確保する。
- 既存のライブGameUPC API呼び出し（`game_upc_client.dart`／`scan_page.dart`）は**置き換えない**。CSVキャッシュで解決できなかった場合のフォールバックとして残す。
- 各タスクは独立コミット可能な粒度。既存テストを壊さないこと。各タスク完了時に `flutter analyze` と `flutter test` を実行。

## 重要な背景（調査済みの事実 — これに合わせて実装すること）

### CSVの実体（実際にダウンロードして確認済み）
- URL: `https://gameupc.com/dumps/latest/gameupc.csv`（旧メモにあった `gameupc.com/data/gameupc.csv` ではない。古いURLは使わないこと）
- ヘッダー行あり、4列: `barcode,bgg_id,version_id,name`
- 例:
  ```
  barcode,bgg_id,version_id,name
  "0091039056052",19095,30887,"Star Fleet Battles: Module K – Fast Patrol Ships"
  "4250231700217",31260,,"Agricola"
  "5011921968923",194990,,"Warhammer 40,000 (Third Edition): Codex – Eldar"
  ```
- `barcode`/`name` はダブルクォート付き文字列、`bgg_id`/`version_id` はクォートなしの数値（`version_id` は空のことが多い）。
- **フィールド内にカンマを含む行が実在する**（上記 `Warhammer 40,000` の例）。RFC4180準拠のCSVパーサで読むこと。単純な `line.split(',')` は禁止。
- **バーコード桁数が不揃い**: 大半は13桁（先頭0埋め済みEAN-13。例 `"0091039056052"`）だが、`"853533008506"`（12桁）のように素のUPC-Aのまま格納されている行もある。**CSVの `barcode` 列は、既存の `lib/src/core/barcode.dart` の `BarcodeNormalizer.normalize()` に必ず通してから保存・照合すること**（12桁→13桁ゼロ埋め＋EAN-13チェックディジット検証は既存ロジックをそのまま使う）。チェックディジットが合わない・桁数が不正な行は取り込み対象から除外し、件数をログに残す。
- **ダミー行を除外する**: `"000000000000",111341,132676,"The Great Zimbabwe"` のような全ゼロバーコードの行が存在する。`BarcodeNormalizer` を通すと有効なEAN-13（`0000000000000`）として通ってしまうため、**取り込み時に明示的に `barcode` の正規化後の値が全て `0` の行をスキップする**こと。
- 同一 `barcode` が複数行に出現する可能性がある（要件として「重複しない」という保証は確認できていない）。取り込み時は**後勝ち（後の行で上書き）でよく、エラーにしない**こと。
- ファイル全体の行数・サイズは未確認（数千〜数万行規模と推定）。タスク1で実際にダウンロードして確認すること。

### ダウンロードの実現可否（未検証のリスク）
以前の調査で、素の `curl` だと `gameupc.com/data/gameupc.csv`（旧URL）への直接アクセスが403になるという報告があった。新URL（`/dumps/latest/gameupc.csv`）でも同様にCloudflare等のボット対策がかかっている可能性があり、**アプリ内のDioによるランタイムダウンロードが確実に成功するとは限らない**。この前提で、以下の二層構成にする：

1. **ビルド時同梱シード**: 開発時に一度CSVをダウンロードし、Flutterアセットとして同梱する。ネットワーク不要で確実に動く「最低保証ライン」。
2. **任意の手動オンライン更新**: 設定画面から明示的にボタンを押したときだけ、最新CSVのダウンロードを試みる。失敗してもシードデータで動き続けるため、アプリの動作に支障は出ない。

自動バックグラウンド更新や起動時の自動フェッチは行わない（このアプリの既存方針＝翻訳・Vision認識・BGG一括取込と同じく、ネットワークを伴う重い処理はユーザーの明示操作でのみ実行する、に合わせる）。

---

## タスク0: 現状確認・実データ取得
1. `https://gameupc.com/dumps/latest/gameupc.csv` を実際にブラウザまたは開発機からダウンロードし、行数・ファイルサイズ・ヘッダーが `barcode,bgg_id,version_id,name` であることを確認する。Codexの実行環境からのダウンロードが失敗する場合（403等）は、開発者（Nagasawa氏）がブラウザ経由で手動ダウンロードして渡すフローに切り替える。
2. `lib/src/data/gameupc/game_upc_client.dart`（既存のライブAPIクライアント）、`lib/src/data/bgg/bgg_transport.dart`（Transport抽象化のお手本にする既存パターン）、`lib/src/ui/pages/scan_page.dart`、`lib/src/core/barcode.dart` を読み、既存の実装パターンと命名規則を把握する。

---

## タスク1: 新規テーブル・マイグレーション（`lib/src/data/db/app_database.dart`）
1. 新規テーブルを追加する:
   ```dart
   @TableIndex(name: 'gameupc_cache_barcode_idx', columns: {#barcode})
   class GameUpcCacheEntries extends Table {
     @override
     String get tableName => 'gameupc_cache';

     TextColumn get barcode => text()(); // 正規化済みEAN-13
     TextColumn get bggId => text()();
     TextColumn get versionId => text().nullable()();
     TextColumn get name => text()();

     @override
     Set<Column<Object>> get primaryKey => {barcode};
   }
   ```
2. `@DriftDatabase(tables: [...])` に `GameUpcCacheEntries` を追加し、`schemaVersion` を8に上げ、`onUpgrade` に `if (from < 8) { await m.createTable(gameUpcCacheEntries); }` を追加する。
3. 取り込み日時・取り込み元（シード／オンライン更新）の管理は、新しいカラムやテーブルを増やさず、既存の `SettingsEntries`（key-valueテーブル）を流用する。キー例: `gameupc_cache_imported_at`（ISO8601文字列）、`gameupc_cache_source`（`bundled` または `remote`）。

---

## タスク2: ダウンロード専用Transport（`lib/src/data/gameupc/game_upc_csv_transport.dart`）
既存の `BggTransport`/`DioBggTransport` パターン（`bgg_transport.dart`）を踏襲し、テスト時にネットワークを使わずモックできるようにする。
```dart
abstract interface class GameUpcCsvTransport {
  Future<String> fetchCsv();
}

class DioGameUpcCsvTransport implements GameUpcCsvTransport {
  DioGameUpcCsvTransport({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  @override
  Future<String> fetchCsv() async {
    final response = await _dio.get<String>(
      AppConstants.gameUpcCsvDumpUrl,
      options: Options(
        responseType: ResponseType.plain,
        headers: const {
          'Accept': 'text/csv',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) BoardGameShelf/1.0',
        },
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final body = response.data;
    if (body == null || body.isEmpty) {
      throw const GameUpcCsvException('Empty response body');
    }
    return body;
  }
}

class GameUpcCsvException implements Exception {
  const GameUpcCsvException(this.message);
  final String message;
  @override
  String toString() => 'GameUpcCsvException: $message';
}
```
`AppConstants.gameUpcCsvDumpUrl` を `lib/src/core/constants.dart` に追加する（値: `https://gameupc.com/dumps/latest/gameupc.csv`）。

---

## タスク3: `GameUpcCacheRepository`（`lib/src/data/repo/game_upc_cache_repository.dart`）
1. CSVパース用に `csv` パッケージを依存に追加する（`flutter pub add csv`。バージョンは最新安定版でよい）。
2. パース・正規化・取り込みをまとめたメソッドを実装する:
   ```dart
   class GameUpcCacheRepository {
     GameUpcCacheRepository({
       required AppDatabase database,
       required GameUpcCsvTransport transport,
       Clock clock = const SystemClock(),
       BarcodeNormalizer normalizer = const BarcodeNormalizer(),
     }) : ...;

     Future<GameUpcCacheLookupResult?> lookup(String normalizedJan) async { ... }

     Future<GameUpcCacheImportSummary> importCsv(
       String csvContent, {
       required String source, // 'bundled' or 'remote'
     }) async { ... }

     Future<GameUpcCacheImportSummary> importBundledSeedIfEmpty() async { ... }

     Future<GameUpcCacheImportSummary> refreshFromRemote() async {
       final csv = await _transport.fetchCsv();
       return importCsv(csv, source: 'remote');
     }

     Future<GameUpcCacheStatus> status() async { ... }
   }
   ```
3. **CSVパースはメインアイソレートをブロックしないよう `compute()` で別アイソレートに逃がす**こと（数万行規模を想定。直前のパフォーマンス改修と矛盾する実装にしないこと）。`package:csv` の `CsvToListConverter` は **`shouldParseNumbers: false` を必ず指定する**（バーコード列の先頭ゼロが数値変換で消えるのを防ぐため。例 `"0091039056052"` が `91039056052` になってしまう事故を避ける）。
4. 取り込みロジック（`compute()` で実行する純粋関数として実装してよい）:
   - 1行目がヘッダー（`barcode,bgg_id,version_id,name` のいずれかの大文字小文字違いでも可）であることを確認し、データ行から除外する。ヘッダーが想定と異なる場合は警告ログを出しつつ処理は継続する（フォーマット変更の早期検知用）。
   - 各行について `BarcodeNormalizer.normalize(barcode)` を実行。無効な行（チェックディジット不正・桁数不正）はスキップし、スキップ件数をカウントする。
   - 正規化後の値が `'0000000000000'`（全ゼロ）の行はスキップする。
   - `bgg_id` が空または数値でない行はスキップする。
   - 同一 `barcode` が複数行に出現した場合は後勝ちでよい（`Map<String, _Row>` に詰めてから一括書き込みすれば自然に後勝ちになる）。
5. **DB書き込みはDriftの `batch()` を使い、1トランザクションでまとめて行うこと**（1行ずつ `await insertOnConflictUpdate` するN+1パターンは禁止。直前のパフォーマンス改修ブリーフの教訓と矛盾させないこと）:
   ```dart
   await _database.batch((batch) {
     batch.insertAllOnConflictUpdate(_database.gameUpcCacheEntries, companions);
   });
   ```
   既存データは一括取り込みの前に `delete(gameUpcCacheEntries)` で全削除してから入れ直す方式でよい（差分更新は今回のスコープ外。シンプルに「フルリプレース」とする）。
6. 取り込み完了後、`SettingsEntries` に `gameupc_cache_imported_at`（取り込み時刻）と `gameupc_cache_source`（`'bundled'`/`'remote'`）を保存する。
7. `lookup(normalizedJan)` は単純な主キー検索（`findGameUpcCache` 相当のヘルパーを `AppDatabase` に追加してもよい）。
8. `importBundledSeedIfEmpty()` は、`gameUpcCacheEntries` の件数が0件のときだけ `rootBundle.loadString('assets/gameupc/gameupc_seed.csv')` を読み、`importCsv(..., source: 'bundled')` を呼ぶ。0件でなければ何もしない（冪等）。
9. `status()` は件数（`SELECT COUNT(*)`）と `SettingsEntries` から読んだ取り込み日時・ソースをまとめて返す（設定画面表示用）。

---

## タスク4: シードデータの同梱
1. `https://gameupc.com/dumps/latest/gameupc.csv` をダウンロードし、`assets/gameupc/gameupc_seed.csv` として保存する（タスク0でダウンロード済みのものを使う）。
2. `pubspec.yaml` の `flutter: assets:` に `assets/gameupc/` を追加する。
3. ファイルサイズが大きすぎる場合（目安: 20MB超）は、developerと相談の上で圧縮同梱（`.csv.gz` + `archive` パッケージで解凍）を検討する。まずは無圧縮で試し、実測サイズを確認してから判断すること。

---

## タスク5: `scan_page.dart` への統合
`_resolve()` の流れを、既存のローカル学習済み判定とライブGameUPC API呼び出しの**間**にCSVキャッシュ参照を挟む形に変更する。

1. `barcodeMapRepository.resolve(jan)` が `miss` を返した後、**ライブAPIを呼ぶ前に** `gameUpcCacheRepository.lookup(jan)` を試す。
2. キャッシュにヒットした場合、既存の `GameUpcCandidate` 型を流用して候補オブジェクトを作る（新しいUIや確認ダイアログを増やさず、既存の自動登録経路にそのまま乗せる）:
   ```dart
   final cacheHit = await ref.read(gameUpcCacheRepositoryProvider).lookup(jan);
   if (cacheHit != null) {
     final candidate = GameUpcCandidate(
       bggId: cacheHit.bggId,
       name: cacheHit.name,
       confidence: 100,
       thumbnailUrl: null,
       updateUrl: null,
     );
     await _registerGameUpcCandidate(candidate, jan: jan, source: source, vote: false);
     return;
   }
   ```
   - `vote: false` 固定（キャッシュ由来の候補にはGameUPCへの投票用 `updateUrl` がないため）。
   - `_registerGameUpcCandidate()` 内の `registerBggId()` が失敗した場合（BGG ID が無効・削除済み等）は、**既存のcatchブロックでエラーメッセージを出して終わる現状の挙動のままでよい**が、可能であればその場合に限り従来のライブGameUPC API（`_tryGameUpc`）へフォールバックする一文を加える（必須ではないが推奨。タスクとして難しければ見送ってよく、その場合は完了条件から該当項目を除く）。
3. キャッシュがミスした場合は、**既存の `_tryGameUpc()` 呼び出しをそのまま実行する**（変更不要）。
4. メッセージ文言（`_message` の更新）は、キャッシュヒット時は新規i18nキー（例 `scan.cacheResolving`）を使い、「オフラインデータで照合中」のように、ライブAPI呼び出し中の文言（`scan.gameUpcResolving`）と区別がつくようにする。

---

## タスク6: 設定画面（`lib/src/ui/pages/settings_page.dart`）
1. 新しいセクション「GameUPCオフラインデータ」を追加する。
2. `gameUpcCacheStatusProvider`（`FutureProvider.autoDispose<GameUpcCacheStatus>`）を `providers.dart` に追加し、件数と最終更新（取り込み元・日時）を表示する:
   - 例: 「32,481件のバーコード情報（内蔵データ、2026-06-01時点）」
   - 未取込（0件、起こり得ないはずだが念のため）の場合は「未読み込み」と表示する。
3. 「最新データを取得」ボタンを設置し、押下時に `gameUpcCacheRepositoryProvider.refreshFromRemote()` を呼ぶ。
   - 処理中はボタンを無効化しつつ `CircularProgressIndicator` を表示する。
   - 成功時は件数・日時の表示を更新する（`ref.invalidate(gameUpcCacheStatusProvider)`）。
   - 失敗時（ネットワークエラー・403等）は `t.t('settings.gameUpcCacheUpdateFailed')` のようなメッセージをスナックバーで表示し、**既存のキャッシュデータはそのまま残す**（失敗してもアプリの動作に支障が出ないことを確認する）。

---

## タスク7: i18n文言追加（`assets/i18n/ja.json`, `assets/i18n/en.json`）
新規キー（例。実際の文言は既存の言い回しに合わせて調整してよい）:
- `scan.cacheResolving`（例: 「オフラインデータで照合中 ({jan})」）
- `settings.gameUpcCacheTitle`（例: 「GameUPCオフラインデータ」）
- `settings.gameUpcCacheStatus`（例: 「{count}件のバーコード情報（{sourceLabel}、{date}時点）」）
- `settings.gameUpcCacheSourceBundled` / `settings.gameUpcCacheSourceRemote`（例: 「内蔵データ」/「オンライン更新」）
- `settings.gameUpcCacheUpdateButton`（例: 「最新データを取得」）
- `settings.gameUpcCacheUpdateFailed`（例: 「データ取得に失敗しました。既存のデータを引き続き使用します。」）

---

## タスク8: テストの追加
新規ファイル `test/t33_game_upc_cache_repository_test.dart`（プロジェクトの番号付け規則の続き）:
1. **正規化のテスト**: 13桁そのまま（`"0091039056052"`）、12桁→13桁ゼロ埋め（`"853533008506"`）の両方が同じ形式で保存されること。
2. **先頭ゼロ保持のテスト**: `shouldParseNumbers: false` の検証も兼ねて、`"0091039056052"` を含むCSVを取り込んだ後、`lookup('0091039056052')` がヒットすること（数値変換で先頭ゼロが消えていないことの確認）。
3. **ダミー行除外のテスト**: `"000000000000",111341,132676,"The Great Zimbabwe"` を含むCSVを取り込んでも、正規化後の全ゼロJANではヒットしないこと。
4. **カンマを含む名前のテスト**: `"5011921968923",194990,,"Warhammer 40,000 (Third Edition): Codex – Eldar"` を含むCSVが正しく4列として読まれ、`name` に `"Warhammer 40,000 (Third Edition): Codex – Eldar"` 全体が入ること（カンマで列がずれないこと）。
5. **重複バーコードのテスト**: 同一 `barcode` が2回出現するCSVを取り込んでも例外にならず、後の行の内容で上書きされること。
6. **不正行のスキップのテスト**: チェックディジットが不正なバーコード、`bgg_id` が空の行が、エラーにせずスキップされ、件数としてカウントされること。
7. **`importBundledSeedIfEmpty()` の冪等性のテスト**: 2回連続で呼んでも2回目は何もしない（件数が変わらない）こと。
8. **`status()` のテスト**: 取り込み後に件数・`source`・日時が正しく返ること。

既存テストへの影響確認:
- `test/t25_game_upc_client_test.dart`（ライブAPIクライアント）は変更不要のはず。挙動が変わっていないことを確認する。
- `test/widget_test.dart` がフルアプリをブートストラップしている場合、新規テーブル追加後も例外なく起動することを確認する。

---

## タスク9: README更新
`README.md` / `README.ja.md` の「バーコードスキャン」セクションに、以下を追記する:
- バーコード解決の優先順位（ローカル学習済み → 内蔵GameUPCオフラインデータ → ライブGameUPC API → 手動検索）。
- オフラインデータはアプリに同梱されており、APIキーなしで利用できること。
- 設定画面から手動でオフラインデータを最新化できること（ネットワークが必要、失敗しても既存データは保持されること）。
- データ提供元（GameUPC, https://gameupc.com）のクレジット。

---

## タスク10: 手動確認
1. アプリを新規インストールした状態で、内蔵シードデータに含まれるバーコード（例: タスク0で確認したCSVの中から実在の商品を1つ選ぶ）をスキャンし、ネットワークなし（機内モード）でもBGG登録まで完了することを確認する。
2. 設定画面の「最新データを取得」を押し、成功・失敗それぞれのケースでUIが適切に反応することを確認する（失敗時にアプリがクラッシュしない、既存データが消えないこと）。
3. 内蔵データにもライブAPIにも存在しないバーコードをスキャンし、従来通り手動検索・手動登録に誘導されることを確認する。

---

## 実装順序
タスク0（実データ確認）→ タスク1（スキーマ）→ タスク2（Transport）→ タスク3（リポジトリ）→ タスク4（シード同梱）→ タスク5（scan_page統合）→ タスク6（設定画面）→ タスク7（i18n）→ タスク8（テスト）→ タスク9（README）→ タスク10（手動確認）

## 完了条件
- 機内モードでも、内蔵シードデータに含まれるバーコードはBGG登録まで完了する
- CSV取り込みは正規化（先頭ゼロ保持・チェックディジット検証・全ゼロ行除外）を経てから保存される
- カンマを含むゲーム名（例: `Warhammer 40,000 ...`）が壊れずに取り込まれる
- CSV取り込みのDB書き込みはバッチ処理で行われ、行数に比例してDB往復回数が増えない
- CSVパースはメインアイソレートをブロックしない（`compute()` 使用）
- 設定画面から手動でオンライン更新でき、失敗してもアプリの動作・既存データに影響しない
- ライブGameUPC API（`game_upc_client.dart`）の既存の挙動・テストは変更されていない
- 既存テスト（特にt11, t12, t25, widget_test）が全てgreen
- 新規ユニットテスト（`t33_game_upc_cache_repository_test.dart`）が追加され、上記の実データ由来のエッジケース（先頭ゼロ・全ゼロ行・カンマ入り名前・重複行）をカバーしている
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス
- 各タスク独立コミット、コミットメッセージにタスク番号を記載
