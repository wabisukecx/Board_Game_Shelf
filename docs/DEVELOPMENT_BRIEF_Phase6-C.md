# Codex用開発文書: Board Game Shelf Phase 6-C（遊ぶゲームを探す・絞り込み拡充）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase6-C.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底） ③`docs/DEVELOPMENT_BRIEF_Phase6-A.md`（`PlaySessionRepository`の仕様） |
| 対象スコープ | **Phase 6-C**: コレクション一覧の絞り込み・並び替え拡充（メカニクス・デザイナー・拡張あり・未プレイ・最終プレイ日順） |
| 非対象 | 新規「探す」専用画面／プレイ傾向分析／メカニクスのAND一致／3区分の拡張絞り込み |
| 実装エージェント | Codex |
| 前提 | Phase 6-B完了済み（`play_session_form_page.dart`、`game_detail_page.dart`の「プレイ記録」セクション、C-50、`test/t28`を確認済み）。本フェーズは **T-54** から開始する |

---

## 0. 設計根拠（rationale）

- **既存一覧の拡張で対応**: S-01（コレクション一覧）には既に人数・時間フィルタ、五十音順／デザイナー順ソート、拡張の親子表示がある。新画面を作るより、これらと同じ`CollectionFilter`/`CollectionSortOrder`の枠組みに新条件を追加する方が一貫性が高く、実装量も小さい。
- **選択肢は「自分のコレクション」基準**: BGGの全メカニクス/デザイナー語彙は数百〜数千におよぶが、個人のコレクションに含まれる値だけなら現実的な件数（数十程度）に収まり、検索付き複数選択ダイアログで十分扱える。
- **「最近遊んでいない」はソートで表現**: 日数しきい値を定数化すると、ユーザーごとに「最近」の感覚が異なり調整が必要になる。ソート（最終プレイ日が古い順）にすれば、しきい値を持たずに「上から見ていけば古い順」という直感的な使い方ができる。未プレイは「記録なし=最も古い」として自然に先頭に来る。
- **`playCount`/`lastPlayedDate`を`CollectionListItem`に持たせる**: Phase 6-D（傾向分析）でも「プレイ回数」「最終プレイ日」は土台になる値のため、本フェーズで`CollectionListItem`に持たせておくことで6-Dからの再利用が容易になる。

---

## 1. 引き渡し手順（人間向け）

1. 本文書と`REQUIREMENTS_Phase6-C.md`を`docs/`に配置（配置済み）。
2. §2「冒頭プロンプト」をCodexに渡す。
3. Codexは§5のタスクを`T-54`から順に実行し、各完了時に「実装ファイル/テスト結果/受け入れ基準との対応」を報告する。
4. 設計と矛盾が出たら停止して報告する。

## 2. 冒頭プロンプト（Codexへ最初に渡す）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 6-C（コレクション一覧の絞り込み・並び替え拡充）を実装します。
docs/REQUIREMENTS_Phase6-C.md と docs/DEVELOPMENT_BRIEF_Phase6-C.md が仕様書です。以下を厳守してください。

1. §5のタスクを T-54 から番号順に実装する。並行着手しない。
2. 新規の「探す」専用画面は作らない。既存の collection_list_page.dart / collection_repository.dart を拡張する。
3. メカニクス・デザイナーの絞り込みは facets()（所持ゲームの和集合）を選択肢とし、複数選択・OR一致とする。
   AND一致モードは実装しない。
4. 「拡張あり」は「コレクション内に登録済み拡張を持つ基本ゲームのみ表示」のトグル1つのみ。
   「基本のみ」等の追加区分は実装しない。
5. 「最近遊んでいない」は日数しきい値フィルタではなく、
   CollectionSortOrder.lastPlayed（最終プレイ日が古い順、未プレイは先頭）として実装する。
6. CollectionListItem に playCount/lastPlayedDate を追加し、
   gameKind != 'expansion' のゲームのみ PlaySessionRepository.listForGame で算出する
   （拡張は常に playCount=0 / lastPlayedDate=null）。
7. 既存の絞り込み（人数・時間・ローカルのみ）・ソート（五十音順・デザイナー順）・
   親子表示・analyticsProvider の挙動を変更しない。
