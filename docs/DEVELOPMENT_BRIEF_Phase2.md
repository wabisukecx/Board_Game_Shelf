# Codex用開発文書: Board Game Shelf Phase 2（コレクション分析ダッシュボード）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-13 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase2.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底・定数表/構成） |
| 対象スコープ | **Phase 2**: 所持コレクションの読み取り専用の集計・可視化（ダッシュボード S-09） |
| 非対象 | 外部API/オンライン集計、DB書き込み、分析結果のエクスポート、リッチチャート必須化、既存フェーズの変更 |
| 実装エージェント | Codex |
| 前提 | Phase 0〜1-C 完了済み。本フェーズは T-26 から開始する |

---

## 0. 設計根拠（rationale）

- **読み取り専用・完全オフライン**: 既存DBの所持データだけを集計する。ネットワーク・カメラ・鍵・DB書き込みを一切使わない。最も安全でテストしやすい領域。
- **集計はUIから分離した純Dart**: `CollectionAnalytics`（純Dart）で集計し、ユニットテストで担保。UIは集計結果を描画するだけにする。
- **新規依存なしを既定**: 分布/ランキングは組み込みウィジェット（横バー＝幅比率）で描画する。`fl_chart` 等の導入は任意の将来拡張とし、本フェーズでは追加しない。
- **欠損の明示**: ローカルレコード・BGG未取得項目の null は集計から除外し、各指標に「対象N/除外M」を持たせて誤った平均を出さない。
- **既存資産の再利用**: 入力は `CollectionRepository.list()`。`CollectionListItem`（Game＋CollectionEntry＋isLocal）をそのまま集計入力にする。

---

## 1. Codexへの引き渡し手順（人間向け）

1. 本文書を `docs/DEVELOPMENT_BRIEF_Phase2.md` として配置（配置済み）。
2. §2「冒頭プロンプト」をCodexの最初の指示として貼り付ける。
3. Codexは§5のタスクを `T-26` から順に実行し、各タスク完了時に受け入れ基準の充足を報告する。
4. 設計と矛盾が出たら実装を止めて報告（勝手に仕様を変えない）。本文書を改訂してから再開する。

## 2. 冒頭プロンプト（Codexへ最初に渡す指示）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 2（コレクション分析ダッシュボード）を実装します。
docs/REQUIREMENTS_Phase2.md と docs/DEVELOPMENT_BRIEF_Phase2.md が仕様書です。
Phase 0〜1-C は完了済みで、既存コードを再利用します。以下を厳守してください。

1. §5のタスクを T-26 から番号順に実装する。並行着手しない。
2. 各タスクの受け入れ基準をテストコードで担保し、完了報告に
   「実装ファイル一覧 / テスト結果 / 基準との対応」を含める。
3. 読み取り専用。DBへ書き込まない。ネットワーク・カメラ・鍵を一切使わない（完全オフライン）。
4. 集計は純Dartの CollectionAnalytics に切り出し、UIと分離してユニットテストする。
   weight/averageRating/purchasePrice/acquiredDate の null・パース不能は除外し、除外件数を保持する。
5. 新規依存は追加しない（組み込みウィジェットで横バー描画）。fl_chart 等は使わない。
6. UI文言はすべて assets/i18n/{ja,en}.json のキー経由（ハードコード禁止）。
7. 既存の定数・スキーマ・YAML互換・vision/barcode基盤を変更しない。
8. §3 定数（Phase 0 C-01〜18 / 1-A〜1-C C-19〜30 / 本書 C-31〜35）は変更禁止。曖昧なら質問する。
まず T-26 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-31 | 上位ランキング表示件数 (Top-N) | 10 | メカ/カテゴリ/デザイナー/パブリッシャー | 要件§4 |
| C-32 | 人数カバレッジ範囲 | 1〜8人 | 各人数で遊べる所持数 | 要件§4 |
| C-33 | 重さバケット境界 | `[1.5, 2.5, 3.5, 4.5]`（5区分: <1.5 / 1.5–2.5 / 2.5–3.5 / 3.5–4.5 / ≥4.5） | 重さ分布 | 要件§4 |
| C-34 | プレイ時間バケット境界(分) | `[30, 60, 90, 120]`（5区分: ≤30 / 31–60 / 61–90 / 91–120 / >120） | 時間分布 | 要件§4 |
| C-35 | 分析対象の既定 | `owned = true` のみ（トグルで全レコードを含む） | 集計対象 | 要件§5 |

補足: 年代分布は 10年刻み（例 1990s/2000s/2010s/2020s）。評価分布は 1点刻み（例 6点台/7点台/8点台）。同数のランキングはラベル昇順で安定ソート。

---

## 4. 技術スタック・リポジトリ構成（追加分）

| 項目 | 指定 |
|---|---|
| 集計 | 純Dart `CollectionAnalytics`（`List<CollectionListItem>` → `AnalyticsSummary`）。null/パース安全、決定的順序 |
| 状態管理 | 既存 Riverpod。`analyticsProvider`（FutureProvider）で list 取得→集計 |
| 描画 | 組み込みウィジェットのみ（Card/ListTile/横バー＝`FractionallySizedBox` 等）。新規依存なし |
| テスト | flutter_test。集計を純Dartでユニットテスト（欠損/ローカル/同点順序/バケット境界/カバレッジ） |

```
追加/変更ファイル（想定）:
lib/src/
  domain/
    collection_analytics.dart   … NEW: CollectionAnalytics + AnalyticsSummary（純Dart集計）
  app/providers.dart            … EDIT: analyticsProvider（list→集計, owned/all 切替）追加
  ui/pages/
    dashboard_page.dart         … NEW: S-09 ダッシュボード（概要/分布/カバレッジ/Top-N/保管・入手）
    collection_list_page.dart   … EDIT: AppBar に「分析」アクションを追加 → S-09 へ
  ui/widgets/
    stat_card.dart              … NEW(任意): 指標カード
    bar_row.dart                … NEW(任意): 横バー1行（ラベル/値/比率）
assets/i18n/{ja,en}.json        … EDIT: dashboard.* を追加
test/
  t15_collection_analytics_test.dart … NEW: 集計ロジックのユニットテスト
README.md                       … EDIT: ダッシュボードの説明
```

---

## 5. 実装タスク（execution order・T-26〜T-30）

### T-26 集計ロジック（CollectionAnalytics）＋ユニットテスト
- 内容: `domain/collection_analytics.dart` に純Dartの集計。入力 `List<CollectionListItem>` と `includeNotOwned` フラグ。出力 `AnalyticsSummary`（総数/内訳、平均weight・平均rating〔null/パース不能除外＋除外件数〕、購入価格合計/平均/入力件数、重さ分布(C-33)、時間分布(C-34)、年代分布、評価分布、人数カバレッジ(C-32)、Top-N(C-31, 同数はラベル昇順)、保管場所別、入手時期推移）。`averageRating`/`yearPublished` は String? を数値化、`weight`/`purchasePrice` は double?、人数/時間は int?。
- 受け入れ基準:
  - [ ] weight/rating/price が null・パース不能の要素が平均から除外され、`対象N/除外M` が出力される
  - [ ] 重さ/時間がバケット境界（C-33/C-34）の値で正しい区分に入る（境界値の所属が定義どおり）
  - [ ] 人数カバレッジが min≤n≤max で各 n（C-32）について正しく数えられる（min/max欠損は対象外）
  - [ ] Top-N が頻度降順・同数はラベル昇順で安定し、最大 C-31 件
  - [ ] `includeNotOwned=false` で owned のみ、`true` で全件が対象になる
  - [ ] 空入力でゼロ値の `AnalyticsSummary` を返し例外を投げない

### T-27 Provider/DI＋導線
- 内容: `analyticsProvider`（`CollectionRepository.list(filter: const CollectionFilter())` を取得し `CollectionAnalytics` で集計、owned/all トグル状態を `StateProvider` で保持）。S-01 の AppBar に「分析」アクション（insights アイコン）を追加し S-09 へ遷移。
- 受け入れ基準:
  - [ ] S-01 から S-09 に遷移できる
  - [ ] トグル変更で集計対象（owned/all）が切り替わり再集計される
  - [ ] 集計過程でDBへ書き込みが発生しない

