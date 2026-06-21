# Board Game Shelf 改修ブリーフ：拡張セットの親ゲーム（基本セット）解決ロジック修正（Codex向け）

## 前提・対象
- 対象: `C:\Users\tucon\StudioProjects\bg_shelf_scanner`（Flutter / Riverpod / Drift）
- 不具合: 拡張ゲームを登録する際、BGGの「拡張元（expandsboardgame）」候補が複数ある場合（例: シリーズに複数版・Big Box・Special Editionなどが存在する場合）、アプリが候補の中から不適切な1件を自動的に親ゲームとして確定してしまい、ユーザーが意図した版（例: 「Dominion: Second Edition」）を選べない。具体例:
  - `Dominion: Intrigue (Second Edition)`（BGG ID 209419）
  - `Dominion: Seaside (Second Edition)`（BGG ID 355958）
  - どちらも「Dominion: Second Edition」（BGG ID 209418）を親ゲームにしたいが、現状は別の候補（無印「Dominion」ID 36218 など）に紐付く、または選択する手段がない。
- 各タスクは独立コミット可能な粒度。既存テストを壊さないこと。各タスク完了時に `flutter analyze` と `flutter test` を実行。

## 重要な背景（調査済みの事実 — これに合わせて実装すること）

### 不具合の原因（コード調査済み）

1. **`lib/src/data/repo/bgg_registration_repository.dart` の `resolveGameKindWithLookup()`** が、拡張アイテムの親ゲームを自動確定するロジックを持つ。
   - 候補は `details.expansionRelationshipLinks`（`bgg_xml_parser.dart` の `_expansionRelationshipLinks()`。XML API `/xmlapi2/thing` の `<link type="boardgameexpansion">` を方向（inbound）問わず全部集めたもの）。
   - 各候補を1件ずつ `api.fetchThing` で再取得し、`itemType == AppConstants.bggCollectionSubtype`（`'boardgame'`）だった**最初の1件**で確定してforループを抜ける。
   - Dominionファミリーのように「無印」「Big Box」「Einsteiger-Bigbox」「Second Edition」「Special Edition」が**全部 subtype=boardgame** であるケースでは、複数の候補が同時に条件を満たす。にもかかわらず最初に見つかった1件で確定してしまうため、意図した版が選ばれるとは限らない。
2. **`search_registration_page.dart` の `_showExpansionCandidates()`**（i18nキー `expansion.candidatesTitle`＝「拡張候補」）は、親ゲーム選択UIではない。これは「BGGの関係先で、まだローカルDBに未登録のゲームをついでに登録できる」機能であり、選んでも今回登録したアイテムの親ゲームには反映されない。
   - `bgg_registration_repository.dart` の `registerBggId()` 内、`expansionCandidates` を組み立てるループは `if (await _database.findGame(candidateId) == null)` の条件で**既にDB登録済みの候補をリストから除外**する。そのため、過去に「Dominion: Second Edition」が一度でも登録されていると、それ以降の同シリーズ拡張の登録時にはこのダイアログから消える。これが「候補に出てこない」と感じる直接的な要因。
3. ゲーム詳細画面（`game_detail_page.dart` の `_ExpansionInfoSection`）は、自動確定された `parentGameKey` を表示するだけで、**後から別候補に張り替える手段がない**。

### 既存テストとの関係（実データを使った既存テストあり）
- `test/t21_bgg_registration_repository_expansion_test.dart` の `'uses the explicit relationship source instead of XML link direction'` は、まさに Dominion（36218）/ Dominion: Second Edition（209418）/ Dominion: Seaside (Second Edition)（355958）という実際のBGG IDを使ったテスト。ただし検証しているのは `expansionCandidates`（＝上記②のダイアログ用リスト）のみで、親ゲーム自動解決（`resolveGameKindWithLookup`）側の「複数候補をどう扱うか」は検証していない。これが今回埋めるべきギャップ。
- `test/t29_bgg_relationship_source_test.dart` の `'uses expandsboardgame links for an expansion item'` も同じID（36218 / 209418）をモックデータに使っており、`expandsboardgame` の並び順は `[Dominion(36218), Dominion: Second Edition(209418)]` という想定になっている。