8. 新規UI文言は assets/i18n/{ja,en}.json の両方に追加する（ハードコード禁止）。
9. 新規定数は不要（本書§3参照）。曖昧なら質問する。
まず T-54 から開始してください。
```

---

## 3. 追加定数

本フェーズでは新規定数の追加はない。既存の`AppConstants`（C-01〜C-50）は変更禁止。

---

## 4. リポジトリ構成（追加分）

```
追加/変更ファイル（想定）:
lib/src/
  app/
    providers.dart                 … EDIT: collectionRepositoryProviderに
                                      playSessions: ref.watch(playSessionRepositoryProvider) を追加。
                                      collectionFacetsProvider（FutureProvider<CollectionFacets>）を新規追加
  data/
    repo/
      collection_repository.dart    … EDIT: コンストラクタにPlaySessionRepository依存を追加、
                                      CollectionListItemにplayCount/lastPlayedDateを追加、
                                      CollectionFilterにmechanics/designers/hasExpansionsOnly/unplayedOnlyを追加、
                                      CollectionSortOrderにlastPlayedを追加、
                                      facets()を新規追加、_matches拡張
  ui/
    pages/
      collection_list_page.dart     … EDIT: _FilterBarへメカニクス/デザイナー/拡張あり/未プレイの
                                      フィルタを追加、ソートチップへlastPlayedを追加、
                                      検索付き複数選択ダイアログ（新規ウィジェット）、
                                      _Subtitleへ最終プレイ日/未プレイ表示を追加
assets/i18n/{ja,en}.json            … EDIT: 要件§6のキーを追加
test/
  t07_collection_repository_test.dart … EDIT: facets()・新規フィルタ・lastPlayedソート・
                                      playCount/lastPlayedDate算出のテストケースを追加
  t29_collection_filters_play_test.dart … NEW（任意）: t07で書きにくい複合ケース
                                      （プレイ記録ありの基本ゲーム＋拡張の組み合わせ等）を補完
