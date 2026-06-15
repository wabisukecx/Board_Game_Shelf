# 要件定義書: Board Game Shelf Phase 5（拡張（Expansion）管理）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 位置づけ | Phase 0〜4（F-01〜F-05＋分析ダッシュボード＋BGG一括取り込み＋多次元分析指標）完了後の新規フェーズ。所持・プレイ管理としての「拡張（expansion）」をデータモデルおよびUIに追加する |
| 前提 | リポジトリ確認の結果、Phase 4 の実装物（`complexity_tables.dart`／`learning_curve.dart`／`assets/analysis/*`／`test/t18_*`・`t19_*`等）が存在することを確認済み。`flutter analyze`／`flutter test` の実行結果は本書作成時点では未確認のため、着手前に実行・確認すること |
| 後続 | 未定（プレイ記録、拡張のみフィルタ、基本＋拡張の合成評価 等は別途検討） |

---

## 1. 目的・背景

ユーザーは基本ゲームだけでなく、その拡張（expansion）も購入・所持する。現状のデータモデルは「1ゲーム=1レコード」であり、拡張は基本ゲームと同列の独立レコードとして扱われ、どの基本ゲームの拡張かという関係も、一覧上の親子関係も表現できない。

一方、評価（Phase 4の多次元指標）に拡張を織り込もうとすると、発売年差・複数拡張の組み合わせ・拡張ごとのメカニクス/カテゴリ/重さの違い・BGGのweightの前提の曖昧さ等、未解決の難問が一気に増える。これは「1ゲーム=1データ」前提の指標算出と根本的に噛み合わない。

そこで Phase 5 は、**評価ロジックには触れず**、「所持・プレイ管理としての拡張」のみをスコープとする。具体的には、拡張をBGGからリンク経由で発見・登録できるようにし、`games`テーブルに `gameKind`（base/expansion）と `parentGameKey`（親=基本ゲームのBGG ID）を追加し、一覧で基本ゲームの下に拡張をぶら下げて表示する。

### 1.1 設計の前提

- **評価ロジックは変更しない**。Phase 4 の10指標・分類は引き続き基本ゲーム単体に対してのみ算出する。本フェーズでは拡張に対してこれらの指標を算出・表示しない（Out of Scope。将来フェーズで「参考表示」「合成評価」を検討する）。
- **BGGのデータ構造を利用する**。拡張はBGG上で独自の thing（独自のobject id）を持ち、基本ゲームとの関係は `link type="boardgameexpansion"` で表現される。拡張側item では（`inbound`属性なし/false の）当該リンクが「このアイテムが拡張する対象（親）」を表し、基本ゲーム側item では（`inbound="true"`の）当該リンクが「このゲームの拡張一覧（候補）」を表す、という前提で設計する。**この方向性の正本はBGG実データであり、開発文書 §6 のフィクスチャ検証で確認・矛盾時は本書を修正する**。
- **拡張も既存の `registerBggId` で1レコードとして登録する**。新規の登録経路・APIエンドポイントは追加しない。拡張アイテムのレスポンスに含まれる `boardgameexpansion` リンクから `gameKind`/`parentGameKey` を自動判定する。
- **親未登録を許容する**。拡張だけ先に登録された場合、`parentGameKey` にはBGGの親IDを保持するが、`games`テーブルに該当行が無くてもエラーにしない。詳細画面から「親ゲームを登録」操作（`registerBggId(parentGameKey)` を直接呼ぶのみ。検索不要）で解消できる。
- **所持管理は既存の `collection` テーブルをそのまま再利用**する。拡張も `gameKey`（=BGG ID）単位で `owned`/`acquired_date`/`condition`/`storage_location`/`memo`/`purchase_price` を独立管理できる（既存の`registerBggId`経路で自動的に1行作成される）。
- **新規依存は原則なし**。既存の `drift`/`xml`/`riverpod` のみで実装する。

---

## 2. スコープ

### 2.1 含むもの（In Scope）

- FR-5-01 `games`テーブルへの `gameKind`（'base'｜'expansion'、既定'base'）・`parentGameKey`（BGG ID文字列、nullable、FK制約なし）追加（schemaVersion 5→6・マイグレーション）
- FR-5-02 BGG XMLパーサに `boardgameexpansion` リンクの解析を追加（`expansionLinks`＝inbound＝拡張候補一覧、`expandsGame`＝non-inbound＝親ゲーム情報）
- FR-5-03 `registerBggId` 拡張: 登録対象アイテムが拡張（`expandsGame`あり）なら `gameKind='expansion'`／`parentGameKey=<親のBGG ID>` を設定。それ以外は `gameKind='base'`／`parentGameKey=null`
- FR-5-04 新規登録直後（`BggRegistrationCreated`）に、未登録の拡張候補（`expansionLinks`からDB未登録分）を一覧提示し、選択して個別登録できるUI
- FR-5-05 コレクション一覧（リスト表示）で、拡張を親（基本ゲーム）の直下にインデント表示。親が一覧に存在しない拡張は「親ゲーム未登録」バッジ付きで単独表示
- FR-5-06 詳細画面に「拡張情報」セクションを追加。
  - `gameKind='expansion'`: 親ゲーム名（親が登録済みなら詳細画面へのリンク、未登録なら「親ゲームを登録」ボタン）を表示
  - `gameKind='base'`: 登録済みの拡張一覧（件数・各拡張への詳細画面リンク）を表示
