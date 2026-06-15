# 要件定義書: BG Shelf Scanner Phase 6-D（プレイ傾向分析）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 位置づけ | Phase 6-A〜6-Cで蓄積したプレイ記録（`play_sessions`/`play_session_expansions`）と、Phase 0〜5のBGGメタデータ（メカニクス・デザイナー・拡張親子構造）・Phase 6-Cの`playCount`/`lastPlayedDate`を組み合わせ、「プレイ傾向」を可視化する新規ページを追加する |
| 前提 | リポジトリ確認の結果、Phase 6-C実装済み（`CollectionRepository.facets()`、`CollectionListItem.playCount`/`lastPlayedDate`、`CollectionFilter`の新規絞り込み、`CollectionSortOrder.lastPlayed`を確認済み）。本フェーズはこの上に積む。`flutter analyze`/`flutter test`は着手前に実行・確認すること |
| 後続 | 未定（人数×ゲーム別満足度マトリクス、プレイ時間の経年変化、勝率分析等は本書のOut of Scopeを踏まえ別途検討） |

---

## 1. 目的・背景

最初のロードマップで挙げた「4. 感想・傾向分析」のうち、本フェーズでは特に価値が高く現在のデータで算出可能な項目を実装する。対象は、よく遊ぶメカニクス、評価が高いデザイナー/メカニクス、実プレイ時間の統計（公称時間との差を含む）、拡張の使用回数、人数別の評価傾向、最近遊んでいないお気に入りの7指標である。

### 1.1 設計の前提

- **既存の「コレクション」ダッシュボード（`dashboard_page.dart`）とは別ページとする**。既存ダッシュボードは「所持ゲームの構成」（重さ・時間・人数カバー・分析指標の分布等）を扱っており、本フェーズの「プレイ傾向」は「実際に遊んだ記録」という別の軸のデータである。既存ページに混在させるとセクション数が過大になるため、新規ページ`PlayAnalyticsPage`を追加し、コレクション一覧から遷移できるアイコンを設ける。
- **既存のバーチャート表示ウィジェット（`_Section`/`_BarRow`等）を共有化する**。`CountEntry`（ラベル＋件数）を横棒グラフで表示する既存の仕組みは本フェーズでもそのまま使えるため、`dashboard_page.dart`内のprivateウィジェットを共有ファイルに抽出し、両ページから利用する。抽出は構造変更のみとし、既存ダッシュボードの表示・挙動は変更しない。
- **「評価」を軸にした集計は`play_sessions.rating`（1〜10、Phase 6-A）を使う**。`rating`が未入力のセッションは平均計算から除外し、件数を併記することで信頼度をユーザー自身が判断できるようにする。最小件数のしきい値は設けない（個人利用のデータ量では1件でも参考情報として有用なため）。
- **「人数別に満足度が高いゲーム」は、まず「人数別の平均評価」という単純な集計に絞る**。「プレイ人数×ゲーム」のマトリクスで個々のゲームをランキングする機能は、現在のデータ量では1セルあたりのサンプル数が極端に少なく統計的意味が薄いため、本フェーズでは扱わない（Out of Scope）。まず「全体として何人プレイのときに評価が高くなりやすいか」という傾向を見られるようにする。
- **「最近遊んでいないお気に入り」は、平均評価がしきい値（1〜10スケールで7以上）以上のゲームを「お気に入り」とみなし、その中で`lastPlayedDate`が古い順に並べる**。しきい値は新規定数として定義する。
- **`PlaySessionRepository`に全ゲーム横断の一覧取得メソッドを追加する**（`listForGame`はゲーム単位のため）。個人コレクションの規模を想定し、ページネーションや集計用SQLの最適化は行わない。
- **新規依存は追加しない**。

---

## 2. スコープ

### 2.1 含むもの（In Scope）

- FR-6D-01 `PlaySessionRepository.listAll()`を追加し、全ゲームの`play_sessions`を`playedDate`降順（`expansionGameKeys`含む）で返す
- FR-6D-02 新規ドメイン`PlayAnalytics`/`PlayAnalyticsSummary`を追加し、以下を算出する
  - `totalSessions`: プレイ記録の総数
  - `actualPlayingTime`: 実プレイ時間の平均（`NumericSummary`）
  - `actualPlayingTimeDistribution`: 実プレイ時間の分布（既存`playingTimeDistribution`と同じバケット）
  - `actualVsNominalPlayingTime`: 実プレイ時間と`games.playingTime`（公称時間）の差の平均（符号付き、`NumericSummary`）
  - `mechanicsPlayCounts`: メカニクス別プレイ記録数（上位N件）
  - `designerPlayCounts`: デザイナー別プレイ記録数（上位N件）
  - `mechanicRatings`: メカニクス別の平均評価（上位N件、件数併記）
  - `designerRatings`: デザイナー別の平均評価（上位N件、件数併記）
  - `expansionUsage`: 拡張の使用回数（上位N件）
  - `ratingByPlayerCount`: プレイ人数別の平均評価（データのある人数のみ、人数昇順）
  - `forgottenFavorites`: 平均評価が閾値以上で`lastPlayedDate`が古い順の上位N件（ゲーム詳細への遷移可）
