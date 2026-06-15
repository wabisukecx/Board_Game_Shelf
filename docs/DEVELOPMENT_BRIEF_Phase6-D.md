# Codex用開発文書: BG Shelf Scanner Phase 6-D（プレイ傾向分析）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase6-D.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底） ③`docs/DEVELOPMENT_BRIEF_Phase6-A.md`（`PlaySessionRepository`の仕様） ④`docs/DEVELOPMENT_BRIEF_Phase6-C.md`（`CollectionListItem.playCount`/`lastPlayedDate`・`facets()`） |
| 対象スコープ | **Phase 6-D**: プレイ記録に基づく傾向分析の新規ページ |
| 非対象 | 人数×ゲームの満足度マトリクス／経年トレンド／勝率集計／既存ダッシュボードの指標変更 |
| 実装エージェント | Codex |
| 前提 | Phase 6-C完了済み（`CollectionRepository.facets()`、`CollectionListItem.playCount`/`lastPlayedDate`、`CollectionFilter`新規絞り込み、`CollectionSortOrder.lastPlayed`を確認済み）。本フェーズは **T-58** から開始する |

---

## 0. 設計根拠（rationale）

- **新規ページとして分離**: 既存`dashboard_page.dart`は「所持ゲームの構成」を扱う。プレイ記録に基づく「行動の傾向」は別の関心事であり、1ページに混在させるとセクション数が20を超え視認性が悪化する。新規ページ`PlayAnalyticsPage`として分離し、コレクション一覧から個別に遷移できるようにする。
- **共有ウィジェット抽出**: `CountEntry`を横棒グラフで表示する`_Section`/`_BarRow`はそのまま再利用できる。複製するとメンテナンス対象が倍になるため、共有ファイルに抽出してpublic化する。抽出は機械的なファイル分割であり、`dashboard_page.dart`側の見た目・挙動は変えない。
- **「人数×ゲーム」マトリクスを見送る理由**: 個人のプレイ記録量では、特定の人数×特定ゲームの組み合わせのサンプル数が1〜2件にしかならないことが多く、ランキングとして提示すると誤解を招く。まず「人数別の平均評価」という、サンプルを人数軸でのみ束ねる集計から始める。
- **しきい値7（10点満点）の根拠**: Phase 6-Aで`rating`をBGGの10点満点スケールに合わせた。BGGでは7点台が「good, usually willing to play」帯であることが一般的な目安であり、「お気に入り」の足切りとして妥当な値として採用する。
- **`listAll()`に最適化を入れない理由**: 個人コレクション×個人のプレイ記録という規模感では、全件取得＋メモリ上での集計で十分な性能が出る。将来データ量が増えた場合の最適化は別途検討する。

---

## 1. 引き渡し手順（人間向け）

1. 本文書と`REQUIREMENTS_Phase6-D.md`を`docs/`に配置（配置済み）。
2. §2「冒頭プロンプト」をCodexに渡す。
3. Codexは§5のタスクを`T-58`から順に実行し、各完了時に「実装ファイル/テスト結果/受け入れ基準との対応」を報告する。
4. 設計と矛盾が出たら停止して報告する。

## 2. 冒頭プロンプト（Codexへ最初に渡す）

