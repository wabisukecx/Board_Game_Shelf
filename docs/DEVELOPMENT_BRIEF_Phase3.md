# Codex用開発文書: Board Game Shelf Phase 3（BGGコレクション一括取り込み）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-13 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase3.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底・別紙1のBGGアクセス制御/レート制限） |
| 対象スコープ | **Phase 3**: BGGコレクション取得→既存登録動線への一括投入 |
| 非対象 | 評価/コメント/プレイ回数取り込み、BGGへの書き込み、自動定期同期、iOS・Desktop・Web |
| 実装エージェント | Codex |
| 前提 | Phase 0〜2 完了済み。本フェーズは T-31 から開始する |

---

## 0. 設計根拠（rationale）

- **取得と登録を分離して既存を再利用**: BGG `collection` は所持一覧（objectid群）を返すだけ。各 objectid の詳細取得・登録は既存 `BggRegistrationRepository.registerBggId`（thing取得＋パース＋upsert＋レート制限＋202＋キャッシュ）に丸投げする。新規の解析・スキーマは作らない。
- **冪等・再開可能**: `registerBggId` は `Created`/`AlreadyExists` を返す。既登録は **AlreadyExists でスキップ**（thing再取得しない）。途中キャンセル・再実行しても二重登録されない。
- **規約遵守**: コレクション取得も thing 取得も既存のレート制限・リトライ・202再取得（別紙1 / C-01〜C-09）を流用し、独自に速度を上げない。
- **認証の分離**: thing登録は既存どおりBearerトークン前提。コレクション取得は **BGGユーザー名**（非機密）が必要なので設定に追加する。
- **明示実行**: 自動取得しない。ユーザーが取得→プレビュー→「インポート開始」を操作したときのみ実行。

---

## 1. Codexへの引き渡し手順（人間向け）

1. 本文書を `docs/DEVELOPMENT_BRIEF_Phase3.md` として配置（配置済み）。
2. §2「冒頭プロンプト」をCodexの最初の指示として貼り付ける。
3. Codexは§5のタスクを `T-31` から順に実行し、各タスク完了時に受け入れ基準の充足を報告する。
4. 設計と矛盾が出たら実装を止めて報告（勝手に仕様を変えない）。本文書を改訂してから再開する。

## 2. 冒頭プロンプト（Codexへ最初に渡す指示）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 3（BGGコレクション一括取り込み）を実装します。
docs/REQUIREMENTS_Phase3.md と docs/DEVELOPMENT_BRIEF_Phase3.md が仕様書です。
Phase 0〜2 は完了済みで、既存コードを再利用します。以下を厳守してください。

1. §5のタスクを T-31 から番号順に実装する。並行着手しない。
2. 各タスクの受け入れ基準をテストコードで担保し、完了報告に
   「実装ファイル一覧 / テスト結果 / 基準との対応」を含める。
3. 各ゲームの詳細取得・登録は既存 BggRegistrationRepository.registerBggId に丸投げする。
   独自に thing 解析や upsert を作らない。AlreadyExists はスキップ（冪等）。
4. コレクション取得・thing取得とも既存のレート制限・リトライ・202再取得を流用し、
   独自に速度を上げない（別紙1 / C-01〜C-09）。
5. コレクション取得はBGGユーザー名（非機密）が必要。設定に追加する。トークンは既存を使う。
6. 自動実行しない。取得→プレビュー→「インポート開始」を明示操作したときのみ実行。
   進捗表示・キャンセル・連続失敗中断に対応する。
7. 対象は Android のみ。UI文言は assets/i18n/{ja,en}.json のキー経由（ハードコード禁止）。
8. §3 定数（既存 C-01〜35 / 本書 C-36〜38）は変更禁止。曖昧なら質問する。
まず T-31 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-36 | コレクション取得パラメータ | `subtype=boardgame`, `own=1`（既定: 所持のみ） | collection API | 要件§4 |
| C-37 | 既登録の扱い | `AlreadyExists` はスキップ（thing再取得しない／冪等） | 一括投入 | 要件§1.1 |
| C-38 | 連続失敗の中断閾値 | 5（連続5件失敗で中断し部分結果を表示） | インポート堅牢性 | 要件§7 |

補足: コレクション取得の **202再取得は既存 C-07**（3秒×最大3回）を流用。レート制限・リトライ・キャッシュは既存 C-01〜C-09 をそのまま使う。

---

## 4. 技術スタック・リポジトリ構成（追加分）

