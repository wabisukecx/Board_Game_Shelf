# Codex用開発文書: Board Game Shelf Phase 4（多次元分析指標の移植）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-13 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase4.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底） |
| 移植元（正本） | `C:\Users\tucon\StudioProjects\boardgame_analyzer\src\analysis\{strategic_depth,learning_curve,mechanic_complexity,category_complexity,rank_complexity}.py` と `config/{mechanics_data,categories_data,rank_complexity}.yaml` |
| 対象スコープ | **Phase 4**: 多次元分析指標の純Dart移植＋詳細画面/ダッシュボード反映 |
| 非対象 | 類似ゲーム(embeddings)／比較専用画面／係数の独自変更／YAML書き戻し／外部API／iOS等の拡大 |
| 実装エージェント | Codex |
| 前提 | Phase 0〜3 完了済み。本フェーズは T-36 から開始する |

---

## 0. 設計根拠（rationale）

- **移植元が正本**: 本アプリの土台は boardgame_analyzer の analyzer互換YAML。算出入力（mechanics/categories/ranks/weight/playingTime/minAge/players/year）は既にDBにある。式・係数・分岐は**移植元 .py を忠実にDart移植**し、独自チューニングしない。要約表は方向付けに過ぎない。
- **完全オフライン・決定的**: 外部API・鍵・ネットワーク不要。唯一「現在年」に依存する経年係数のみ、テスト安定と決定性のため **既存 `Clock` から年を注入**する（`DateTime.now()` 直書き禁止）。
- **重み付けは3 YAMLをアセット同梱・読み取り専用**: 未知名称は既定値にフォールバック（Python版のバッファ書き戻しは**移植しない**）。
- **UIから分離した純Dart**で算出し、ユニットテストで担保。新規依存は追加しない（`yaml` 既存、描画は組み込みウィジェット）。

---

## 1. 引き渡し手順（人間向け）

1. 本文書と `REQUIREMENTS_Phase4.md` を `docs/` に配置（配置済み）。
2. §2「冒頭プロンプト」をCodexに渡す。
3. Codexは§5のタスクを `T-36` から順に実行し、各完了時に「実装ファイル / テスト結果 / 受け入れ基準との対応」を報告。
4. 設計と矛盾が出たら停止して報告。