- FR-5-07 ダッシュボードに「基本ゲーム数／拡張数」の件数表示を追加
- FR-5-08 拡張に対してはPhase 4の分析セクションを非表示にし、案内文（「分析指標は基本ゲームに対してのみ算出されます」＋親ゲームへのリンク）を表示

### 2.2 含まないもの（Out of Scope）

- プレイ記録機能（owned以外の利用記録）全般
- 拡張自身へのPhase 4多次元指標の算出・表示、「基本＋拡張」の合成評価プロファイル
- 拡張のみ表示/非表示の専用フィルタ（一覧の既存フィルタは変更しない）
- グリッド表示での親子ネスト表現（インデント表示はリスト表示のみ。グリッドは拡張バッジのみ追加）
- 拡張候補の一括自動登録（個別選択登録のみ）
- ローカル独自レコード（L-ID）に対する手動の親子関係設定UI
- 新規外部API・新規ネットワークエンドポイントの追加（既存BGG `thing`/`search` のみ）
- 対象プラットフォームの拡大（Androidのみ）

---

## 3. 対象・非機能要件

| 項目 | 方針 |
|---|---|
| 対象OS | Android（既存踏襲）。本機能はオフラインDB操作が中心のため全プラットフォームで動作可能 |
| 依存 | 追加なし（drift / xml / riverpod 既存のみ） |
| データ | `games.gameKind`/`games.parentGameKey` を追加。既存行は移行時に `gameKind='base'`/`parentGameKey=null` |
| 後方互換 | 既存のYAMLエクスポート（Phase 0 §6）・分析（Phase 4）には影響しない。エクスポートに `game_kind`/`parent_game_key` を含めるかは本フェーズでは追加しない（Out of Scope。analyzer互換YAMLの構造変更は別途検討） |
| i18n | 新規UI文言はすべて `assets/i18n/{ja,en}.json` のキー経由 |
| 安全性 | 拡張候補提示は新規登録時に取得済みのBGGレスポンスを再利用し、追加APIコールを発生させない |

---

## 4. データモデル仕様（概要）

### 4.1 `games`テーブル拡張

| カラム | 型 | 既定値 | 説明 |
|---|---|---|---|
| `gameKind` | TEXT | `'base'` | `'base'`（基本ゲーム）｜`'expansion'`（拡張） |
| `parentGameKey` | TEXT, nullable | `null` | `gameKind='expansion'`のとき、親（基本ゲーム）のBGG ID文字列。`games.gameKey`へのFK制約は設けない（親未登録を許容） |

マイグレーション（schemaVersion 5→6）: `from < 6` のとき `addColumn(games, games.gameKind)` ／ `addColumn(games, games.parentGameKey)`。既存行は `gameKind='base'`・`parentGameKey=null` となる。

### 4.2 BGG `boardgameexpansion` リンクの解析

| 方向 | XML属性の想定 | 意味 | 用途 |
|---|---|---|---|
| 拡張候補 | `link type="boardgameexpansion" inbound="true"` | このゲーム（取得対象アイテム）の拡張 | `expansionLinks`としてFR-5-04の候補提示に使用 |
| 親ゲーム | `link type="boardgameexpansion"`（`inbound`属性なし/false） | このアイテムが拡張する対象（親） | `expandsGame`としてFR-5-03の`gameKind`/`parentGameKey`判定に使用 |

> 方向性の正本はBGG実データ。開発文書 §6 のフィクスチャで確認し、矛盾があれば本書を修正してから実装する。

### 4.3 `gameKind`/`parentGameKey` の決定規則（`registerBggId`）

1. BGGアイテム取得後、`expandsGame`が存在する → `gameKind='expansion'`、`parentGameKey=expandsGame.bggId`
2. `expandsGame`が存在しない → `gameKind='base'`、`parentGameKey=null`
3. ローカル独自レコード（`insertLocalGame`）は常に `gameKind='base'`／`parentGameKey=null`（既定値のまま。Out of Scope）
4. `parentGameKey`が指す`gameKey`が`games`テーブルに存在しない場合も登録は成功する（親未登録）。詳細画面でその旨を表示し、`registerBggId(parentGameKey)`で解消できる

### 4.4 拡張候補の抽出（`expansionLinks`）

- `BggRegistrationCreated`（新規登録時のみ）で、取得済みレスポンスの`expansionLinks`のうち、`games.gameKey`に未存在の`bggId`を持つものを`expansionCandidates: List<NamedBggValue>`として公開する
- 既存登録済みのIDは候補から除外する（重複登録防止）
- `BggRegistrationAlreadyExists`（既存ヒット時）では候補抽出を行わない（追加APIコールが発生しないため）

---

## 5. 画面要件

### 5.1 拡張候補提示（新規登録直後）

- FR-5-04。`BggRegistrationCreated`で`expansionCandidates`が空でない場合、登録完了後に簡易シート/ダイアログで候補（名称＋BGG ID）を一覧表示
- 各候補に「登録」ボタン。タップで`registerBggId(candidate.bggId)`を呼び、成功したら一覧から除去（またはチェック表示に変更）
- 「閉じる」操作でいつでも終了できる。未登録のまま閉じても後から手動でBGG ID検索すれば登録可能（候補提示はあくまで便宜機能）

### 5.2 コレクション一覧（S-01拡張）

- リスト表示: `gameKind='base'`の行の直下に、`parentGameKey==当該行のgameKey`である`gameKind='expansion'`の行をインデント表示（小さめのリストタイル＋「拡張」バッジ）
- 親が一覧に存在しない拡張（親が未所持・未登録 等でフィルタ結果に含まれない場合を含む）は、インデントせず単独表示し「親ゲーム未登録」または「親ゲームは表示対象外」を示すバッジを付与
- グリッド表示: ネスト表現は行わない。`gameKind='expansion'`の項目に「拡張」バッジのみ追加（既存レイアウト維持）
- 既存の検索・フィルタ（タイトル部分一致／人数／時間／ローカルのみ）は変更しない。フィルタ後の結果に対してグルーピングを適用する

### 5.3 詳細画面（S-04拡張）

- 「拡張情報」セクションを新設（Phase 4の「分析」セクションとは別セクション）
  - `gameKind='expansion'`の場合: 「この基本ゲームの拡張です」＋親ゲーム名（`parentGameKey`に該当する`games`行があれば表示名、なければ「親ゲーム未登録（BGG ID: …）」）。親が登録済みなら詳細画面への遷移ボタン、未登録なら「親ゲームを登録」ボタン（`registerBggId(parentGameKey)`を実行し、成功後に画面を再読み込み）
  - `gameKind='base'`の場合: 「登録済みの拡張」一覧（`parentGameKey==自分のgameKey`の`games`行）。0件なら「登録済みの拡張はありません」。各行から詳細画面へ遷移可能
- 「分析」セクション（Phase 4）: `gameKind='expansion'`では非表示にし、代わりに「分析指標は基本ゲームに対してのみ算出されます」の案内文＋親ゲームへのリンク（登録済みの場合）を表示。`gameKind='base'`では既存どおり表示

### 5.4 ダッシュボード（Phase 2/4拡張）

- 既存の「ローカル件数／BGG件数」等と同居する形で、「基本ゲーム数／拡張数」を追加表示（`gameKind`別の集計）

---

## 6. 受け入れ基準（概要）

- `games`テーブルに`gameKind`/`parentGameKey`が追加され、既存行は`gameKind='base'`/`parentGameKey=null`に移行される（schemaVersion 6マイグレーションがエラーなく動作）
- BGG `boardgameexpansion`リンクの解析により、拡張アイテムでは`gameKind='expansion'`/`parentGameKey=<親BGG ID>`が、それ以外では`gameKind='base'`/`parentGameKey=null`が設定される
- 新規ベースゲーム登録直後、未登録の拡張候補が一覧提示され、個別登録できる。既存登録済みIDは候補に出ない
- 親未登録の拡張が登録でき、詳細画面から「親ゲームを登録」操作で親が登録され、以後リンク表示に切り替わる
- コレクション一覧（リスト表示）で拡張が親の直下にインデント表示され、孤立拡張は単独表示＋バッジ付きになる
- 詳細画面で、拡張は親への/からのナビゲーションができ、Phase 4分析セクションが非表示（案内文に置換）になる。基本ゲームは登録済み拡張一覧が表示される
- ダッシュボードに基本ゲーム数／拡張数が表示される
- 既存のYAMLエクスポート・Phase 4分析結果・既存テストに後退（regression）が発生しない
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス（新規ユニットテストを含む）

詳細なタスク分割・定数・実装制約は `docs/DEVELOPMENT_BRIEF_Phase5.md` を参照。