### 確定仕様（この方針で実装すること）
- 拡張元候補（subtype=boardgame）が **1件のみ** → 従来通り自動確定。ユーザー操作は増やさない（回帰なし）。
- 拡張元候補が **0件** → 従来通りのフォールバック（`resolveGameKind` の単一フォールバック）。
- 拡張元候補が **2件以上** → 自動確定せず、`parentGameKey` は `null` のまま登録し、候補一覧をユーザーに提示して選ばせる。
- 候補ソースは `BggRelationshipSource`（`api.geekdo.com` の `expandsboardgame`。BGGページの「Expands」分類と一致する、最も正確なソース）を優先する。取得に失敗した場合のみ、各呼び出し箇所が現状使っているXML由来のフィールドにフォールバックする（後述タスク2で詳細）。
- 登録時に未確定だった場合は、**ゲーム詳細画面からいつでも「親ゲームを選び直す」で確定・修正できる**。これにより、過去に誤った版へ紐付いた既存データも事後修正できるようにする（DBマイグレーション不要、既存の `parentGameKey` カラムをそのまま使う）。

---

## タスク0: 現状確認（実装前）
`t05_bgg_registration_repository_test.dart` / `t21_bgg_registration_repository_expansion_test.dart` / `t29_bgg_relationship_source_test.dart` を読み、現在のモックパターン（`_FakeBggApi` / `_FakeRelationshipSource`）を把握してから着手する。

---

## タスク1: `GameKindResolution` の拡張とロジック変更（`bgg_registration_repository.dart`）
1. `GameKindResolution` に `parentCandidates`（`List<NamedBggValue>`、デフォルト空リスト）を追加。
2. `resolveGameKindWithLookup()` のシグネチャに `required List<NamedBggValue> relationshipCandidates` を追加し、関数内部で `details.expansionRelationshipLinks` を直接参照する代わりに、この引数を候補ソースとして使う（API呼び出しの一本化はタスク2で行う。この関数自体はAPIを叩かない候補リストを受け取るだけにする）。
3. 候補の確定ロジックを「最初の1件で即returnする」forループから、**全候補をチェックして `subtype=boardgame` のものを全部集めてから判定する**形に変更する:
   - 確定候補が0件 → 既存の `fallback`（`resolveGameKind(details)`）を返す。
   - 確定候補が1件 → 従来通り `GameKindResolution(gameKind: expansion, parentGameKey: <そのID>)`（`parentCandidates` は空のまま）。
   - 確定候補が2件以上 → `GameKindResolution(gameKind: expansion, parentGameKey: null, parentCandidates: <確定候補のリスト>)`。
4. 各候補に対する `api.fetchThing` での subtype 検証自体は変更しない（Nucleumのような「expandsboardgame関係に紛れ込む別の拡張アイテム」を弾く既存の安全策のため、`t21` の `'prefers fetched boardgame candidate as parent for ambiguous expansion links'` を壊さないこと）。

---

## タスク2: `registerBggId()` の候補取得を1本化（`bgg_registration_repository.dart`）
現状、`registerBggId()` 内では `_relationshipSource.registrationCandidates()` を「親ゲーム解決の後・DB upsert後」に1回呼んで `expansionCandidates`（ダイアログ用）だけに使っている。これを以下のように組み替える。

1. `_validateDetails(details)` の直後で `_relationshipSource.registrationCandidates(details.bggId)` を**1回だけ**呼ぶ。
2. 成功した場合は、その結果を①親ゲーム解決（タスク1の `relationshipCandidates` 引数）と②拡張候補ダイアログ用リストの**両方**に使い回す（再フェッチしない）。
3. 失敗（例外）した場合は、**現状の挙動を変えない**。具体的には:
   - 親ゲーム解決用のフォールバックは `details.expansionRelationshipLinks`（現状 `resolveGameKindWithLookup` が直接参照していたフィールド）を使う。
   - 拡張候補ダイアログ用のフォールバックは `details.expansionLinks`（現状の `var candidateLinks = details.expansionLinks;` のまま）を使う。
   - この2つは意味が異なる（前者は方向問わずの拡張関係リンク、後者はinbound＝このアイテム自身の子拡張）ので、**1つの変数に統合しないこと**。relationshipSourceが成功したときだけ両者を同じ値で共有し、失敗時は呼び出し箇所ごとに個別のXMLフィールドへフォールバックする。
