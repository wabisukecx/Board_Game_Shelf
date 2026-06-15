# 要件定義書: Board Game Shelf Phase 6-C（遊ぶゲームを探す・絞り込み拡充）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 位置づけ | Phase 6-A/6-B（プレイ記録DB・UI）の上に、「今日遊ぶゲームを選ぶ」ための絞り込み・並び替えを既存のコレクション一覧（S-01）に拡充する |
| 前提 | リポジトリ確認の結果、Phase 6-B実装済み（`play_session_form_page.dart`、`game_detail_page.dart`の「プレイ記録」セクション、`AppConstants.playPerceivedWeightStep`（C-50）、`test/t28`を確認済み）。本フェーズはこの上に積む。`flutter analyze`/`flutter test`は着手前に実行・確認すること |
| 後続 | Phase 6-D（プレイ傾向分析） |

---

## 1. 目的・背景

これまでに、人数・時間での絞り込みとデザイナー順ソートは既存のコレクション一覧（`collection_list_page.dart`/`CollectionRepository`）に実装済みである。Phase 6-Aでプレイ記録のデータも揃ったため、本フェーズでは「メカニクス」「デザイナー（絞り込み）」「拡張ありゲーム」「未プレイ／最近遊んでいない」を既存の一覧に追加し、所持ゲームの中から今日遊ぶものを選びやすくする。

### 1.1 設計の前提

- **新規の「探す」専用画面は作らない**。既存のコレクション一覧（S-01）のフィルタ・ソートを拡充する形で実現する。既存の絞り込み（人数・時間・ローカルのみ）、ソート（五十音順・デザイナー順）、親子表示（拡張のネスト）はそのまま活かす。専用の「おすすめ」画面が必要になった場合は、本フェーズの絞り込みを踏まえて別途Phase 6-C′として検討する。
- **メカニクス・デザイナーの絞り込みは「自分のコレクションに存在する値」から選ぶ**。BGG全体の語彙ではなく、所持ゲームの`mechanics`/`designers`の和集合を選択肢とすることで、選択肢数を実用的な範囲に抑える。選択はいずれも複数選択・OR一致（選んだいずれかに該当すれば表示）とする。選択肢が多くなる前提で、検索ボックス付きの複数選択ダイアログとする。
- **「拡張あり」絞り込みは、コレクション内に登録済みの拡張を持つ基本ゲームのみを表示するトグル**とする。「拡張込み/基本のみ/拡張ありゲーム」という3区分の細かい切り分けは行わず、まず「拡張ありゲームのみ表示」の1トグルに絞る（基本ゲームの表示自体は既存の親子表示で常に行われており、追加の「基本のみ」表示モードは必要性が薄いため）。
- **「未プレイ」絞り込みと「最近遊んでいない」は別の仕組みで対応する**。「未プレイ」はプレイ記録が0件のゲームを表示するトグルとする。「最近遊んでいない」は固定のしきい値（日数）によるフィルタにはせず、既存のソート機能に「最終プレイ日が古い順」を追加することで対応する（未プレイのゲームは「記録なし」として最も古い扱いで先頭に表示される）。
- **絞り込み・並び替えは個々のゲーム（`CollectionListItem`）の値に対して適用する**（既存の人数・時間フィルタと同じ方式）。拡張のメカニクス/デザイナーが基本ゲーム側のフィルタ結果に影響することは本フェーズでは行わない（基本ゲームと拡張は別々に評価される）。
- **新規依存は追加しない**。

---

## 2. スコープ

### 2.1 含むもの（In Scope）

- FR-6C-01 `CollectionListItem`に`playCount`（プレイ記録件数）・`lastPlayedDate`（最終プレイ日、`YYYY-MM-DD`または`null`）を追加する。対象は`gameKind != 'expansion'`のゲームのみ（拡張は常に`playCount=0`/`lastPlayedDate=null`）
- FR-6C-02 `CollectionRepository`に`facets()`を追加し、所持ゲーム全体の`mechanics`/`designers`の和集合（重複排除・ソート済み）を返す
- FR-6C-03 `CollectionFilter`に以下を追加し、`CollectionRepository.list()`の絞り込みに反映する
  - `mechanics: List<String>`（OR一致）
  - `designers: List<String>`（OR一致）
  - `hasExpansionsOnly: bool`（コレクション内に登録済み拡張を持つ基本ゲームのみ）
  - `unplayedOnly: bool`（`playCount == 0`のみ）
