# Board Game Shelf 改修ブリーフ：ゲーム名のUI言語連動表示（Phase 8 / Codex向け）

## 前提・対象
- 対象: `C:\Users\tucon\StudioProjects\bg_shelf_scanner`（Flutter / Riverpod）
- 目的: ゲーム名（タイトル）の**表示**を、Phase 7 で導入したUI言語設定に連動させる。日本語UIなら日本語名、英語UIなら英語名を優先表示する。日本語名が無いゲームは英語名（primary）にフォールバックする。
- 各タスクは独立コミット可能な粒度。既存テストを壊さないこと。各タスク完了時に `flutter test` を実行。

## 重要な背景（調査済みの事実 — これに合わせて実装すること）

### データ構造
- `GameNames`（`lib/src/domain/game_names.dart`）は `primary` / `japanese`(nullable) / `english` / `alternates` を持つ。
- BGGパーサ（`bgg_xml_parser.dart` の `_parseNames`）の埋め方は**非対称**:
  - `english` には常に `primary`（BGGプライマリ名）が入る。ほぼ必ず存在する。
  - `japanese` は、BGG代替名に `language=ja/jp/jpn` が付くか、カナを含む別名がある場合のみ埋まる。**多くのゲームでは null**。
  - したがって「日本語名が無いゲーム」は普通に存在する。フォールバック必須。
- ローカル登録ゲーム（手動追加 `local_game_repository.dart`）は `primary`/`japanese`/`english` すべてに同じ入力タイトルが入る。言語連動しても表示は変わらず、害もない。

### 現状の表示ロジック（ここが日本語ハードコード）
`lib/src/data/repo/collection_repository.dart` のトップレベル関数:
- `resolveJapaneseDisplayName(Game)` … 常に「japanese → primary → name → '名称不明'」の順。
- `resolveJapaneseSubtitle(Game)` … 常に「English: <primary>」固定（日本語名があるときのみ表示）。
これらが `CollectionRepository.list()` で `displayName` / `subtitle` を組み立てるのに使われている。
**この2関数が言語固定の原因**。Phase 7 を入れてもここが日本語前提のままなので、ゲーム名がUI言語に連動しない。

### 検索は既に全言語名対象（変更しないこと）
`CollectionRepository._matches()` の `titleQuery` 判定は、`name`/`japaneseName`/`primary`/`japanese`/`english`/`alternates` すべてを小文字化して部分一致対象にしている。
→ 「他言語名でも検索ヒットする」は**既に満たされている**。本改修で検索対象を狭めてはならない。表示言語を変えても、全言語名で引けるヒット挙動は維持する。

### 確定仕様（ユーザー決定済み）
- 表示はUI言語に連動（日本語UI→日本語名、英語UI→英語名）。
- 日本語UIで日本語名が無いゲームは**英語名(primary)にフォールバック**して表示。
- 検索は表示言語を反映しつつ、全言語名でヒットを漏らさない（＝現状の全言語検索を維持）。
- ソートは表示名（displayName）基準に揃える（現状どおり displayName で比較）。

---

## タスク0: 表示言語の受け渡し方を決める（実装前の判断と報告）
表示名の解決には「現在の表示ロケール（例 'ja' / 'en'）」が必要。`CollectionRepository.list()` は現在ロケールを知らないので、渡す経路を決める。

採用方針（これで実装すること）:
1. `list()` に `String displayLocaleCode` 引数（必須でなく既定 'ja' でも可。ただし呼び出し側で必ず現在ロケールを渡す）を追加する。
2. Phase 7 で `effectiveLocaleProvider`（または相当）が現在の有効ロケールを提供しているはずなので、`collectionListProvider`（`lib/src/app/providers.dart`）で `ref.watch(effectiveLocaleProvider)` の localeCode を読み、`list(filter:..., sortOrder:..., displayLocaleCode: code)` に渡す。
3. これにより言語切り替え→`collectionListProvider`再評価→表示名再計算、で**即時反映**される。Phase 7 のプロバイダ名・取得方法を実コードで確認し、それに合わせること（名前が違う場合は実在のものを使う）。

報告: Phase 7 で現在ロケールを公開しているプロバイダ名と型を、実装前に明記すること。

---

## タスク1: 言語対応の表示名リゾルバを新設（domain）
`collection_repository.dart` の日本語ハードコード2関数を置き換える、言語引数付きリゾルバを作る。