4. `resolveGameKindWithLookup` の呼び出しに、上記で決定した候補リストを `relationshipCandidates:` として渡す。
5. `kind.parentCandidates` が非空の場合、`BggRegistrationCreated` に `parentCandidates: kind.parentCandidates` を持たせて返す（タスク3）。

---

## タスク3: 戻り値の型拡張
`BggRegistrationCreated` に `parentCandidates: List<NamedBggValue>`（デフォルト空）フィールドを追加する。既存の `expansionCandidates`（関連ゲームの追加登録候補）とは明確に別フィールドにし、混同しないようにする。

---

## タスク4: 親ゲーム更新・再取得用のAPI追加
1. `AppDatabase`（`lib/src/data/db/app_database.dart`）に `Future<void> updateParentGameKey(String gameKey, String? parentGameKey)` を、既存の `updateDescriptionJa` と同じパターンで追加する。スキーマ変更は不要（既存の `parentGameKey` カラムを使う）。
2. `BggRegistrationRepository` に以下を追加する:
   - `Future<void> setParentGameKey(String gameKey, String parentGameKey)` — 内部で `_database.updateParentGameKey` を呼ぶ薄いラッパ。
   - `Future<List<NamedBggValue>> fetchParentCandidates(String bggId)` — 内部で `_relationshipSource.registrationCandidates(bggId)` を呼ぶだけの薄いラッパ。例外はそのまま投げ、UI側でハンドリングする（ゲーム詳細画面から「選び直す」際に使う。タスク6）。

---

## タスク5: 登録直後の「親ゲーム候補」選択ダイアログ（`search_registration_page.dart`）
1. `_register()` 内、`BggRegistrationCreated` を受け取った後、`parentCandidates` が非空なら新規ダイアログを表示する。既存の `_showExpansionCandidates`（拡張候補＝追加登録用、i18nキー `expansion.candidatesTitle`）とは**完全に別のダイアログ・別の文言**にする（タスク7で新規i18nキーを用意）。
2. ダイアログ仕様:
   - 各候補に「これに決定」ボタン。押すと `setParentGameKey(forGameKey, candidateId)` を呼ぶ。選んだ候補がローカル未登録の場合は、決定後に続けて親ゲーム登録を促す（既存の `_registerParent` 相当の動線を流用してよい）。
   - 「あとで決める」ボタンで閉じられる。`parentGameKey` は `null` のままにし、ゲーム詳細画面でいつでも選び直せるようにする（タスク6）。
3. `parentCandidates` と `expansionCandidates` が両方非空の場合（理論上は稀）は、親ゲーム候補ダイアログを先に表示し、閉じてから拡張候補ダイアログを表示する。

---

## タスク6: ゲーム詳細画面に「親ゲームを選び直す」を追加（`game_detail_page.dart`）
1. `_ExpansionInfoSection`（`game.gameKind == AppConstants.gameKindExpansion` の分岐）に、親が確定済み・未確定（`parentGameKey == null`）のどちらの場合でも常時表示される「親ゲームを選び直す」ボタンを追加する。
2. 押すと `fetchParentCandidates(game.bggId!)` を呼び、タスク5と同じ選択UIを表示する（共通化推奨: 選択ダイアログをウィジェット/関数として切り出し、`search_registration_page.dart` と `game_detail_page.dart` の両方から呼べるようにする）。
3. 選択結果で `setParentGameKey` を呼び、画面を再読み込みする（既存の `_reload()` 相当）。
4. `parentGameKey` が `null` の状態（未確定）を表示する文言を追加する（既存の「親ゲームは未登録です（BGG ID: {id}）」はIDがある前提のため、IDなしの「未確定」用に別文言が必要。タスク7）。

---