- FR-6C-04 `CollectionSortOrder`に`lastPlayed`を追加し、最終プレイ日が古い順（未プレイは最古として先頭）に並べる
- FR-6C-05 コレクション一覧画面のフィルタバーに、メカニクス・デザイナーの検索付き複数選択ダイアログ、および「拡張あり」「未プレイ」のトグルチップを追加する
- FR-6C-06 ソート選択に「最終プレイ日が古い順」を追加する
- FR-6C-07 `sortOrder==lastPlayed`または`filter.unplayedOnly`のとき、一覧の各アイテムに最終プレイ日（または「未プレイ」）を表示する
- FR-6C-08 新規UI文言の`assets/i18n/{ja,en}.json`への追加

### 2.2 含まないもの（Out of Scope）

- 新規の「探す」専用画面・おすすめ表示
- 「最近遊んでいない」のための日数しきい値フィルタ（ソートで代替）
- 「拡張込み/基本のみ/拡張ありゲーム」の3区分絞り込み（「拡張あり」トグルのみ）
- メカニクス/デザイナーのAND一致モード
- 拡張のメカニクス/デザイナーを基本ゲームのフィルタ結果に合算する処理
- プレイ傾向分析（デザイナー別/メカニクス別の集計等）→ Phase 6-D

---

## 3. 対象・非機能要件

| 項目 | 方針 |
|---|---|
| 依存 | 追加なし（既存の`flutter_riverpod`・`drift`・標準Widgetのみ） |
| パフォーマンス | `playCount`/`lastPlayedDate`は既存の`findCollection`と同様、ゲームごとに`PlaySessionRepository.listForGame`を呼び出す方式でよい（個人コレクション規模を想定し、新規の集計クエリ最適化は行わない） |
| i18n | 新規UI文言はすべて`assets/i18n/{ja,en}.json`のキー経由 |
| 既存への影響 | 既存の絞り込み（人数・時間・ローカルのみ）・ソート（五十音順・デザイナー順）・親子表示（グルーピング）・`analyticsProvider`の挙動を変更しない（`CollectionListItem`へのフィールド追加のみ） |

---

## 4. データモデル／Repository仕様

### 4.1 `CollectionListItem`拡張

| フィールド | 型 | 説明 |
|---|---|---|
| `playCount` | `int` | `gameKind != 'expansion'`のとき`PlaySessionRepository.listForGame(gameKey)`の件数。拡張は常に`0` |
| `lastPlayedDate` | `String?` | 上記記録のうち最も新しい`playedDate`（`listForGame`は降順なので先頭要素）。記録なしまたは拡張は`null` |

### 4.2 `CollectionRepository.facets()`

- `Future<CollectionFacets> facets()`を新規追加
- `CollectionFacets { mechanics: List<String>, designers: List<String> }`
- 所持ゲーム全件（`gameKind`問わず）の`game.mechanics`/`game.designers`の和集合を、重複排除のうえ昇順ソートして返す

### 4.3 `CollectionFilter`拡張

| フィールド | 型 | 既定値 | 説明 |
|---|---|---|---|
| `mechanics` | `List<String>` | `const []` | 空でなければ、`item.game.mechanics`がこのリストのいずれかを含む場合のみ表示（OR一致） |
| `designers` | `List<String>` | `const []` | 空でなければ、`item.game.designers`がこのリストのいずれかを含む場合のみ表示（OR一致） |
| `hasExpansionsOnly` | `bool` | `false` | `true`のとき、コレクション内に`parentGameKey==item.game.gameKey`の拡張（`gameKind=='expansion'`）を持つアイテムのみ表示 |
| `unplayedOnly` | `bool` | `false` | `true`のとき、`playCount == 0`のアイテムのみ表示 |

`hasExpansionsOnly`の判定に必要な「コレクション内の拡張→親」関係は、`list()`内で絞り込み前の全アイテムから算出する（既存の`groupCollectionItems`が行っている親子判定と同じ情報源）。

### 4.4 `CollectionSortOrder`拡張