```
あなたはFlutterアプリ「BG Shelf Scanner」の Phase 6-D（プレイ傾向分析）を実装します。
docs/REQUIREMENTS_Phase6-D.md と docs/DEVELOPMENT_BRIEF_Phase6-D.md が仕様書です。以下を厳守してください。

1. §5のタスクを T-58 から番号順に実装する。並行着手しない。
2. 既存の dashboard_page.dart のセクション構成・指標・表示内容・順序を変更しない。
   _Section 等の共有化はファイル分割のみで、見た目・挙動を変えてはならない。
3. 「人数×ゲーム」の満足度マトリクスは実装しない。ratingByPlayerCount
   （人数別の平均評価、人数昇順）のみとする。
4. forgottenFavorites のしきい値は本書C-51（playFavoriteRatingThreshold=7）を使う。
5. listAll() にページネーション・追加インデックス等の最適化は入れない。
6. 新規UI文言は assets/i18n/{ja,en}.json の両方に追加する（ハードコード禁止）。
   既存キー（dashboard.noData / dashboard.qualityCount / collection.minutesUnit /
   collection.playersUnit / collection.lastPlayedLabel）は流用する。
7. §3 定数（既存 C-01〜50 / 本書 C-51）は変更禁止。曖昧なら質問する。
まず T-58 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-51 | お気に入り評価しきい値 | `playFavoriteRatingThreshold = 7` | `forgottenFavorites`で「お気に入り」とみなす平均評価の下限（1-10スケール） | 要件§4.4 |

---

## 4. リポジトリ構成（追加分）

```
追加/変更ファイル（想定）:
lib/src/
  core/
    constants.dart                  … EDIT: C-51 (playFavoriteRatingThreshold) を追加
  data/
    repo/
      play_session_repository.dart  … EDIT: listAll() を追加
  domain/
    play_analytics.dart              … NEW: PlayAnalytics, PlayAnalyticsSummary,
                                       RatedEntry, FavoriteEntry
  app/
    providers.dart                  … EDIT: playSessionListAllProvider
                                       （FutureProvider<List<PlaySessionRecord>>）、
                                       playAnalyticsProvider
                                       （FutureProvider<PlayAnalyticsSummary>）を追加
  ui/
    widgets/
      analytics_sections.dart        … NEW: dashboard_page.dartから抽出した
                                       _Section/_RankingSection/_DistributionSection/
                                       _BarRow/_displayLabel をpublic化して移設
    pages/
      dashboard_page.dart             … EDIT: 上記widgetsの参照に置き換えるのみ
                                       （表示・挙動は変更しない）
      play_analytics_page.dart        … NEW: PlayAnalyticsPage
      collection_list_page.dart       … EDIT: AppBarに「プレイ傾向」アイコンを追加
assets/i18n/{ja,en}.json             … EDIT: 要件§6のキーを追加
test/
  t26_play_session_repository_test.dart … EDIT: listAll()のテストケースを追加
  t29_play_analytics_test.dart          … NEW: PlayAnalytics.summarize()の単体テスト