## タスク7: i18n文言追加（`assets/i18n/ja.json`, `assets/i18n/en.json`）
新規キー（既存 `expansion.*` と衝突しない命名にする。文言は以下を参考に、ja/en両方に追加すること）:
- `expansion.parentCandidatesTitle` （例:「親ゲーム候補」）
- `expansion.parentCandidatesBody` （例:「該当する版を選んでください」）
- `expansion.parentChoose` （例:「これに決定」）
- `expansion.parentDecideLater` （例:「あとで決める」）
- `expansion.parentUndetermined` （例:「親ゲーム未確定」）
- `expansion.changeParent` （例:「親ゲームを選び直す」）
- `expansion.parentUpdated` （例:「親ゲームを更新しました」）

---

## タスク8: ユニットテスト追加
1. `test/t21_bgg_registration_repository_expansion_test.dart` に追加:
   - 「拡張元候補が2件（ともに `fetchThing` 後に subtype=boardgame と判定される）→ `parentGameKey` は `null`、`parentCandidates` に2件とも含まれる」ケース。`Dominion`(36218) / `Dominion: Second Edition`(209418) / `Dominion: Seaside (Second Edition)`(355958) の組み合わせで、既存テストのIDに揃えて書く。
   - 既存の「候補1件→自動確定」「候補0件→base」「Nucleumのambiguousケース」が新ロジックでも green であることを確認する（シグネチャ変更に伴う呼び出し側の修正は必要だが、期待値は変えない）。
2. `AppDatabase.updateParentGameKey` のDBレベルテスト（`t02_database_test.dart` または新規ファイルに追加）。
3. 可能であれば、新ダイアログ（`search_registration_page.dart` / `game_detail_page.dart`）のwidgetテストを追加する。難しい場合はrepository層のテストで担保し、UI側はタスク9の手動確認に委ねる。

---

## タスク9: 手動確認
1. BGGトークン設定済み環境で、実際に `Dominion: Intrigue (Second Edition)`（BGG ID 209419）と `Dominion: Seaside (Second Edition)`（BGG ID 355958）を検索登録し、「親ゲーム候補」ダイアログで `Dominion: Second Edition`（BGG ID 209418）を選択できること、選択後にゲーム詳細画面で正しく親ゲームとして表示されることを確認する。
2. 拡張元候補が1件しかない通常の拡張を登録し、従来通りダイアログなしで自動確定されることを確認する（回帰なし）。
3. 既に誤った親に紐付いている既存ゲームがあれば、「親ゲームを選び直す」から修正できることを確認する。

---

## タスク10: ドキュメント更新（README）
`README.md` / `README.ja.md` に1〜2文追記:
- 拡張ゲームの親ゲーム（基本セット）候補が複数ある場合（同一シリーズに複数版が存在する場合など）は、登録時、またはゲーム詳細画面の「親ゲームを選び直す」から手動で選択できる。

---

## 実装順序
タスク0（現状確認）→ タスク1〜4（ロジック・データ層）→ タスク7（i18n）→ タスク5・6（UI）→ タスク8（テスト）→ タスク9（手動確認）→ タスク10（README）

## 完了条件
- 拡張元候補（subtype=boardgame）が複数ある場合、自動確定されず、登録直後またはゲーム詳細画面からユーザーが選択できる
- 候補が1件のみの通常の拡張は、従来通り自動確定され、ユーザー操作は増えない（回帰なし）
- `Dominion: Intrigue (Second Edition)` / `Dominion: Seaside (Second Edition)` について、`Dominion: Second Edition` を親ゲームとして選択・保存できる
- 既存テスト（t05, t21, t29 等）が green のまま、または新ロジックに合わせて妥当に更新されている
- 新規ユニットテストが追加されている（候補2件以上のケース、`updateParentGameKey` のケース）
- 「拡張候補」（関連ゲーム追加登録）ダイアログと「親ゲーム候補」（親ゲーム選択）ダイアログが文言・機能ともに明確に区別されている
- 既存の誤った親紐付けを、ゲーム詳細画面から事後修正できる
- 各タスク独立コミット、メッセージにタスク番号を記載
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス
