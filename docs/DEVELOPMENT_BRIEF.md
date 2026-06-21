# 開発文書: Board Game Shelf

| 項目 | 内容 |
|---|---|
| 文書バージョン | 1.0（統合版） |
| 最終更新 | 2026-06-21 |
| 位置づけ | `docs/archive/DEVELOPMENT_BRIEF_*.md`（Phase 0〜8、および運用改善ブリーフ群）を、開発履歴のサマリーとして1つに統合したもの。各フェーズの冒頭プロンプト・タスク別の詳細な実装指示・受け入れ基準・コードスニペットは `docs/archive/` の元文書を参照 |
| 対応する要件 | `docs/REQUIREMENTS.md`（統合版要件定義書） |
| 実装エージェント | Codex（仕様策定・レビューはClaude） |

---

## 1. 開発の進め方（規約）

このプロジェクトはAIDD（AI-Driven Development）で進めてきた。Claudeが要件定義・設計・タスク分割を行い、`docs/`にブリーフとして書き起こし、Codexがそれをタスク番号順に実装する。各フェーズ・各ブリーフで一貫している進め方:

1. 各タスクは独立コミット可能な粒度に分割し、依存順に直列実行する（並行着手しない）。
2. 各タスク完了時に「実装ファイル一覧／テスト結果／受け入れ基準との対応」を報告する。
3. 設計と矛盾が見つかった場合は実装を止めて報告する（独断で仕様を変えない）。矛盾が解消してから再開する。
4. UI文言は必ず `assets/i18n/{ja,en}.json` のキー経由で参照し、ハードコードしない。
5. 時刻・乱数・ネットワークに直接依存するテストは書かず、Clock/Random/Transport等の抽象を注入してユニットテストする。
6. 既存の定数・スキーマ・YAML互換仕様・移植ロジックは、明示的にそのフェーズの対象でない限り変更しない。

---

## 2. 技術スタック・リポジトリ構成

| 項目 | 指定 |
|---|---|
| フレームワーク | Flutter（stable最新）。Android優先、iOSビルドは壊さない |
| 状態管理 | Riverpod |
| ローカルDB | drift（SQLite） |
| HTTP | dio（インターセプタでレート制限・リトライを実装） |
| 機密保存 | flutter_secure_storage |
| 非機密設定 | shared_preferences（言語設定等） |
| XML解析 | package:xml |
| CSV解析 | package:csv（GameUPCオフラインキャッシュ取り込み用） |
| YAML | package:yaml（分析重み付けデータ読み込み・エクスポート） |
| テスト | flutter_test + mocktail。Clock/Random/Transportは注入可能にする |

```
lib/
  core/        … 定数(constants.dart)、Result型、Clock/Random抽象、barcode.dart（JAN正規化）
  data/
    db/        … drift スキーマ・DAO（app_database.dart）
    bgg/       … BggApiClient, RateLimiter, RetryPolicy, BggXmlParser, BggTransport
    gameupc/   … GameUpcClient（ライブAPI）, GameUpcCsvTransport（CSVダウンロード）
    vision/    … GeminiVisionClient（箱写真・棚写真の画像認識）
    repo/      … 各種Repository（collection / barcode_map / bgg_registration /
                  local_game / play_session / game_upc_cache / box_recognition /
                  shelf_recognition / bgg_collection / information_update）
  domain/      … GameNames, CollectionAnalytics, LearningCurveAnalyzer,
                  ComplexityTables, PlayAnalytics, display_names.dart
  ui/
    pages/     … 各画面（collection_list / game_detail / scan / search_registration /
                  local_game_form / photo_recognition / shelf_recognition /
                  bgg_import / dashboard / play_analytics / play_session_form / settings）
    widgets/   … 画面共有ウィジェット（candidate dialog, analytics sections 等）
  i18n/        … 文言ローダ（ドット区切りキー、未定義キーはキー文字列を返すフォールバック）
assets/
  i18n/        … ja.json, en.json（_meta付き。フォルダ指定でAssetManifestから動的列挙）
  analysis/    … mechanics_data.yaml, categories_data.yaml, rank_complexity.yaml
  gameupc/     … gameupc_seed.csv（GameUPCオフラインキャッシュの同梱シード）
docs/          … REQUIREMENTS.md, DEVELOPMENT_BRIEF.md（本書）, archive/（フェーズ別原本）
test/          … タスク単位のテスト（t01〜t34、命名は実装順の連番）
```

---

## 3. 定数表の要点

全定数は `lib/src/core/constants.dart` の `AppConstants` に一元管理されている。フェーズごとに採番した代表的なものを抜粋する（フルの対応表は `docs/archive/` 各ブリーフの §3 を参照）。