| 項目 | 指定 |
|---|---|
| API | 既存 `BggApiClient` に `collection(username, {own, subtype})` を追加（既存の transport/レート制限/リトライ/202/キャッシュ機構を通す） |
| 解析 | 既存 `BggXmlParser` に collection 解析（`<item objectid>` / name / yearpublished 抽出）を追加 |
| 登録 | 既存 `BggRegistrationRepository.registerBggId` を再利用（新規実装しない） |
| ユーザー名保存 | 非機密。`settings` テーブル経由のKVアクセサを用意（無ければ `SecureSettingsRepository` と同様の保存口を追加。secure storageでも可だが非機密の旨をコメント） |
| 状態管理 | 既存 Riverpod。インポート進捗（total/done/registered/skipped/failed/canceled）は StateNotifier 等で管理 |
| テスト | flutter_test + 既存のフェイク/インメモリDB。collection解析・202処理・スキップ/中断ロジックを純Dart/モックでテスト |

```
追加/変更ファイル（想定）:
lib/src/
  data/
    bgg/
      bgg_api_client.dart      … EDIT: collection(username, own, subtype) を追加
      bgg_xml_parser.dart      … EDIT: parseCollection(xml) → List<BggCollectionItem>(objectid/name/year) を追加
    repo/
      bgg_collection_repository.dart … NEW: fetchOwned(username) → List<BggCollectionItem>
    settings/
      secure_settings_repository.dart or 新規KV … EDIT/NEW: bggUsername の保存/読み出し（非機密）
  app/providers.dart           … EDIT: bggCollectionRepositoryProvider / importController(StateNotifier) 追加
  ui/pages/
    bgg_import_page.dart        … NEW: S-10 取得→プレビュー→進捗→サマリ
    settings_page.dart          … EDIT: BGGユーザー名欄を追加
    collection_list_page.dart   … EDIT: 登録メニュー（FAB）に「BGGから一括取り込み」を追加
assets/i18n/{ja,en}.json        … EDIT: bggImport.* / settings.bggUsername を追加
test/
  t16_bgg_collection_test.dart  … NEW: collection解析 / 202 / fetchOwned / 未設定エラー
README.md                       … EDIT: BGG一括取り込み手順・ユーザー名設定
```

---

## 5. 実装タスク（execution order・T-31〜T-35）

### T-31 コレクションAPI＋解析
- 内容: `BggApiClient` に `collection(username, {own=true, subtype='boardgame'})` を追加。既存の transport/レート制限/リトライ/**202再取得（C-07）**/キャッシュ機構を通す（`www`禁止のドメイン方針も踏襲）。`BggXmlParser` に `parseCollection` を追加し `<item objectid>`・name・yearpublished を抽出。
- 受け入れ基準:
  - [ ] 202→（待機）→200 の流れで最終的にアイテム配列を返す（FakeClock/モックで検証）
  - [ ] `own=1`/`subtype=boardgame` がクエリに付与される
  - [ ] 空コレクション・複数アイテムの両方を例外なく解析する
  - [ ] 202が解消しないときタイムアウト相当のエラーになる（無限ループしない）

### T-32 BggCollectionRepository
- 内容: `fetchOwned(username)` を実装（API→parse→`List<BggCollectionItem>`）。ユーザー名空はバリデーションエラー。トークン要否は既存 thing 登録側の挙動に委ねる（コレクション取得自体はユーザー名ベース）。
- 受け入れ基準:
  - [ ] 正常系で objectid/name/year のリストを返す
  - [ ] ユーザー名未指定/空でバリデーションエラーを返す
  - [ ] ネットワーク例外を呼び出し側が判別できる形で伝播/返却する

### T-33 設定（BGGユーザー名）
- 内容: BGGユーザー名（非機密）の保存/読み出しを追加し、S-05 設定画面に入力欄（保存/クリア・設定済み/未設定表示）を追加。
- 受け入れ基準:
  - [ ] ユーザー名を保存・再読込でき、未設定が判定できる
  - [ ] 機密（トークン/キー）と混同しない保存先で、ログ/エクスポートに漏れない