- FR-6D-03 `_Section`/`_BarRow`等の既存バーチャートウィジェットを共有ファイルに抽出し、`dashboard_page.dart`と新規ページの両方から利用する（表示・挙動は変更しない）
- FR-6D-04 新規ページ`PlayAnalyticsPage`を追加し、上記指標をセクション表示する
- FR-6D-05 コレクション一覧画面に`PlayAnalyticsPage`への遷移アイコンを追加する
- FR-6D-06 新規定数: 「お気に入り」とみなす平均評価のしきい値
- FR-6D-07 新規UI文言の`assets/i18n/{ja,en}.json`への追加

### 2.2 含まないもの（Out of Scope）

- 「プレイ人数×ゲーム」の満足度マトリクス（人数別のゲームランキング）
- プレイ時間・評価の経年変化（月別/年別トレンド）
- 勝率・勝者の集計（`winnerMemo`は自由記述のため対象外）
- メカニクス/デザイナーの評価集計に対する最小サンプル数のフィルタ
- 既存ダッシュボード（`dashboard_page.dart`）のセクション構成・指標の変更（共有ウィジェット抽出に伴う表示差異が出てはならない）
- 新規の「探す」画面・絞り込み（Phase 6-Cで対応済み）

---

## 3. 対象・非機能要件

| 項目 | 方針 |
|---|---|
| 依存 | 追加なし（既存の`flutter_riverpod`・`drift`・標準Widgetのみ） |
| パフォーマンス | `listAll()`はページネーションなしで全件取得する。個人コレクション規模（数百件程度のプレイ記録）を想定し、追加の集計用クエリ最適化は行わない |
| i18n | 新規UI文言はすべて`assets/i18n/{ja,en}.json`のキー経由。既存キー（`dashboard.noData`/`dashboard.qualityCount`/`collection.minutesUnit`/`collection.playersUnit`/`collection.lastPlayedLabel`等）は流用可能な場合は再利用する |
| 既存への影響 | `dashboard_page.dart`の表示・挙動（既存セクションの内容・順序）を変更しない。ウィジェット抽出はファイル分割のみ |

---

## 4. データモデル／ドメイン仕様

### 4.1 `PlaySessionRepository.listAll()`

- `Future<List<PlaySessionRecord>> listAll()`
- `play_sessions`全件を`playedDate`降順・同値は`id`降順で取得し、`listForGame`と同様に各記録の`expansionGameKeys`を`play_session_expansions`から解決する

### 4.2 `PlayAnalytics.summarize(items, sessions)`

- 入力: `List<CollectionListItem> items`（`CollectionRepository.list()`の結果、所持・未所持を問わない全件）、`List<PlaySessionRecord> sessions`（`listAll()`の結果）
- `items`から`gameKey -> CollectionListItem`のマップを作り、各セッションの`gameKey`から該当ゲームの`mechanics`/`designers`/`playingTime`/`displayName`/`lastPlayedDate`を参照する
- 出力: `PlayAnalyticsSummary`（4.3参照）

### 4.3 `PlayAnalyticsSummary`の主要フィールド

| フィールド | 型 | 算出方法 |
|---|---|---|
| `totalSessions` | `int` | `sessions.length` |
| `actualPlayingTime` | `NumericSummary` | `actualPlayingTime`が非nullのセッションの平均 |
| `actualPlayingTimeDistribution` | `DistributionSummary` | `actualPlayingTime`を既存の`analyticsPlayingTimeBucketEdges`でバケット化 |
| `actualVsNominalPlayingTime` | `NumericSummary` | `actualPlayingTime`と対象ゲームの`game.playingTime`が両方非nullのセッションについて、`actual - nominal`の平均（符号付き、正値=公称より長くかかる傾向） |
| `mechanicsPlayCounts` | `List<CountEntry>` | 各セッションが属するゲームの`mechanics`それぞれに+1して集計し、上位`analyticsTopN`件 |
| `designerPlayCounts` | `List<CountEntry>` | 同様に`designers`で集計 |
| `mechanicRatings` | `List<RatedEntry>` | `rating`が非nullのセッションについて、ゲームの`mechanics`ごとに評価値を集め平均。上位`analyticsTopN`件（平均降順、同値は件数降順） |
| `designerRatings` | `List<RatedEntry>` | 同様に`designers`で集計 |
| `expansionUsage` | `List<CountEntry>` | 各セッションの`expansionGameKeys`をカウントし、表示名（`items`から解決）で上位`analyticsTopN`件 |
| `ratingByPlayerCount` | `List<RatedEntry>` | `playerCount`と`rating`が両方非nullのセッションを`playerCount`ごとに平均。データのある人数のみ、人数昇順 |
| `forgottenFavorites` | `List<FavoriteEntry>` | ゲームごとの平均`rating`（4.4の新規定数以上）を算出し、`lastPlayedDate`昇順（古い順）で上位`analyticsTopN`件。`gameKey`/`displayName`/`averageRating`/`lastPlayedDate`を保持し、詳細画面への遷移に使う |