| ID範囲 | 概要 |
|---|---|
| C-01〜C-09 | BGG APIのレート制限（thing 15/分・search 20/分）・リトライ・202再取得・キャッシュTTL |
| C-10〜C-18 | 数値差分許容誤差、推奨人数の採用閾値、ID書式（BGG 6桁ゼロ埋め／ローカル`L`+5桁）、バックアップ命名 |
| C-19〜C-22 | バーコード受理形式（EAN-13/UPC-A正規化）、連続検出抑止時間、学習保存のsource値 |
| C-23〜C-30 | Vision（箱写真・棚写真）のモデル設定、送信前リサイズ、確信度下限、出力スキーマ、棚の最大検出数 |
| C-31〜C-35 | コレクション分析のTop-N件数、人数カバレッジ範囲、重さ/時間のバケット境界 |
| C-36〜C-38 | BGGコレクション取得パラメータ、既登録スキップ、連続失敗中断閾値 |
| C-39〜C-42 | 分析重み付けアセットパス、未知名称の既定値、指標レンジ、入力既定値 |
| C-43〜C-45 | ゲーム種別（base/expansion）、BGG拡張リンク種別、DBスキーマバージョン(6) |
| C-46〜C-51 | プレイ記録の評価系スケール（評価1-10・また遊びたい度1-5・重さの体感1.0-5.0刻み0.5）、DBスキーマバージョン(7)、お気に入り評価しきい値(7) |

> 2026-06の運用改善（§5後半）で、GameUPCオフラインキャッシュ関連の定数・GitHub配布向けの設定が追加されている。最新の正本は常に `constants.dart`。

---

## 4. データベーススキーマの変遷

| schemaVersion | 変更内容 |
|---|---|
| 1〜4 | Phase 0〜4。`games` / `collection` / `barcode_map` / `api_cache` / `settings` の基本構成 |
| 6 | Phase 5。`games` に `gameKind`（'base'/'expansion'）・`parentGameKey` を追加（拡張管理） |
| 7 | Phase 6-A。`play_sessions` / `play_session_expansions` を新規追加（プレイ記録） |
| 8 | 運用改善（GameUPCオフラインキャッシュ化）。`gameupc_cache` テーブルを新規追加 |

(schemaVersion 5は社内検証用に欠番。詳細はマイグレーションテスト `t24`/`t27`/`t34` を参照)

---

## 5. 開発履歴

### Phase 0（MVP）— `docs/archive/DEVELOPMENT_BRIEF_Phase0.md`（T-01〜T-10）
ローカルDB＋BGG検索登録＋boardgame_analyzer互換YAMLエクスポートというコア価値を最初に完成させた。i18n基盤、driftスキーマ（5テーブル）、BGG APIクライアント（レート制限・リトライ・202・キャッシュ）、XMLパーサ（日本語名2段判定・投票集計）、検索登録フロー、ローカル独自レコード登録、コレクション管理（一覧・詳細・最適人数バッジ）、情報更新（差分検出）、YAMLエクスポート、設定画面（APIキー・Gemini翻訳オプション〔後に削除〕・バックアップ）を実装。最大の技術リスク（バーコード解決・画像認識）はこの時点では意図的に対象外とした。

### Phase 1-A（バーコードスキャン登録）— T-11〜T-15
`mobile_scanner`によるJAN/EAN-13カメラ読み取り。BGGにはバーコード検索が無いため、`barcode_map`テーブルへの学習保存を軸に「既知JANは即ヒット、未知JANは検索/手動登録経由で登録時に学習」という非対称フローを構築。カメラ非対応・権限拒否時は手入力フォームにフォールバック。

### Phase 1-B（箱表紙の画像AI認識）— T-16〜T-20
`image_picker`で取得した箱表紙1枚をGemini マルチモーダルへ明示送信し、推定タイトルを既存のタイトル検索に合流させる`photo_recognition_page.dart`を追加。VisionはBGG IDを直接確定せず、必ず候補確認を挟む。

### Phase 1-C（棚全体の複数ゲーム同時検出）— T-21〜T-25
1-Bのvisionクライアントを多検出（JSON配列）に拡張し、棚画像から複数候補を一括レビュー→順次登録できる`shelf_recognition_page.dart`を追加。物体検出・クロップは実装せず、確認UIで誤り・取りこぼしを吸収する設計。

### Phase 2（コレクション分析ダッシュボード）— T-26〜T-30
完全オフライン・読み取り専用の集計ロジック`CollectionAnalytics`を純Dartで実装し、`dashboard_page.dart`で概要・分布・人数カバレッジ・Top-Nランキング・保管/入手時期を可視化。新規依存（チャートライブラリ等）は追加せず、組み込みウィジェットの横バーで描画。