### T-34 S-10 インポートUI＋一括投入（E2Eコア）
- 内容: `bgg_import_page.dart` を新規作成。ユーザー名確認（未設定→S-05誘導、トークン未設定も誘導）→「コレクションを取得」（202中の表示）→プレビュー（総数/新規/既登録：既登録は `AppDatabase.findGame` 等で判定）→「インポート開始」で未登録 objectid を順次 `registerBggId` に投入。進捗（n/total・現在タイトル）、キャンセル、`AlreadyExists` スキップ、連続失敗中断（C-38）。完了サマリ（登録/スキップ/失敗）。S-01 のFAB登録メニューに導線を追加。完了後に一覧（collectionListProvider）を invalidate。
- 受け入れ基準:
  - [ ] 未登録のみ `registerBggId` に流れ、`AlreadyExists` はスキップされる
  - [ ] 進捗が更新表示され、キャンセルで安全に中断（そこまでの結果を保持）
  - [ ] 連続5件失敗で中断し、部分サマリが表示される
  - [ ] 再実行で二重登録されない（冪等）
  - [ ] 既存の検索/スキャン/画像認識/分析の各動線が回帰しない

### T-35 失敗時UX・i18n・ドキュメント仕上げ
- 内容: 要件§7の各ケース（ユーザー名未設定→S-05、トークン未設定→S-05、ネットワークなし、202未解消、個別失敗継続、キャンセル）。`bggImport.*`/`settings.bggUsername` のi18nキーを ja/en に追加。README にBGG一括取り込み手順・ユーザー名設定を追記。
- 受け入れ基準:
  - [ ] 追加文言がすべて ja/en のキー経由で、ハードコード文字列が無い
  - [ ] 各失敗ケースの表示/誘導が出る
  - [ ] `flutter analyze` 警告ゼロ、`flutter test` 全件パス

---

## 6. 既存資産マッピング（実装時に参照）

| 用途 | 既存シンボル | 所在 |
|---|---|---|
| BGG APIクライアント | `BggApiClient`（transport/レート制限/リトライ/202/キャッシュ。`collection` を追加） | `lib/src/data/bgg/bgg_api_client.dart` |
| XML解析 | `BggXmlParser`（`parseCollection` を追加） | `lib/src/data/bgg/bgg_xml_parser.dart` |
| ゲーム登録（再利用の中核） | `BggRegistrationRepository.registerBggId(bggId)` → `BggRegistrationCreated`/`BggRegistrationAlreadyExists` | `lib/src/data/repo/bgg_registration_repository.dart` |
| 既登録判定 | `AppDatabase.findGame(gameKey)`（gameKey=BGG ID文字列） | `lib/src/data/db/app_database.dart` |
| トークン | `SecureSettingsRepository`（readToken 等。既存の未設定誘導を流用） | `lib/src/data/settings/secure_settings_repository.dart` |
| 一覧更新 | `collectionListProvider`（インポート後に invalidate） | `lib/src/app/providers.dart` |
| 設定画面 | `SettingsPage`（BGGユーザー名欄を追加） | `lib/src/ui/pages/settings_page.dart` |
| 登録メニュー | `CollectionListPage` の FAB ボトムシート（導線追加） | `lib/src/ui/pages/collection_list_page.dart` |
| レート制限/202/リトライ定数 | C-01〜C-09（別紙1） | `docs/DEVELOPMENT_BRIEF.md` §3 |
| i18n | `I18n.t(key, vars)`（未定義キーはキー文字列を返す） | `lib/src/i18n/i18n.dart` |

---

## 7. 禁止事項・制約

1. **thing解析/upsert/登録を独自実装しない**。各 objectid は既存 `registerBggId` に丸投げする。
2. **レート制限・リトライ・202を独自に回避/高速化しない**。既存機構（C-01〜C-09）を通す。
3. **冪等を壊さない**。`AlreadyExists` はスキップ。再実行・キャンセル後再開で二重登録しない。
4. **自動実行しない**。取得・インポートはユーザーの明示操作で開始。進捗・キャンセル・連続失敗中断を備える。
5. **評価/コメント/プレイ回数の取り込み・BGGへの書き込みをしない**（本フェーズ範囲外）。
6. **スキーマ変更をしない**（BGGユーザー名設定の追加を除く）。ユーザー名は非機密として保存し、ログ/エクスポートに出さない。
7. 対象は **Android のみ**。UI文言ハードコード禁止（i18nキー経由）。テストは時刻・乱数・ネットワークに直接依存させず、抽象/モックを注入する。

---

## 8. 完了の定義（Phase 3 Done）

- T-31〜T-35 の全受け入れ基準がテストで担保され、`flutter test` が全件成功する
- `flutter analyze` 警告ゼロ
- 実機（Android）で「ユーザー名設定→コレクション取得→プレビュー→インポート→サマリ」のE2E動線が通る
- 既登録スキップ・キャンセル・連続失敗中断・再実行の冪等が確認できる
- 既存のレート制限・リトライ・202を流用し、独自に速度を上げていない
- README にBGG一括取り込み手順・ユーザー名設定が追記されている