### T-28 ダッシュボードUI（概要＋データ品質ノート）
- 内容: `dashboard_page.dart` に 概要セクション（指標カード）とデータ品質ノート（ローカル件数・weight/rating欠損件数・価格入力件数）。空状態（所持ゼロ）と全欠損時の「—」表示。owned/all トグルUI。
- 受け入れ基準:
  - [ ] 概要カードに総数/内訳/平均weight/平均rating/購入価格合計が表示される
  - [ ] 全欠損の平均が「—」になり、除外件数が明示される
  - [ ] 所持ゼロ件で空状態が表示される（クラッシュしない）

### T-29 ダッシュボードUI（分布・カバレッジ・ランキング）
- 内容: 分布（重さ/時間/年代/評価）・人数カバレッジ・Top-N（メカ/カテゴリ/デザイナー/パブリッシャー）・保管場所別・入手時期推移を、組み込みウィジェットの横バー（幅比率＋件数ラベル）で描画。新規依存を追加しない。
- 受け入れ基準:
  - [ ] 各分布/カバレッジ/Top-N が件数つき横バーで表示される
  - [ ] 1,000件のシードでスクロールがジャンクしない（遅延構築）
  - [ ] `fl_chart` 等の新規依存が pubspec に追加されていない

### T-30 i18n・README・仕上げ
- 内容: `dashboard.*` のi18nキーを ja/en に追加。README にダッシュボードの説明を追記。
- 受け入れ基準:
  - [ ] 追加文言がすべて ja/en のキー経由で、ハードコード文字列が無い
  - [ ] `flutter analyze` 警告ゼロ、`flutter test` 全件パス

---

## 6. 既存資産マッピング（実装時に参照）

| 用途 | 既存シンボル / 型 | 所在 |
|---|---|---|
| 集計入力 | `CollectionRepository.list(filter:)` → `List<CollectionListItem>`（`game` / `collection` / `isLocal` / `displayName`） | `lib/src/data/repo/collection_repository.dart` |
| ゲーム属性 | `Game`: `weight`(double?), `averageRating`(String?), `yearPublished`(String?), `playingTime`(int?), `publisherMinPlayers`/`publisherMaxPlayers`(int?), `mechanics`/`categories`/`designers`/`publishers`(List<String>) | `lib/src/data/db/app_database.dart` |
| 所持メタ | `CollectionEntry`: `owned`(bool), `purchasePrice`(double?), `storageLocation`(String?), `acquiredDate`(String?) | 同上 |
| フィルタ | `CollectionFilter`（全件取得は `const CollectionFilter()`） | `lib/src/data/repo/collection_repository.dart` |
| 一覧画面（導線元） | `CollectionListPage` の AppBar に「分析」を追加 | `lib/src/ui/pages/collection_list_page.dart` |
| DI | `lib/src/app/providers.dart`（`analyticsProvider` 追加） | 同上 |
| i18n | `I18n.t(key, vars)`（未定義キーはキー文字列を返す） | `lib/src/i18n/i18n.dart` |

注意: `averageRating` と `yearPublished` は **文字列**（YAML互換のため）。集計時に `double.tryParse` / `int.tryParse` で数値化し、失敗・null は除外すること。

---

## 7. 禁止事項・制約

1. **DBへ書き込まない・データを補正しない**（読み取り専用）。再取得・外部API・ネットワーク・カメラ・鍵を使わない。
2. **新規依存を追加しない**（組み込みウィジェットで描画）。`fl_chart` 等は本フェーズで導入しない。
3. **欠損を平均に混ぜない**。null/パース不能は除外し、除外件数を必ず保持・表示する。
4. **集計をUIに埋め込まない**。純Dartの `CollectionAnalytics` に分離し、UIから独立してテストする。
5. **既存フェーズの定数・スキーマ・YAML互換・vision/barcode基盤を変更しない**。
6. UI文言ハードコード禁止（i18nキー経由）。
7. 集計は決定的（同数はラベル昇順など）で、テストが時刻・乱数・ネットワークに依存しないこと。

---

## 8. 完了の定義（Phase 2 Done）

- T-26〜T-30 の全受け入れ基準がテストで担保され、`flutter test` が全件成功する
- `flutter analyze` 警告ゼロ
- 実機（Android）で「S-01→分析→ダッシュボード表示／owned・all 切替」が動作する
- 欠損・空・全欠損の各ケースで「—」や除外件数が正しく表示され、クラッシュしない
- 集計がDBへ一切書き込まない（読み取り専用）ことが担保される
- 新規依存が追加されていない
- README にダッシュボードの説明が追記されている