1. 新規 `lib/src/domain/display_names.dart`（場所は適宜）に純粋関数を実装:
   - `String resolveDisplayName(Game game, String localeCode)`
     - localeCode が 'ja' 系: japanese(非空) → primary(非空) → name(非空) → フォールバック の順。
       - 注: '名称不明' は i18n 文言にすべき（タスク3参照）。リゾルバ自体はフォールバック文字列を引数で受けるか、空を返して呼び出し側で i18n を当てる設計にし、ハードコード日本語を残さないこと。
     - localeCode が 'en' 系: english/primary(非空) → japanese(非空) → name(非空) → フォールバック の順。
     - その他の localeCode: 英語優先（primary → japanese → name → フォールバック）。Phase 7 のフォールバックが英語であることと整合させる。
   - `String? resolveSubtitle(Game game, String localeCode)`
     - 主表示名と異なる「もう一方の言語名」をサブタイトルに出す。
       - 日本語UIで日本語名を主表示しているとき: 英語名が異なれば英語名をサブに（ラベルは i18n、後述）。
       - 英語UIで英語名を主表示しているとき: 日本語名があり異なれば日本語名をサブに。
       - 主・副が同一、または副が無いときは null。
     - サブタイトルのラベル（現状 "English: " 固定）は i18n キー化する（タスク3）。
2. これらは純粋関数としてユニットテストを書く。ケース最低限:
   - 日本語名あり/なし × ja/en ロケール
   - english==japanese（ローカル登録ゲーム想定）でサブタイトルが null
   - すべて空で fallback が返る
   - 'fr' など他ロケールで英語優先になる

---

## タスク2: CollectionRepository を言語対応に改修（data）
1. `list()` に `displayLocaleCode` を追加（タスク0）。
2. `displayName` / `subtitle` の組み立てを、旧 `resolveJapaneseDisplayName` / `resolveJapaneseSubtitle` からタスク1の新リゾルバ呼び出しに置き換える。
3. 旧2関数は削除（または新リゾルバへの薄いラッパに退避し、最終的に削除）。他からの参照（テスト含む）を grep し、全て新APIに移行すること。
4. **検索 `_matches` は変更しない**。全言語名を対象にしたまま維持する（確定仕様）。
5. ソートは現状どおり `displayName` 比較を維持（displayName が言語連動した結果でソートされる＝表示言語順になる）。
6. `groupCollectionItems` 内の拡張ソートも `displayName` 基準のままでよい（言語連動後の displayName を使う）。

---

## タスク3: i18n文言の追加（assets/i18n）
ハードコード日本語をキー化する。`ja.json` / `en.json` 両方に同じキー構造で追加:
- `game.nameUnknown` … '名称不明' / 'Unknown title'
- サブタイトルのラベル（現状 "English: " 固定の英語ハードコード）の扱い:
  - 案A（推奨）: サブタイトルは「ラベル＋名前」をやめ、**名前だけ**を副表示にする。これが最も言語中立で簡潔。ラベルキー不要。
  - 案B: ラベルを残すなら `game.alternateNameLabel`（例 '別名: ' / 'Also: '）のように言語中立な文言にする。
  - どちらでもよいが、"English:" 固定の英語ハードコードは残さないこと。
- 呼び出し側（UI もしくはリポジトリ）で `i18n.t(...)` を当てる。リポジトリ層に i18n を持ち込みたくない場合は、リゾルバは「生の名前と、フォールバック要否のフラグ/空文字」を返し、UI層（`collection_list_page.dart` 等）で最終的な文言を i18n で確定する設計にする。レイヤリングはこの方針を優先。

---

## タスク4: UI反映確認（ui）
1. `collection_list_page.dart`（リスト/グリッド両方）と、ゲーム詳細 `game_detail_page.dart` で、表示名・サブタイトルが新リゾルバ経由になっていることを確認・修正。
   - 詳細画面が独自に `resolveJapanese...` を呼んでいないか grep。呼んでいれば言語対応版に差し替え、現在ロケールを渡す。
2. 言語切り替え（設定画面）→ 一覧/詳細のゲーム名が即時に切り替わることを手動確認（日本語名が無いゲームは英語名のまま＝フォールバック表示でよい）。
3. 検索ボックスで、日本語UIでも英語名で引けることを確認（全言語検索維持の回帰確認）。

---

## タスク5: ドキュメント更新（README）
`README.md` / `README.ja.md` の Localization / 多言語化 節に1〜2文追記:
- UI言語を切り替えると、ゲーム名の表示も連動する（日本語UI→日本語名、英語UI→英語名）。
- BGGに日本語名が無いゲームは英語名にフォールバックして表示される。
- 検索は表示言語に関わらず全言語の名前を対象にするため、別言語名でもヒットする。

---

## 実装順序
タスク0（経路決定・Phase7プロバイダ確認）→ タスク1（リゾルバ＋テスト）→ タスク3（i18nキー）→ タスク2（リポジトリ改修）→ タスク4（UI確認）→ タスク5（README）

## 完了条件
- UI言語切り替えで一覧・詳細のゲーム名表示が即時に連動する
- 日本語名が無いゲームは英語名にフォールバック表示される
- 検索は全言語名対象を維持し、別言語名でもヒットする（回帰なし）
- ソートは表示名基準（＝表示言語順）
- '名称不明' / 'English:' 等の言語ハードコードが残っていない（i18n化 or ラベル廃止）
- 旧 `resolveJapaneseDisplayName` / `resolveJapaneseSubtitle` への参照が消えている
- 新規ユニットテスト（表示名リゾルバ）追加、既存テスト緑
- 各タスク独立コミット、メッセージにタスク番号を記載