### Phase 3（BGGコレクション一括取り込み）— T-31〜T-35
BGGの`collection`エンドポイント（202レスポンス対応）から所持ゲーム一覧を取得し、既存の`registerBggId`に丸投げする一括登録フロー`bgg_import_page.dart`を追加。既登録はスキップ（冪等）、進捗・キャンセル・連続失敗中断に対応。

### Phase 4（多次元分析指標の移植）— T-36〜T-40
姉妹プロジェクトboardgame_analyzerの戦略的深度・学習曲線等の算出ロジックを純Dartに忠実移植。重み付けデータ3 YAMLをアセット同梱し、`LearningCurveAnalyzer`が10指標＋分類を算出。詳細画面とダッシュボードに反映。

### Phase 5（拡張管理）— T-41〜T-45
`games`テーブルに`gameKind`/`parentGameKey`を追加（schemaVersion 6）。BGGの`boardgameexpansion`リンクから親子関係を判定し、新規登録直後に拡張候補を提示。コレクション一覧で拡張を親の直下にインデント表示する`groupCollectionItems`を実装。評価ロジック（Phase 4）は変更せず、拡張では案内文に置換。

### Phase 6-A〜6-D（プレイを起点とした活用）
- **6-A（DB・Repository）** — T-46〜T-49: `play_sessions`/`play_session_expansions`を追加（schemaVersion 7）。評価スケールをBGGの尺度に統一（評価1-10、重さの体感1.0-5.0）。`PlaySessionRepository`を新規実装。
- **6-B（UI）** — T-50〜T-53: ゲーム詳細画面に「プレイ記録」セクションと`PlaySessionFormPage`を追加。追加・削除のみ（編集なし）。
- **6-C（探す・絞り込み拡充）** — T-54〜T-57: `CollectionListItem`に`playCount`/`lastPlayedDate`を追加し、メカニクス・デザイナー・拡張あり・未プレイのフィルタと最終プレイ日順ソートを既存の一覧に統合。
- **6-D（プレイ傾向分析）** — T-58〜T-61: `PlayAnalyticsPage`を新規追加。よく遊ぶメカニクス/デザイナー、評価が高いメカニクス/デザイナー、公称時間との差、人数別評価、「最近遊んでいないお気に入り」を可視化。`dashboard_page.dart`の共有ウィジェットを`analytics_sections.dart`に抽出。

### Phase 7（設定画面での言語選択）
`assets/i18n/`配下のJSONを`AssetManifest`で動的列挙し、`_meta`（locale/displayName）から選択肢を構築。`shared_preferences`に言語設定を保存（秘密情報ではないためセキュアストレージとは分離）。選択は即時反映、未対応言語は英語にフォールバック。`pubspec.yaml`のi18nアセット指定を個別列挙からフォルダ指定に変更し、新規言語ファイルの追加だけで選択肢に出るようにした。

### Phase 8（ゲーム名のUI言語連動表示）
従来 `collection_repository.dart` にあった「常に日本語優先」のハードコードされた表示名解決ロジック（`resolveJapaneseDisplayName`/`resolveJapaneseSubtitle`）を、`domain/display_names.dart`の言語引数付きリゾルバ（`resolveDisplayName`/`resolveSubtitle`）に置き換え。UI言語に応じて日本語名/英語名を優先表示し、無い場合は英語名にフォールバック。検索は全言語名を対象にしたまま維持（回帰なし）。

---

## 6. 運用改善・後続対応（2026-06）

Phase 8完了後、機能追加よりも品質・運用面の改善を中心に対応した。

### 拡張の親解決まわりの改善
- **ExpansionParentSelection**: BGGの拡張リンクが複数の親候補を持ちうるケース（同一シリーズの複数版等）で、Phase 5時点の「最初の1件を採用」という単純化が誤判定を招く場合があったため、親候補の解決ロジックを補強した。
- **ExpansionCandidateOptIn**: 新規ベースゲーム登録直後に表示される拡張候補シートの体験を見直し、ユーザーが任意のタイミングで確認・スキップできる形に調整した。

### UI仕上げ
- **DetailPageCleanup**: ゲーム詳細画面の文言・セクション構成を整理し、表示の重複や分かりにくい表現を解消した。

### コレクション一覧のパフォーマンス改修
ゲームを100件以上登録すると一覧のスクロールが滑らかでなくなる、という不具合を調査し、3つの原因を特定・修正した。

1. サムネイル画像が`cacheWidth`/`cacheHeight`を指定せずソース解像度のままデコードされていた → 実際の表示物理ピクセルサイズに基づくデコードサイズ指定を追加。
2. `AnimatedCrossFade`が折りたたみ中の拡張タイル（画像含む）も常にビルド・描画していた → `AnimatedSize`＋条件分岐ビルドに変更し、見えていないタイルのコストをゼロに。
3. `CollectionRepository.list()`/`facets()`、`PlaySessionRepository.listAll()`/`listForGame()`がゲーム件数・プレイ記録件数に比例したN+1クエリ（1件ずつのDB往復）になっていた → 一括取得＋メモリ上のマップ参照に変更し、DB往復回数を件数によらず一定にした。