```

---

## 5. 実装タスク（execution order・T-58〜T-61）

### T-58 PlaySessionRepository.listAll() と定数追加
- 内容:
  - `core/constants.dart`にC-51（`playFavoriteRatingThreshold = 7`）を追加
  - `play_session_repository.dart`に`Future<List<PlaySessionRecord>> listAll()`を追加。`play_sessions`全件を`playedDate`降順・同値は`id`降順で取得し、`listForGame`と同様の方法で各記録の`expansionGameKeys`を解決する
- 受け入れ基準:
  - [ ] `listAll()`が複数ゲームの記録を`playedDate`降順で返し、各記録の`expansionGameKeys`が正しい
  - [ ] `listForGame`の既存挙動・既存テスト（t26）に後退がない

### T-59 PlayAnalyticsドメインの実装
- 内容: `lib/src/domain/play_analytics.dart`を新規作成。
  - `RatedEntry { final String label; final double average; final int count; }`
  - `FavoriteEntry { final String gameKey; final String label; final double averageRating; final String lastPlayedDate; }`
  - `PlayAnalyticsSummary`: 要件§4.3の全フィールド（`totalSessions`/`actualPlayingTime`/`actualPlayingTimeDistribution`/`actualVsNominalPlayingTime`/`mechanicsPlayCounts`/`designerPlayCounts`/`mechanicRatings`/`designerRatings`/`expansionUsage`/`ratingByPlayerCount`/`forgottenFavorites`）。`PlayAnalyticsSummary.empty()`ファクトリも用意する
  - `class PlayAnalytics { const PlayAnalytics(); PlayAnalyticsSummary summarize(List<CollectionListItem> items, List<PlaySessionRecord> sessions) {...} }`
  - 実装方針:
    - `itemsByKey = {for (final item in items) item.game.gameKey: item}`
    - 1回のループで`sessions`を走査し、`mechanicsPlayCounts`/`designerPlayCounts`/`mechanicRatingValues`/`designerRatingValues`/`expansionUsageCounts`/`ratingByPlayerCountValues`/`gameRatingValues`/`actualPlayingTimeValues`/`actualVsNominalDiffs`を集計する
    - `mechanicsPlayCounts`/`designerPlayCounts`/`expansionUsage`: 既存`_topLabels`と同様の方式（カウント降順、同数はラベル昇順、上位`AppConstants.analyticsTopN`件）
    - `mechanicRatings`/`designerRatings`: 平均降順、同値は件数降順、上位`AppConstants.analyticsTopN`件
    - `ratingByPlayerCount`: データのある人数のみ、人数（`AppConstants.analyticsMinPlayerCount`〜`analyticsMaxPlayerCount`）昇順
    - `forgottenFavorites`: `gameRatingValues`から各ゲームの平均評価を求め、`average >= AppConstants.playFavoriteRatingThreshold`かつ`itemsByKey[gameKey]?.lastPlayedDate != null`のものを対象に、`lastPlayedDate`昇順（同値は`displayName`昇順）で上位`AppConstants.analyticsTopN`件
    - `actualPlayingTimeDistribution`: 既存`_bucketInts`相当のロジックを`AppConstants.analyticsPlayingTimeBucketEdges`で適用（`collection_analytics.dart`のプライベート関数を直接は再利用せず、同等のロジックを`play_analytics.dart`内に実装してよい）
    - `actualVsNominalPlayingTime`: `actualPlayingTime`と`itemsByKey[gameKey]?.game.playingTime`が両方非nullのセッションについて`(actual - nominal).toDouble()`を集め、`NumericSummary.fromValues`（`totalCount`は`actualPlayingTime`が非nullのセッション数）
- 受け入れ基準:
  - [ ] `mechanicsPlayCounts`/`designerPlayCounts`が、各セッションのゲームの`mechanics`/`designers`それぞれに+1して集計した上位N件になる
  - [ ] `mechanicRatings`/`designerRatings`が、`rating`非nullのセッションのみを対象に平均・件数を正しく算出し、平均降順で並ぶ
  - [ ] `expansionUsage`が`expansionGameKeys`の出現回数を表示名付きで集計する
  - [ ] `ratingByPlayerCount`が人数昇順で、データのある人数のみ含む
  - [ ] `forgottenFavorites`が、平均評価がC-51以上かつ`lastPlayedDate`が古い順に並ぶ
  - [ ] `actualVsNominalPlayingTime`が符号付きで正しく算出される（実時間が長い場合は正）
  - [ ] `actualPlayingTimeDistribution`が既存の`playingTimeDistribution`と同じバケット境界・ラベルを用いる

### T-60 共有ウィジェット抽出とPlayAnalyticsPage実装
- 内容:
  1. `lib/src/ui/widgets/analytics_sections.dart`を新規作成し、`dashboard_page.dart`の`_Section`/`_RankingSection`/`_DistributionSection`/`_BarRow`/`_displayLabel`をpublic名（例: `AnalyticsSection`/`AnalyticsRankingSection`/`AnalyticsDistributionSection`/`AnalyticsBarRow`/`displayAnalyticsLabel`）で移設する
  2. `dashboard_page.dart`を編集し、移設したウィジェット/関数の参照に置き換える。**表示内容・順序・スタイルは変更しない**
  3. `lib/src/ui/pages/play_analytics_page.dart`を新規作成。
     - `totalSessions == 0`のとき`play_analytics.empty`のみ表示
     - それ以外は要件§5.1の9セクションを表示:
       - 概要カード: `totalSessions`/`actualPlayingTime.average`/`actualVsNominalPlayingTime.average`（符号付きで「+15分」等表示）
       - `actualPlayingTimeDistribution`: `AnalyticsDistributionSection`
       - `mechanicsPlayCounts`/`designerPlayCounts`/`expansionUsage`: `AnalyticsRankingSection`（`CountEntry`）
       - `mechanicRatings`/`designerRatings`/`ratingByPlayerCount`: 新規`RatedSection`/`RatedRow`ウィジェット（`RatedEntry`を、平均値/10のバー＋「{average}点 ({count}件)」表示）
       - `forgottenFavorites`: 新規`ForgottenFavoritesSection`（各行に`displayName`・`averageRating`・`lastPlayedDate`を表示し、タップで`GameDetailPage(gameKey: ...)`へ遷移）
  4. `app/providers.dart`に`playSessionListAllProvider`（`FutureProvider.autoDispose<List<PlaySessionRecord>>`）・`playAnalyticsProvider`（`FutureProvider.autoDispose<PlayAnalyticsSummary>`、`collectionRepositoryProvider.list(filter: const CollectionFilter())`と`playSessionListAllProvider`から`PlayAnalytics().summarize(...)`を呼ぶ）を追加
  5. `collection_list_page.dart`のAppBarに、既存の「ダッシュボード」（`Icons.insights`）の隣に「プレイ傾向」アイコン（例: `Icons.query_stats`、tooltip`nav.playAnalytics`）を追加し、`PlayAnalyticsPage`へ遷移する
- 受け入れ基準:
  - [ ] 共有ウィジェット抽出後、既存`DashboardPage`の表示内容・順序・スタイルに変化がない（目視確認）
  - [ ] `PlayAnalyticsPage`が9セクション構成で表示され、`totalSessions==0`時は`play_analytics.empty`のみ表示される
  - [ ] `forgottenFavorites`の行タップで該当ゲームの詳細画面に遷移する
  - [ ] コレクション一覧の「プレイ傾向」アイコンから`PlayAnalyticsPage`に遷移できる

### T-61 i18n追加・テスト整備・仕上げ
- 内容:
  - `assets/i18n/{ja,en}.json`に要件§6の新規キーを追加
  - `test/t29_play_analytics_test.dart`を新規作成し、T-59の受け入れ基準をカバーする（複数ゲーム・複数セッション・拡張使用・人数別評価・お気に入り閾値のケースを含む）
  - `test/t26_play_session_repository_test.dart`に`listAll()`のテストケースを追加
  - `flutter analyze`警告ゼロ・`flutter test`全件パス（t01〜t29）を確認
- 受け入れ基準:
  - [ ] 要件§6の全キーがja/en両方に存在する
  - [ ] `t29_play_analytics_test.dart`が追加され、T-59の受け入れ基準をカバーしてパスする
  - [ ] `flutter analyze`警告ゼロ、`flutter test`全件パス

---

## 6. 禁止事項・制約

1. **既存`DashboardPage`の指標・セクション構成・表示順序を変更しない**。ウィジェット抽出はファイル分割のみ。
2. **「人数×ゲーム」の満足度マトリクスを実装しない**。`ratingByPlayerCount`（人数別の平均評価のみ）に限定する。
3. **`mechanicRatings`/`designerRatings`/`forgottenFavorites`に最小サンプル数フィルタを追加しない**（件数を併記するのみ）。
4. **`listAll()`にページネーション・新規インデックス等の最適化を入れない**。
5. **新規依存を追加しない**。
6. UI文言ハードコード禁止（i18nキー経由、ja/en両方に追加。既存キーの再利用を優先する）。
7. `play_sessions`/`play_session_expansions`/`games`/`collection`のスキーマ変更は行わない。

---

## 7. 完了の定義（Phase 6-D Done）

- T-58〜T-61の全受け入れ基準がテストおよび目視確認で担保される
- `flutter analyze`警告ゼロ、`flutter test`全件パス
- `PlayAnalyticsPage`から、よく遊ぶメカニクス・デザイナー・評価が高いメカニクス/デザイナー・実プレイ時間統計（公称時間との差を含む）・拡張使用回数・人数別評価・最近遊んでいないお気に入りが確認できる
- 既存`DashboardPage`に表示・挙動の後退が発生しない
- 既存機能（Phase 0〜6-C）に後退が発生しない
