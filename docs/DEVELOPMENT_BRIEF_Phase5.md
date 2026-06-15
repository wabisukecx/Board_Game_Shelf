# Codex用開発文書: Board Game Shelf Phase 5（拡張（Expansion）管理）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase5.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底） ③`docs/DEVELOPMENT_BRIEF_Phase4.md`（既存定数・構成の参照） |
| 対象スコープ | **Phase 5**: 拡張（expansion）の所持・プレイ管理（評価ロジックは変更しない） |
| 非対象 | 拡張へのPhase4指標算出／合成評価／プレイ記録／拡張専用フィルタ／グリッドのネスト表示／一括登録／ローカルレコードの親子設定／iOS等の拡大 |
| 実装エージェント | Codex |
| 前提 | Phase 0〜4完了済み（リポジトリ上にPhase4実装物を確認済み。`flutter analyze`/`flutter test`は着手前に実行・確認すること）。本フェーズは **T-41** から開始する |

---

## 0. 設計根拠（rationale）

- **評価ロジック非改変**: Phase 4の10指標・分類アルゴリズム（`learning_curve.dart`/`complexity_tables.dart`）には一切手を入れない。拡張は`gameKind='expansion'`として識別し、UI側で分析セクションを案内文に置換するのみ。
- **既存登録経路の再利用**: 新規APIエンドポイント・新規リポジトリクラスを増やさず、`BggRegistrationRepository.registerBggId`を拡張する。拡張も基本ゲームと同じ`games`/`collection`テーブルの1行として扱う。
- **親未登録の許容**: `parentGameKey`は`games.gameKey`へのFK制約を持たない単純なTEXT列とする。これにより「拡張だけ先に登録」が常に成功し、後から`registerBggId(parentGameKey)`を呼ぶだけで親を補完できる（検索UIを介さない最短経路）。
- **拡張候補提示は新規登録直後のみ**: 既にBGGから取得済みのレスポンス（`BggGameDetails.expansionLinks`）を再利用するため、追加のAPIコール・レート消費が発生しない。既存登録（`BggRegistrationAlreadyExists`）では候補提示を行わない。
- **方向性（inbound判定）はフィクスチャで確認してから実装**: BGGの`link type="boardgameexpansion"`の`inbound`属性の意味は実データで検証する。矛盾があれば実装前に報告し、本書を修正する。

---

## 1. 引き渡し手順（人間向け）

1. 本文書と`REQUIREMENTS_Phase5.md`を`docs/`に配置（配置済み）。
2. §2「冒頭プロンプト」をCodexに渡す。
3. Codexは§5のタスクを`T-41`から順に実行し、各完了時に「実装ファイル/テスト結果/受け入れ基準との対応」を報告する。
4. 設計と矛盾が出たら停止して報告する（特にT-41のinbound方向性確認）。

## 2. 冒頭プロンプト（Codexへ最初に渡す）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 5（拡張（expansion）管理）を実装します。
docs/REQUIREMENTS_Phase5.md と docs/DEVELOPMENT_BRIEF_Phase5.md が仕様書です。以下を厳守してください。

1. §5のタスクを T-41 から番号順に実装する。並行着手しない。
2. Phase 4の分析ロジック（learning_curve.dart / complexity_tables.dart 等）の式・係数・分岐は変更しない。
3. 新規APIエンドポイント・新規ネットワークコールを追加しない。
   既存の registerBggId が取得済みのBGGレスポンスのみを使って拡張候補を抽出する。
4. T-41 で BGG `link type="boardgameexpansion"` の `inbound` 属性の意味（拡張候補側か親ゲーム側か）を
   フィクスチャで確認する。本書§6の想定と矛盾する場合は実装前に報告し、本書修正後に再開する。
5. parentGameKey は games.gameKey への外部キー制約を持たせない（親未登録を許容するため）。
6. 既存のYAMLエクスポート(Phase0 §6)・Phase4分析・既存テストに後退を起こさない。
7. UI文言は assets/i18n/{ja,en}.json のキー経由（ハードコード禁止）。
8. §3 定数（既存 C-01〜42 / 本書 C-43〜45）は変更禁止。曖昧なら質問する。
まず T-41 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-43 | ゲーム種別 | `gameKindBase = 'base'` / `gameKindExpansion = 'expansion'` | `games.gameKind`の値 | 要件§4.1 |
| C-44 | BGG拡張リンク種別 | `bggExpansionLinkType = 'boardgameexpansion'` | XMLパーサ判定 | 要件§4.2 |
| C-45 | DBスキーマバージョン | 5 → 6 | `AppDatabase.schemaVersion` | 要件§4.1 |

---

## 4. リポジトリ構成（追加分）

```
追加/変更ファイル（想定）:
lib/src/
  data/
    db/
      app_database.dart            … EDIT: games.gameKind/parentGameKey 追加、schemaVersion 6、migration追加、
                                      upsertBggGame/insertLocalGameにgameKind/parentGameKey引数追加（既定値あり）、
                                      findExpansions(parentGameKey) 等のクエリ追加
      app_database.g.dart          … EDIT(自動生成): build_runner再実行
    bgg/
      bgg_xml_parser.dart           … EDIT: BggGameDetailsにexpansionLinks/expandsGame追加、_links()の拡張または
                                      新規ヘルパーでinbound属性を判定
    repo/
      bgg_registration_repository.dart … EDIT: registerBggIdでgameKind/parentGameKey判定・設定、
                                      BggRegistrationCreatedにexpansionCandidates追加、
                                      DB未登録分のみ抽出するフィルタ
      collection_repository.dart    … EDIT: groupCollectionItems()追加（親子グルーピング・孤立拡張判定）
  domain/
    collection_analytics.dart       … EDIT: AnalyticsSummaryにbaseCount/expansionCountを追加、summarize()で集計
  ui/
    pages/
      collection_list_page.dart     … EDIT: _CollectionListをgroupCollectionItems()ベースの表示に変更、
                                      拡張バッジ・孤立拡張バッジを追加。_CollectionGridに拡張バッジ追加
      game_detail_page.dart         … EDIT: 「拡張情報」セクション追加（親リンク/親登録ボタン/拡張一覧）、
                                      gameKind='expansion'時に分析セクションを案内文に置換
      dashboard_page.dart           … EDIT: 基本ゲーム数／拡張数の表示追加
      search_registration_page.dart … EDIT (or NEW widget): 登録成功後にexpansionCandidatesがあれば
                                      候補シートを表示し個別登録できるようにする
assets/i18n/{ja,en}.json            … EDIT: expansion.* / collection.expansionBadge 等のキー追加
test/
  t20_bgg_xml_parser_expansion_test.dart      … NEW: inbound/non-inbound boardgameexpansionリンクの解析
  t21_bgg_registration_repository_expansion_test.dart … NEW: gameKind/parentGameKey判定、親未登録許容、
                                                  expansionCandidates抽出・DB既存分の除外
  t22_collection_repository_grouping_test.dart … NEW: groupCollectionItems（親子グルーピング・孤立拡張）
  t23_collection_analytics_counts_test.dart    … NEW: baseCount/expansionCount集計
  t24_database_migration_v6_test.dart          … NEW: schemaVersion 5→6マイグレーション（既存行の既定値）
README.md                            … EDIT: 拡張管理機能の説明追記
```
（テスト番号は既存の最終番号(t19)＋1から連番。）

---

## 5. 実装タスク（execution order・T-41〜T-45）

### T-41 DBスキーマ拡張＋BGGリンク方向性の確認
- 内容:
  1. BGG `thing` APIのフィクスチャを2種用意（①拡張を持つ基本ゲームのitem例 ②ある基本ゲームを拡張するitem例）し、`link type="boardgameexpansion"`の`inbound`属性の付き方を確認する。要件§4.2の想定（`inbound="true"`=拡張候補、属性なし/false=親ゲーム）と一致するか検証し、矛盾があれば停止して報告する。
  2. `games`テーブルに`gameKind`（TEXT, デフォルト`'base'`=C-43）・`parentGameKey`（TEXT, nullable, FK制約なし）を追加。`schemaVersion`を5→6（C-45）。`from < 6`のマイグレーションで両カラムを追加し、既存行は既定値（`'base'`/`null`）になることを確認。
  3. `AppDatabase`に`findExpansions(String parentGameKey) -> Future<List<Game>>`（`gameKind='expansion' AND parentGameKey=:parentGameKey`）を追加。
- 受け入れ基準:
  - [ ] フィクスチャ検証結果（inbound属性の意味）が要件§4.2と一致する、または不一致を報告し本書修正の上で次へ進む
  - [ ] schemaVersion6への移行で既存DBがエラーなく開き、既存行の`gameKind='base'`/`parentGameKey=null`になる
  - [ ] `findExpansions`が`parentGameKey`一致行のみを返す

### T-42 BGG XMLパーサ拡張＋registerBggId拡張
- 内容:
  - `bgg_xml_parser.dart`: `BggGameDetails`に`expansionLinks: List<NamedBggValue>`（T-41で確認した「拡張候補」方向のリンク）・`expandsGame: NamedBggValue?`（「親ゲーム」方向のリンク。複数存在する場合は最初の1件を採用し、他は無視。理由をコードコメントに記載）を追加。`parseThing`で`link type="boardgameexpansion"`（C-44）をT-41の判定規則で振り分ける。
  - `bgg_registration_repository.dart`: `registerBggId`で、`details.expandsGame`の有無により`gameKind`/`parentGameKey`（C-43）を決定し`upsertBggGame`に渡す（`upsertBggGame`/`insertLocalGame`は新規引数に既定値`gameKindBase`/`null`を設定）。新規登録（`BggRegistrationCreated`）の場合、`details.expansionLinks`から`games.gameKey`に未存在のもののみを`expansionCandidates: List<NamedBggValue>`としてフィールド追加し公開する。`BggRegistrationAlreadyExists`では`expansionCandidates`は空リスト固定（追加APIコールなし）。
- 受け入れ基準:
  - [ ] 拡張item（`expandsGame`あり）の登録で`gameKind='expansion'`/`parentGameKey=expandsGame.bggId`になる
  - [ ] 通常item（`expandsGame`なし）の登録で`gameKind='base'`/`parentGameKey=null`になる
  - [ ] `parentGameKey`が`games`に存在しないIDでも登録が成功する（例外なし）
  - [ ] `BggRegistrationCreated.expansionCandidates`が、DB未登録の`expansionLinks`のみを含み、既存登録済みIDを含まない
  - [ ] `BggRegistrationAlreadyExists`では`expansionCandidates`が常に空で、追加のBGG APIコールが発生しない

### T-43 コレクション一覧の親子表示
- 内容: `collection_repository.dart`に純粋関数`groupCollectionItems(List<CollectionListItem> items) -> List<CollectionGroup>`を追加。
  - `CollectionGroup`: `{ parent: CollectionListItem, expansions: List<CollectionListItem>, isOrphanExpansion: bool }`
  - `gameKind='base'`の項目を親候補とし、`gameKind='expansion'`かつ`parentGameKey==親のgameKey`の項目を`expansions`に格納（表示名で昇順ソート）
  - 親候補が`items`内に存在しない拡張（親未登録、または親がフィルタ等で結果に含まれない）は、`parent=その拡張自身`・`expansions=[]`・`isOrphanExpansion=true`の単独グループとする
  - グループの並び順は`parent`の`displayName`昇順（既存の`list()`のソート結果を維持）
  - `collection_list_page.dart`の`_CollectionList`を`groupCollectionItems`ベースに変更。各グループの`parent`を通常表示、`expansions`をインデント（例: `contentPadding: EdgeInsets.only(left: 32)`）＋「拡張」バッジ付きで表示。`isOrphanExpansion`の場合は「親ゲーム未登録」バッジを付与
  - `_CollectionGrid`は`gameKind='expansion'`の項目に「拡張」バッジを追加するのみ（ネストなし）
- 受け入れ基準:
  - [ ] 親と拡張が同一フィルタ結果内にある場合、拡張が親の直下にインデント表示される
  - [ ] 親未登録の拡張、または親がフィルタ結果に含まれない拡張は、単独表示＋「親ゲーム未登録」相当のバッジが付く
  - [ ] グリッド表示で拡張に「拡張」バッジが表示され、レイアウト崩れがない
  - [ ] 既存のフィルタ・検索・並び順の挙動に後退がない

### T-44 詳細画面の拡張情報セクション
- 内容: `game_detail_page.dart`に「拡張情報」セクションを追加。
  - `gameKind='expansion'`: 親ゲーム名を表示。`AppDatabase.findGame(parentGameKey)`が非nullなら「親ゲームを見る」ボタンで`GameDetailPage(gameKey: parentGameKey)`へ遷移。nullなら「親ゲーム未登録（BGG ID: {parentGameKey}）」表示＋「親ゲームを登録」ボタン。ボタン押下で`registerBggId(parentGameKey)`を呼び、成功後に詳細画面を再読み込み（`ref.invalidate`等）
  - `gameKind='base'`: `findExpansions(gameKey)`の結果件数と一覧（各行に表示名、タップで`GameDetailPage`へ遷移）。0件は「登録済みの拡張はありません」
  - Phase 4「分析」セクション: `gameKind='expansion'`では非表示にし、代わりに案内文（i18n: `analysis.expansionNotice`）＋（親登録済みなら）親ゲームへのリンクを表示。`gameKind='base'`は既存どおり
- 受け入れ基準:
  - [ ] 拡張の詳細画面で親が登録済みなら遷移リンクが、未登録なら登録ボタンが表示され、登録後に画面が更新される
  - [ ] 基本ゲームの詳細画面で登録済み拡張の件数・一覧が表示され、各行から遷移できる
  - [ ] 拡張の詳細画面でPhase4「分析」セクションが非表示になり、案内文が表示される。基本ゲームでは表示が維持される
  - [ ] 文言はi18nキー経由

### T-45 ダッシュボード集計・i18n・README・仕上げ
- 内容:
  - `collection_analytics.dart`: `AnalyticsSummary`に`baseCount`/`expansionCount`を追加し、`summarize()`で`item.game.gameKind`別に集計
  - `dashboard_page.dart`: 既存の集計表示に「基本ゲーム数／拡張数」を追加
  - `assets/i18n/{ja,en}.json`に`expansion.*`/`collection.expansionBadge`/`collection.parentUnregistered`/`analysis.expansionNotice`等のキーを追加
  - READMEに拡張管理機能（親子表示・拡張候補登録・分析対象外の扱い）を追記
- 受け入れ基準:
  - [ ] ダッシュボードに基本ゲーム数／拡張数が表示され、合計が総数と一致する
  - [ ] 追加文言がすべてi18nキー経由
  - [ ] `flutter analyze` 警告ゼロ、`flutter test` 全件パス（t20〜t24含む既存全件）

---

## 6. BGGリンク仕様の要点（参照・正本はT-41のフィクスチャ検証）

> 以下は実装時の早見。**最終判断はT-41でのフィクスチャ検証結果**。

- 対象: `<link type="boardgameexpansion" id="..." value="..." [inbound="true"]/>`
- 想定: `inbound="true"`＝「value/idのゲームは、取得対象アイテムの拡張である」（拡張候補・`expansionLinks`）
- 想定: `inbound`属性なし（またはfalse）＝「取得対象アイテムは、value/idのゲームを拡張する」（親ゲーム・`expandsGame`）
- 1アイテムに複数の`expandsGame`相当リンクが存在する場合（複数の基本ゲームを拡張する大型拡張等）は、最初の1件を`parentGameKey`として採用し、他は無視する（複数親対応はOut of Scope）
- `expansionLinks`は0件以上。`expandsGame`は0または1件
- 既存の`mechanics`/`categories`/`designers`/`publishers`と同様、`_links(item, 'boardgamemechanic')`等のヘルパーパターンを踏襲し、`inbound`属性での絞り込みのみ追加する

---

## 7. 禁止事項・制約

1. **Phase 4の分析ロジック・係数・分岐を変更しない**。拡張の識別・UI表示制御のみで対応する。
2. **新規外部API・新規ネットワークコールを追加しない**。拡張候補は新規登録時に取得済みのレスポンスのみを使う。
3. **`parentGameKey`にFK制約を付けない**。親未登録を許容する設計を維持する。
4. **既存のYAMLエクスポート構造（Phase0 §6）を変更しない**。`game_kind`/`parent_game_key`のエクスポートはOut of Scope（追加しない）。
5. **新規依存を追加しない**（drift/xml/riverpod既存のみ）。
6. UI文言ハードコード禁止（i18nキー経由）。テストは時計・乱数・ネットワークに依存させない（既存フィクスチャ/モック方針を踏襲）。
7. グリッド表示のネスト化・拡張専用フィルタ・プレイ記録・ローカルレコードの親子設定は実装しない（Out of Scope）。

---

## 8. 完了の定義（Phase 5 Done）

- T-41〜T-45の全受け入れ基準がテストで担保され、`flutter test`が全件成功する
- `flutter analyze`警告ゼロ
- schemaVersion6への移行が既存DBに対してエラーなく動作する
- BGG拡張リンクから`gameKind`/`parentGameKey`が正しく設定され、親未登録でも登録・後からの親登録が機能する
- コレクション一覧で拡張が親の直下にインデント表示され、孤立拡張は単独表示される
- 詳細画面で拡張⇄親のナビゲーションが機能し、拡張ではPhase4分析セクションが案内文に置換される
- ダッシュボードに基本ゲーム数／拡張数が表示される
- 既存のYAMLエクスポート・Phase4分析・既存テスト（t01〜t19）に後退が発生しない