- `enum CollectionSortOrder { name, designer, lastPlayed }`
- `lastPlayed`: `lastPlayedDate`の昇順（`null`は最も古いものとして先頭）。同値は`displayName`の五十音順
- 既存の`name`/`designer`の挙動は変更しない

---

## 5. UI仕様

### 5.1 フィルタバー（`_FilterBar`）への追加

- 「メカニクス」チップ: タップで検索付き複数選択ダイアログを開く。選択肢は`facets().mechanics`。選択件数が1件以上のとき、チップに件数を表示する（例: 「メカニクス (2)」）
- 「デザイナー」チップ: 同様に`facets().designers`を選択肢とする検索付き複数選択ダイアログ（既存の「デザイナー順」ソートとは独立した、絞り込み用の新規チップ）
- 「拡張あり」`FilterChip`: トグルで`filter.hasExpansionsOnly`を切り替える
- 「未プレイ」`FilterChip`: トグルで`filter.unplayedOnly`を切り替える

### 5.2 検索付き複数選択ダイアログ

- メカニクス・デザイナーで共通の汎用ダイアログとする
- 上部に検索テキストフィールド（入力で選択肢を部分一致フィルタ）
- 各選択肢は`CheckboxListTile`で複数選択
- 「クリア」（全選択解除）・「適用」（選択を確定して閉じる）ボタンを持つ

### 5.3 ソート選択への追加

- 既存のソートチップ（五十音順／デザイナー順）に「最終プレイ日が古い順」を追加する

### 5.4 一覧アイテムへの最終プレイ日表示

- `sortOrder==CollectionSortOrder.lastPlayed`または`filter.unplayedOnly==true`のとき、各アイテムのsubtitleに以下を追加表示する
  - `playCount > 0`: 「最終プレイ: {lastPlayedDate}」
  - `playCount == 0`: 「未プレイ」
- それ以外のソート/フィルタ状態では表示しない（既存表示を変更しない）

---

## 6. i18nキー一覧（新規追加）

`collection`名前空間に追記:

- `collection.filterMechanics`（「メカニクス」）
- `collection.filterDesigners`（「デザイナー」※絞り込み用。既存の`sortByDesigner`とは別キー）
- `collection.filterHasExpansions`（「拡張あり」）
- `collection.filterUnplayed`（「未プレイ」）
- `collection.sortByLastPlayed`（「最終プレイ日が古い順」）
- `collection.filterDialogSearchHint`（「検索」）
- `collection.filterDialogClear`（「クリア」）
- `collection.filterDialogApply`（「適用」）
- `collection.lastPlayedLabel`（「最終プレイ: {date}」）
- `collection.neverPlayedLabel`（「未プレイ」）

ja/en両方に追加すること。

---

## 7. 受け入れ基準（概要）

- `CollectionListItem.playCount`/`lastPlayedDate`が、`gameKind != 'expansion'`のゲームについて`PlaySessionRepository`の記録に基づき正しく算出される。拡張は常に`playCount=0`/`lastPlayedDate=null`
- `CollectionRepository.facets()`が、所持ゲーム全体の`mechanics`/`designers`の和集合を重複排除・ソート済みで返す
- メカニクスまたはデザイナーを1件以上選択すると、該当する値を持つゲームのみが一覧に表示される（OR一致）。複数選択時はいずれかに一致すれば表示される
- 「拡張あり」を有効にすると、コレクション内に登録済み拡張を持つ基本ゲームのみが表示される
- 「未プレイ」を有効にすると、プレイ記録が0件のゲームのみが表示される
- ソートに「最終プレイ日が古い順」を選択すると、未プレイ・最終プレイ日が古いゲームから順に表示される
- 「最終プレイ日が古い順」または「未プレイ」絞り込み時、各アイテムに最終プレイ日または「未プレイ」が表示される。それ以外では表示されない
- 既存の絞り込み（人数・時間・ローカルのみ）・ソート（五十音順・デザイナー順）・親子表示・ダッシュボード集計（`analyticsProvider`）の挙動に後退が発生しない
- 新規UI文言がja/en両方のi18nファイルに存在する
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス

詳細なタスク分割・実装制約は `docs/DEVELOPMENT_BRIEF_Phase6-C.md` を参照。