`RatedEntry { label: String, average: double, count: int }`、`FavoriteEntry { gameKey: String, label: String, averageRating: double, lastPlayedDate: String }`を新規定義する。

### 4.4 新規定数

| 定数 | 値 | 用途 |
|---|---|---|
| `playFavoriteRatingThreshold` | `7`（1〜10スケール） | `forgottenFavorites`で「お気に入り」とみなす平均評価のしきい値 |

---

## 5. UI仕様

### 5.1 新規ページ `PlayAnalyticsPage`

- `play_analytics.title`をタイトルとするページ。`totalSessions == 0`のときは`play_analytics.empty`のみ表示する
- セクション構成（上から順）:
  1. 概要: `totalSessions`、`actualPlayingTime`（平均）、`actualVsNominalPlayingTime`（平均差分、符号付き）
  2. `actualPlayingTimeDistribution`（既存`_DistributionSection`相当の表示）
  3. `mechanicsPlayCounts`（既存`_RankingSection`相当の表示）
  4. `designerPlayCounts`
  5. `mechanicRatings`（新規: 平均評価＋件数を表示するセクション）
  6. `designerRatings`
  7. `expansionUsage`
  8. `ratingByPlayerCount`（新規: 人数別の平均評価セクション）
  9. `forgottenFavorites`（新規: タップでゲーム詳細へ遷移するリスト）

### 5.2 共有ウィジェット抽出

- `dashboard_page.dart`の`_Section`/`_RankingSection`/`_DistributionSection`/`_BarRow`/`_displayLabel`を共有ファイル（例: `lib/src/ui/widgets/analytics_sections.dart`）に移し、public化する
- `dashboard_page.dart`は移動後のウィジェットを参照するだけに修正し、表示・挙動は変更しない
- `PlayAnalyticsPage`は、`CountEntry`系の指標（2〜4, 7）にこれらの共有ウィジェットを使う。`RatedEntry`系（5, 6, 8）には新規ウィジェット（平均値バー表示）、`forgottenFavorites`には新規のリストウィジェットを使う

### 5.3 コレクション一覧からの遷移

- `collection_list_page.dart`のAppBarに、既存の「ダッシュボード」アイコンの隣に「プレイ傾向」アイコン（`nav.playAnalytics`）を追加し、`PlayAnalyticsPage`へ遷移する

---

## 6. i18nキー一覧（新規追加）

- `nav.playAnalytics`（「プレイ傾向」）
- `play_analytics.title`（「プレイ傾向」）
- `play_analytics.empty`（「プレイ記録がありません」）
- `play_analytics.totalSessions`（「プレイ記録数」）
- `play_analytics.actualPlayingTime`（「実プレイ時間（平均）」）
- `play_analytics.actualVsNominal`（「公称時間との差（平均）」）
- `play_analytics.actualPlayingTimeDistribution`（「実プレイ時間の分布」）
- `play_analytics.mechanicsPlayCounts`（「よく遊ぶメカニクス」）
- `play_analytics.designerPlayCounts`（「よく遊ぶデザイナー」）
- `play_analytics.mechanicRatings`（「評価が高いメカニクス」）
- `play_analytics.designerRatings`（「評価が高いデザイナー」）
- `play_analytics.expansionUsage`（「拡張の使用回数」）
- `play_analytics.ratingByPlayerCount`（「人数別の評価」）
- `play_analytics.forgottenFavorites`（「最近遊んでいないお気に入り」）
- `play_analytics.ratingUnit`（「点」、平均評価の単位表示用）

既存キーの流用: 件数の内訳表示は`dashboard.qualityCount`、データなしは`dashboard.noData`、分の単位は`collection.minutesUnit`、人数の単位は`collection.playersUnit`、最終プレイ日は`collection.lastPlayedLabel`を使う。新規キーはja/en両方に追加すること。

---

## 7. 受け入れ基準（概要）

- `PlaySessionRepository.listAll()`が全ゲームのプレイ記録を`playedDate`降順で返し、各記録に`expansionGameKeys`が含まれる
- `PlayAnalyticsSummary`の各フィールドが4.3の算出方法どおりに計算される（特に`actualVsNominalPlayingTime`の符号、`mechanicRatings`/`designerRatings`の平均と件数、`forgottenFavorites`のしきい値・並び順）
- `PlayAnalyticsPage`に7セクションすべてが表示され、`totalSessions==0`のときは`play_analytics.empty`のみ表示される
- `forgottenFavorites`の各行から該当ゲームの詳細画面に遷移できる
- コレクション一覧から`PlayAnalyticsPage`へ遷移できる
- 共有ウィジェット抽出後、既存`DashboardPage`の表示内容・順序・挙動に変化がない
- 新規UI文言がja/en両方のi18nファイルに存在する
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス

詳細なタスク分割・実装制約は `docs/DEVELOPMENT_BRIEF_Phase6-D.md` を参照。