### GameUPCオフラインキャッシュ化
GameUPC側の無償API提供に契約的な保証がないことを踏まえ、ランタイムAPI依存を下げるための施策。

- GameUPCが公開しているCSVダンプ（`https://gameupc.com/dumps/latest/gameupc.csv`）をビルド時に同梱（`assets/gameupc/gameupc_seed.csv`）し、初回起動時に自動でローカルキャッシュ（`gameupc_cache`テーブル、schemaVersion 8）へ取り込む。
- 設定画面から手動でオンライン更新を試みられるが、自動バックグラウンド更新は行わない（GameUPC側への配慮、既存の「明示操作のみで外部API呼び出し」方針との一貫性）。
- CSVのフィールド内カンマ・先頭ゼロのバーコード・全ゼロのダミー行など、実データに即した正規化・除外処理を実装。
- バーコード解決の優先順位は「ローカル学習済み→GameUPCオフラインキャッシュ→ライブGameUPC API→手動検索」に拡張（§3.3参照）。

### 翻訳機能の残骸整理
説明文のGemini翻訳機能はUIから既に削除されていたが、バックエンド実装（`DescriptionTranslationRepository`/`GeminiTranslationClient`）・関連provider・テスト・i18n文言・README記述が孤立して残っていた。これらを完全に削除し、Geminiキーの設定画面の表示を「写真・棚画像の認識」専用の表現に統一した。`Games.descriptionJa`カラムはデータ保護のため変更していない（マイグレーションなし）。

### GitHub配布対応
Google Play公開ではなくGitHub Releasesでの配布に方針変更したことに伴う対応。

- リリースビルドのAndroidManifestに`INTERNET`権限が欠落していた実装バグを修正（配布方法に関係なく必須の修正）。
- `applicationId`/`namespace`をFlutterテンプレートのデフォルト値（`com.example.*`）から一意な値に変更。
- リリース署名を、`key.properties`が存在しない場合は明示的にビルドを失敗させる構成にし、debug鍵での誤配布を構造的に防止。
- リポジトリルートに`LICENSE`（MIT）を追加。
- 設定画面にBGG/GameUPCの出典クレジット表示を追加（BGG XML API利用規約の必須条件）。
- READMEにGitHub Releases経由のインストール手順・Play Protectの警告に関する案内・SHA-256検証手順を追記。

---

## 7. テスト構成

`test/`配下は実装順の連番（t01〜t34、一部は機能追加に伴い既存ファイルへのケース追加で対応）。主な対象:

| 範囲 | 対象 |
|---|---|
| t01〜t10 | i18n、DB、BGG APIクライアント/パーサ、登録Repository、エクスポート、設定/バックアップ |
| t11〜t14 | バーコード正規化、barcode_map、箱写真/棚写真認識 |
| t15〜t19 | コレクション分析、BGGコレクション取込、複雑度テーブル/学習曲線 |
| t20〜t27 | 拡張パーサ/登録/グルーピング、DBマイグレーション(v6/v7)、GameUPCクライアント、プレイ記録Repository |
| t28〜t32 | プレイ記録UI、BGG関係性ソース、プレイ傾向分析、プレイ対象者、言語設定、表示名 |
| t33〜t34 | GameUPCオフラインキャッシュRepository、DBマイグレーション(v8) |

各タスク完了時に `flutter analyze`（警告ゼロ）・`flutter test`（全件パス）を確認することを完了条件としている。

---

## 8. 既知の未解決事項

- **GameUPC CSVダンプの再配布可否**: `assets/gameupc/gameupc_seed.csv`としてアプリ・公開リポジトリに同梱しているが、GameUPC側の正式な利用規約文書は確認できておらず、開発者本人からGameUPCへの直接確認が未完了。Bulk再配布が問題になった場合は、シードデータの削除・縮小を検討する必要がある。
- **対象SDKバージョンの確認**: GitHub配布ではPlay Storeのような強制力はないが、新しいAndroidバージョンでの非互換警告を避けるため、`targetSdk`が妥当な水準にあるか定期的に確認すること。

---

## 9. 参照

- `docs/REQUIREMENTS.md` — 統合版要件定義書
- `docs/archive/` — フェーズ別の元のREQUIREMENTS/DEVELOPMENT_BRIEF文書一式（詳細なタスク分割・受け入れ基準・コードスニペットはこちら）
- `README.md` / `README.ja.md` — エンドユーザー・開発者向けセットアップ手順