## 2. 冒頭プロンプト（Codexへ最初に渡す）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 4（多次元分析指標の移植）を実装します。
docs/REQUIREMENTS_Phase4.md と docs/DEVELOPMENT_BRIEF_Phase4.md が仕様書です。
移植元（正本）は ../boardgame_analyzer/src/analysis/*.py と config/*.yaml です。以下を厳守してください。

1. §5のタスクを T-36 から番号順に実装する。並行着手しない。
2. 算出式・係数・分岐は移植元 .py を忠実にDart移植する。独自チューニング禁止。
   要約表は方向付けで、判断に迷ったら移植元ソースを正本とする。
3. 算出は純Dartに分離し、ユニットテストで担保する。UI・ネットワーク・乱数に依存させない。
4. 「現在年」に依存する経年係数は DateTime.now() 直書きにせず、既存 Clock から注入する（決定性のため）。
5. 重み付け3 YAML はアセット同梱・読み取り専用。未知名称は既定値にフォールバックし、
   YAMLへ書き戻さない（Python版のバッファ保存は移植しない）。
6. 新規依存を追加しない（yaml 既存、描画は組み込みウィジェット）。読み取り専用でDB/アセットを変更しない。
7. 対象は Android。UI文言は assets/i18n/{ja,en}.json のキー経由（ハードコード禁止）。
8. §3 定数（既存 C-01〜38 / 本書 C-39〜42）は変更禁止。曖昧なら質問する。
まず T-36 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-39 | 分析重み付けアセット | `assets/analysis/{mechanics_data,categories_data,rank_complexity}.yaml`（boardgame_analyzer/config から同梱・読み取り専用） | 複雑度ルックアップ | 要件§1.1 |
| C-40 | 未知名称の既定値 | メカ complexity 2.5 / strategic 3.0 / interaction 3.0、カテゴリ complexity 2.5、ランク種別 complexity 3.0（書き戻し禁止） | フォールバック | 移植元 |
| C-41 | 指標レンジ | 各指標 1.0–5.0 にクランプ | 全指標 | 移植元 |
| C-42 | 入力既定値 | weight 3.0 / min_age 10 / min_players 2 / max_players 4 / playing_time（リプレイ性）60 | 欠損補完 | 移植元 |

補足: 係数（初期障壁 0.40/0.25/0.20/0.15、戦略的深度 0.20/0.35/0.10/0.25/0.10＋上限付きボーナス strategy≤0.4・hidden_info≤0.3・playtime≤0.1 等）は移植元の式に固定。改変禁止。

---

## 4. リポジトリ構成（追加分）

```
追加/変更ファイル（想定）:
assets/analysis/
  mechanics_data.yaml        … NEW: boardgame_analyzer/config から同梱（読み取り専用）
  categories_data.yaml       … NEW: 同上
  rank_complexity.yaml       … NEW: 同上
lib/src/
  domain/
    complexity_tables.dart   … NEW: 3 YAML を name→{complexity,strategic,interaction} に読込（未知→既定値, 書き戻しなし）
    learning_curve.dart      … NEW: 純Dart移植（10指標＋分類）。LearningCurveResult を返す
  app/providers.dart         … EDIT: complexityTablesProvider / learningCurveProvider 追加
  ui/pages/
    game_detail_page.dart    … EDIT: 「分析」セクション（10指標の横バー＋分類）を追加
    dashboard_page.dart      … EDIT: 戦略的深度の平均・分布、プレイヤータイプ件数等を追加
  domain/collection_analytics.dart … EDIT(任意): 戦略的深度等の集計を追加
assets/i18n/{ja,en}.json     … EDIT: analysis.* / learningCurve.* / playerType.* / masteryTime.* / replayability.* を追加
pubspec.yaml                 … EDIT: assets に assets/analysis/ を追加
test/
  t16... 以降の続き番号で:
  tNN_complexity_tables_test.dart … NEW: ロード・ルックアップ・未知既定値
  tNN_learning_curve_test.dart    … NEW: 既知ゲームの指標が移植元と許容誤差内 / 欠損・未知で例外なし / 1.0-5.0
README.md                    … EDIT: 分析指標の説明・出典（boardgame_analyzer）
```
（テスト番号は既存の最終番号＋1から連番にすること。）

---

## 5. 実装タスク（execution order・T-36〜T-40）

### T-36 重み付けアセット同梱＋ローダ
- 内容: `boardgame_analyzer/config` の3 YAML を `assets/analysis/` にコピーし pubspec に登録。`complexity_tables.dart` で `rootBundle` から読み込み、`name→{complexity, strategicValue, interactionValue}` のマップを構築。未知名称は C-40 の既定値を返す（書き戻ししない）。複雑度集約関数（`calculateCategoryComplexity`／`calculateRankComplexity`／`calculateRankPositionScore`）も移植元どおり移植。
- 受け入れ基準:
  - [ ] 3 YAML がアセットから読み込め、既知名称の complexity/strategic/interaction を返す
  - [ ] 未知名称で C-40 既定値を返し、例外・書き戻しが発生しない
  - [ ] `calculateRankPositionScore` 等が移植元と一致（代表値で検証）

### T-37 多次元指標アナライザ（純Dart移植）
- 内容: `learning_curve.dart` に `LearningCurveAnalyzer`（入力: 既存 `Game`＋複雑度テーブル＋現在年は Clock 注入）。移植元の `calculate_strategic_depth_improved` / `calculate_learning_curve` / 各補助関数を忠実移植し、`LearningCurveResult`（10指標＋学習曲線タイプ＋プレイヤータイプ＋習熟時間＋深度/リプレイ性説明キー）を返す。入力形状の対応（mechanics/categories=List<String>、ranks=GameRanksの(type,rank)、weight/year=String?・double?の数値化）と既定値（C-42）を厳守。意思決定点の要素数別重みテーブル、戦略的深度の上限付きボーナスと最終 complexity_factor 乗算、初期障壁の complexity_factor（別物）を正しく実装。
- 受け入れ基準:
  - [ ] 代表ゲーム数件で各指標が移植元と許容誤差（例 ±0.05）内
  - [ ] mechanics/categories/ranks 欠損・未知名称・weight/year欠損でも例外なく算出
  - [ ] 全指標が 1.0–5.0 に収まり、分類（曲線タイプ9/プレイヤータイプ/習熟時間4）が移植元の条件と一致
  - [ ] 現在年は注入され、テストが時計に依存しない（経年係数の決定性）

### T-38 詳細画面（S-04）への表示
- 内容: `game_detail_page.dart` に「分析」セクションを追加。10指標を 1.0–5.0 の横バー（組み込みウィジェット）で表示し、戦略的深度・リプレイ性の説明、学習曲線タイプ・プレイヤータイプ・習熟時間を表示。入力が乏しいローカルレコードでは「参考値」である旨を添える。
- 受け入れ基準:
  - [ ] BGG由来ゲームで10指標＋分類が表示される
  - [ ] ローカル/欠損ゲームでも例外なく参考値が表示される
  - [ ] 文言はi18nキー経由

### T-39 ダッシュボード（Phase 2）への集計反映
- 内容: 所持コレクションに対し、戦略的深度の平均・分布、プレイヤータイプ件数、習熟時間分布等を集計して `dashboard_page.dart` に追加（`collection_analytics.dart` を拡張、または同等の集計を用意）。算出は T-37 のアナライザを再利用。
- 受け入れ基準:
  - [ ] 戦略的深度の平均・分布が表示される（null/欠損は除外し件数明示）
  - [ ] プレイヤータイプ/習熟時間の件数が表示される
  - [ ] 1,000件規模でスクロールがジャンクしない

### T-40 i18n・README・仕上げ
- 内容: `analysis.*`/`learningCurve.types.*`/`playerType.*`/`masteryTime.*`/`replayability.*`/`analysis.depth.*` のi18nキーを ja/en に追加（移植元 `config/languages/{ja,en}.json` を参考に自然な訳を付ける）。README に分析指標の説明・出典（boardgame_analyzer）を追記。
- 受け入れ基準:
  - [ ] 追加文言がすべて ja/en のキー経由で、ハードコード文字列が無い
  - [ ] `flutter analyze` 警告ゼロ、`flutter test` 全件パス

---

## 6. 移植式の要点（参照・正本はソース）

> 以下は実装時の早見。**最終判断は移植元 .py**。係数・分岐・上限を勝手に変えないこと。

- **メカニクス複雑度(avg)**: 各メカの `complexity` 平均（既定2.5）。
- **ルール複雑度**: `(avg_mechanic_complexity × min(1.5, 1+件数/10)) × 0.6 + age_complexity × 0.2 + weight × 0.2`。`age_complexity = min(4.0, (min_age−6)/3)`、`min_age` 既定10、`weight` 既定3.0。1–5クランプ。
- **意思決定点**: 各メカの `strategic_value` を降順ソートし要素数別重み（1→[1.0]、2→[0.65,0.35]、3→[0.55,0.30,0.15]、4+→[0.5,0.25,残りを下限保証で分配]）で加重平均。`diversity_bonus = min(0.4, ユニーク値数×0.07 + 値域×0.1)`。playtime の `decision_density`(×0.8) と `complexity_factor`(影響0.9に抑制) を適用。1–5。
- **相互作用複雑度**: categories/mechanics の `interaction_value` を 60:40 加重（両方あるとき）。片方のみは要素数別重み。playtime `interaction_modifier`(×0.85) と `complexity_factor`(0.9) 適用、`max_players≥5→×1.10 / ≥4→×1.07`。1–5。
- **戦略的深度**: `weight×0.20 + decision×0.35 + rules×0.10 + interaction×0.25 + weight×0.10 + strategy_bonus(≤0.4) + playtime_bonus(=playtime_strategic×0.6, ≤0.1) + hidden_info_bonus(≤0.3)`、最後に playtime `complexity_factor`（影響0.95に抑制）を乗算。1–5、round2。`strategy_bonus` は上位3メカの `(value−2.5)×0.1` を重み[0.5,0.3,0.2]で和、`decay = 1/(1+log10(件数))`、最終 min(0.8,...)。`hidden_info` 該当メカ数×0.1（≤0.3）。
- **初期障壁**: `avg_mechanic_complexity×0.40 + rules×0.25 + weight×0.20 + (category_complexity×0.6 + rank_complexity×0.4)×0.15`、×`min(1.25, max(1.0, メカ件数/5))`、上限5、round2。
- **リプレイ性**: `base 2.0 + diversity(メカ件数×0.1≤0.7 + 高リプレイメカ×0.2/中×0.1≤0.8 + カテゴリ件数×0.1≤0.4) + rank_bonus(=(rank_position_score−1)/4×0.6≤0.6)` を `× longevity_factor` し、`+ playtime_replay_bonus`（≤30:+0.3, ≤60:+0.15, ≥180:−0.2）。1–5、round2。
  - `longevity_factor`: 経過年 ≥20→1.1 / ≥10→1.07 / ≥5→1.05 / else 1.0。**経過年は注入した現在年−year_published**。
- **rank_position_score**: ≤10→5.0 / ≤100→4.5→4.0 / ≤1000→4.0→3.0 / ≤5000→3.0→2.0 / else `max(1.0, 2.0 − log10(rank/5000))`。
- **calculate_rank_complexity**: 各ランクで `type_complexity×0.8 + (position_score−3.0)×0.2`、重み（boardgame1.0 / strategy・war1.2 / family・party・children0.8）で加重平均。既定3.0。
- **category_complexity**: 各カテゴリ `complexity` 平均 × `min(1.3, 1+(件数−1)×0.05)`。既定2.5。
- **ソロ適性**: 'Solo / Solitaire Game'→5.0 / 'Cooperative Game'→4.0 / Campaign系→3.5 / min_players==1→3.0 / else 1.0。
- **人数スケーラビリティ**: `min(5.0, 2.0 + (max−min)×0.5)`。既定 min2/max4。
- **運依存度**: `min(5, max(1, 3.0 + 運メカ数×0.5 − 戦略メカ数×0.4))`。
- **分類**: 学習曲線タイプ（initial_barrier×strategic_depth の閾値で9種）、プレイヤータイプ（beginner/casual/experienced/hardcore/strategist/system_master/replayer/trend_follower(rank≤1000)/classic_lover(year≤2000)、該当なしは barrier/depth で補完）、習熟時間（strategic_depth×initial_barrier×メカ件数で short/medium/medium_to_long/long）。条件は移植元 `update_learning_curve_with_improved_strategic_depth` と `calculate_learning_curve` を厳密移植。

---

## 7. 禁止事項・制約

1. **係数・分岐・上限を独自変更しない**。移植元 .py を正本に忠実移植。
2. **YAMLへ書き戻さない**。未知名称は既定値（C-40）にフォールバック。アセットは読み取り専用。
3. **現在年を直書きしない**。既存 `Clock` から注入し決定性を保つ。
4. **新規依存を追加しない**。`yaml` 既存、描画は組み込みウィジェット。
5. **読み取り専用**。DB・アセットを書き換えない。外部API・ネットワーク・鍵を使わない。
6. **入力形状/既定値のズレに注意**（List<String>↔{name}、GameRanks↔(type,rank)、weight/year の数値化、2種の complexity_factor の混同禁止）。
7. 対象は Android。UI文言ハードコード禁止（i18nキー経由）。テストは時計・乱数・ネットワークに依存させない。

---

## 8. 完了の定義（Phase 4 Done）

- T-36〜T-40 の全受け入れ基準がテストで担保され、`flutter test` が全件成功する
- `flutter analyze` 警告ゼロ
- 代表ゲームの指標が移植元と許容誤差内で一致する
- 詳細画面に10指標＋分類、ダッシュボードに戦略的深度の平均・分布等が表示される
- 算出がDB・アセットを書き換えない（読み取り専用）／新規依存が増えていない
- README に分析指標の説明・出典が追記されている