```
（新規テストファイルを作る場合は、既存の最終番号(t28)＋1のt29から連番。t07の拡張で十分カバーできる場合はt29は不要）

---

## 5. 実装タスク（execution order・T-54〜T-57）

### T-54 CollectionRepositoryへのプレイ記録情報追加・facets()
- 内容:
  - `collection_repository.dart`の`CollectionRepository`コンストラクタに`required PlaySessionRepository playSessions`を追加
  - `app/providers.dart`の`collectionRepositoryProvider`を`CollectionRepository(database: ..., playSessions: ref.watch(playSessionRepositoryProvider))`に変更
  - `CollectionListItem`に`playCount: int`・`lastPlayedDate: String?`を追加
  - `list()`内で、各アイテムについて`game.gameKind != AppConstants.gameKindExpansion`のとき`playSessions.listForGame(game.gameKey)`を呼び、`playCount=records.length`・`lastPlayedDate=records.isEmpty ? null : records.first.playedDate`を設定（`listForGame`は`playedDate`降順のため先頭が最新）。拡張は`playCount=0`/`lastPlayedDate=null`
  - `CollectionFacets`クラスと`Future<CollectionFacets> facets()`を追加。全アイテムの`game.mechanics`/`game.designers`を集約し、重複排除・昇順ソートして返す
  - `app/providers.dart`に`collectionFacetsProvider = FutureProvider<CollectionFacets>((ref) => ref.watch(collectionRepositoryProvider).facets())`を追加
- 受け入れ基準:
  - [ ] `gameKind != 'expansion'`のゲームで、プレイ記録の件数・最新`playedDate`が`playCount`/`lastPlayedDate`に正しく反映される
  - [ ] 拡張は常に`playCount=0`/`lastPlayedDate=null`
  - [ ] `facets()`が所持ゲーム全体の`mechanics`/`designers`の和集合を重複なく昇順で返す
  - [ ] 既存の`analyticsProvider`・既存テスト（t01〜t28）に後退がない

### T-55 CollectionFilter/CollectionSortOrder拡張
- 内容:
  - `CollectionFilter`に`mechanics: List<String> = const []`・`designers: List<String> = const []`・`hasExpansionsOnly: bool = false`・`unplayedOnly: bool = false`を追加
  - `list()`内で、絞り込み前の全アイテムから「コレクション内に存在する拡張の`parentGameKey`集合」を算出する（`groupCollectionItems`の親子判定と同じ情報源で構わない）
  - `_matches`に以下を追加:
    - `filter.mechanics`が空でない場合、`item.game.mechanics`が1件以上含まれること（OR一致）
    - `filter.designers`が空でない場合、`item.game.designers`が1件以上含まれること（OR一致）
    - `filter.hasExpansionsOnly`が`true`の場合、`item.game.gameKey`が上記の「拡張を持つ親」集合に含まれること
    - `filter.unplayedOnly`が`true`の場合、`item.playCount == 0`であること
  - `CollectionSortOrder`に`lastPlayed`を追加。ソート時、`lastPlayedDate`を`item.lastPlayedDate ?? ''`として比較し昇順（空文字は最も古いものとして先頭）。同値は`displayName`昇順
- 受け入れ基準:
  - [ ] `mechanics`/`designers`を1件以上指定すると、いずれかに該当するアイテムのみが返る
  - [ ] `hasExpansionsOnly=true`で、コレクション内に登録済み拡張を持つ基本ゲームのみが返る
  - [ ] `unplayedOnly=true`で、`playCount==0`のアイテムのみが返る
  - [ ] `sortOrder=lastPlayed`で、未プレイ・最終プレイ日が古い順に並ぶ
  - [ ] 既存の`name`/`designer`ソート、既存フィルタ（人数・時間・ローカルのみ）の挙動に後退がない

### T-56 フィルタバーUI拡張
- 内容: `collection_list_page.dart`を編集。
  - 検索付き複数選択ダイアログ用の新規ウィジェット（例: `_MultiSelectFilterDialog`）を追加。`title`・`options: List<String>`・`initialSelection: Set<String>`を受け取り、検索テキストフィールドで`options`を部分一致フィルタしながら`CheckboxListTile`で複数選択、「クリア」「適用」ボタンを持つ
  - `_FilterBar`に以下を追加:
    - 「メカニクス」チップ: `ref.watch(collectionFacetsProvider)`の`mechanics`を選択肢に上記ダイアログを開き、結果を`filter.mechanics`に反映。選択件数が1件以上のときチップに件数を表示
    - 「デザイナー」チップ: 同様に`designers`を選択肢にし、`filter.designers`に反映
    - 「拡張あり」`FilterChip`: `filter.hasExpansionsOnly`をトグル
    - 「未プレイ」`FilterChip`: `filter.unplayedOnly`をトグル
  - 既存のソートチップに「最終プレイ日が古い順」（`CollectionSortOrder.lastPlayed`）を追加
  - `_Subtitle`を編集し、`sortOrder==CollectionSortOrder.lastPlayed || filter.unplayedOnly`のとき、`item.playCount > 0`なら「最終プレイ: {lastPlayedDate}」、`==0`なら「未プレイ」を追加表示する
- 受け入れ基準:
  - [ ] 「メカニクス」「デザイナー」チップから検索付き複数選択ダイアログが開き、選択結果が一覧に反映される
  - [ ] 「拡張あり」「未プレイ」トグルが一覧に反映される
  - [ ] ソートに「最終プレイ日が古い順」が追加され、選択すると一覧の並びが変わる
  - [ ] 「最終プレイ日が古い順」または「未プレイ」のとき、各アイテムに最終プレイ日または「未プレイ」が表示される。それ以外では表示されない
  - [ ] 既存のフィルタチップ・ソートチップ・親子表示の見た目・挙動に変化がない

### T-57 i18n追加・仕上げ
- 内容:
  - `assets/i18n/{ja,en}.json`に要件§6の全キーを追加
  - `flutter analyze`警告ゼロ・`flutter test`全件パス（t01〜t28、および本フェーズで追加したケース）を確認
- 受け入れ基準:
  - [ ] 要件§6の全キーがja/en両方に存在する
  - [ ] `flutter analyze`警告ゼロ、`flutter test`全件パス

---

## 6. 禁止事項・制約

1. **新規の「探す」専用画面を作らない**。既存のコレクション一覧を拡張する。
2. **メカニクス・デザイナーのAND一致モードを実装しない**（OR一致のみ）。
3. **「拡張あり」は1トグルのみ**。「基本のみ」等の追加区分・3区分セレクタは実装しない。
4. **「最近遊んでいない」を日数しきい値フィルタとして実装しない**。`CollectionSortOrder.lastPlayed`で代替する。
5. **既存の絞り込み・ソート・親子表示・`analyticsProvider`の挙動を変更しない**。
6. **新規依存を追加しない**。
7. UI文言ハードコード禁止（i18nキー経由、ja/en両方に追加）。
8. `play_sessions`/`play_session_expansions`/`games`/`collection`のスキーマ変更は行わない。

---

## 7. 完了の定義（Phase 6-C Done）

- T-54〜T-57の全受け入れ基準がテストおよび目視確認で担保される
- `flutter analyze`警告ゼロ、`flutter test`全件パス
- コレクション一覧で、メカニクス・デザイナー・拡張あり・未プレイの絞り込みと、最終プレイ日が古い順ソートが一通り機能する
- `CollectionListItem.playCount`/`lastPlayedDate`がPhase 6-D（傾向分析）で再利用可能な形で提供されている
- 既存機能（Phase 0〜6-B）に後退が発生しない
