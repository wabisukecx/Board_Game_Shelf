# Board Game Shelf 改修ブリーフ：「拡張候補」ダイアログを自動表示から手動アクションへ（Codex向け）

## 前提・対象
- 対象: `C:\Users\tucon\StudioProjects\bg_shelf_scanner`（Flutter / Riverpod / Drift）
- 不具合（UX）: ゲームを検索して一覧に登録するたびに「拡張候補」ダイアログが**ほぼ必ず**表示され、登録フローを毎回中断する。トークン設定・親ゲーム候補解決とは違い、このダイアログは「あれば便利」程度の補助機能であり、登録完了に必須ではないため、強制表示はUXを損ねている。
- 要望: ゲームの検索登録は中断なく完了させ、「拡張（関連ゲーム）を追加する」は独立した別アクションとして、ユーザーが望むときにだけ実行できるようにする。
- 各タスクは独立コミット可能な粒度。既存テストを壊さないこと。各タスク完了時に `flutter analyze` と `flutter test` を実行。

## 重要な背景（調査済みの事実 — これに合わせて実装すること）

### 原因
1. `lib/src/ui/pages/search_registration_page.dart` の `_register()` は、`registerBggId()` の戻り値 `BggRegistrationCreated.expansionCandidates` が非空であれば、無条件で `_showExpansionCandidates()`（i18nキー `expansion.candidatesTitle`＝「拡張候補」）を呼び出している。
2. `expansionCandidates` は `lib/src/data/repo/bgg_registration_repository.dart` の `registerBggId()` 内で、`BggRelationshipSource`（BGGの関係先API）から取得した関連ゲームのうち、まだローカルDBに未登録のものを列挙したリスト。よく知られたゲームはほぼ必ず未登録の関連ゲーム（拡張・Big Box・他言語版など）を持つため、**実質的にほぼ毎回ダイアログが出る**。これを止める設定・スキップ手段は存在しない。
3. このダイアログを抑制・無効化するオプションはなく、`_register()` の中に直接埋め込まれているため、検索登録フローを必ず通過する。

### 登録経路の確認（影響範囲の特定）
他の登録導線も確認したが、いずれも最終的に `search_registration_page.dart` の `SearchRegistrationPage`／`_register()` を経由するか、`expansionCandidates` を参照していないため、**今回直すべき箇所は `search_registration_page.dart`（および呼び出し元の `bgg_registration_repository.dart`）のみ**で十分。
- `shelf_recognition_page.dart`（棚撮影一括登録）: 検出した各候補ごとに `SearchRegistrationPage` を `push` して検索登録させる → 同じ `_register()` を通る。
- `photo_recognition_page.dart`（箱写真認識）: 同様に `SearchRegistrationPage` に遷移するのみ。
- `scan_page.dart`（バーコードスキャン／GameUPC直接登録）: `registerBggId()` を直接呼ぶが、`expansionCandidates`／`parentCandidates` のどちらも参照していない（このダイアログはそもそも出ない経路）。
- `bgg_collection_importer.dart`（BGGコレクション一括取込）: `registerBggId()` を呼ぶが `BggRegistrationCreated` の中身は件数カウントにしか使っていない（ダイアログは出ない経路）。

### 確定仕様（この方針で実装すること）
- ゲームの検索登録（`SearchRegistrationPage._register()`）は、**「拡張候補」ダイアログを自動表示しない**。登録完了後はそのままゲーム詳細画面へ遷移する（親ゲーム候補ダイアログ `_showParentCandidates` は今回の対象外。こちらは登録データの正しさに関わる必須の確認であり、複数候補があるレアケースのみ表示される。残す）。
- 「拡張候補（関連ゲームの追加登録）」機能自体は削除しない。**ゲーム詳細画面から明示的に呼び出せる、独立したアクション**として残す。
- `registerBggId()` は登録のたびに `expansionCandidates` を計算・返却する必要がなくなる（誰も自動表示しないため）。代わりに、ゲーム詳細画面が必要なタイミングで明示的に取得する新メソッドを `BggRegistrationRepository` に用意する。

---

## タスク0: 現状確認（実装前）
`test/t21_bgg_registration_repository_expansion_test.dart` のうち `expansionCandidates` を直接アサートしているテスト（`'registers base game and exposes only unregistered expansion candidates'` と `'uses the explicit relationship source instead of XML link direction'`）を確認し、タスク2の変更でどう移行するかを把握する。

---

## タスク1: `BggRegistrationRepository` のリファクタ
1. `registerBggId()` から `expansionCandidates` の計算（DB登録済み判定込みのフィルタループ）を削除する。`BggRegistrationCreated` から `expansionCandidates` フィールドも削除する（`parentCandidates` は残す）。
2. 削除した「自己ID除外・重複除外・DB未登録のみ」のフィルタロジックは、private ヘルパーとして残しておく（例: `Future<List<NamedBggValue>> _filterUnregisteredCandidates(String selfBggId, List<NamedBggValue> candidates)`）。中身は現行ループと同じ条件でよい。
3. 新規パブリックメソッドを追加する:
   ```dart
   Future<List<NamedBggValue>> fetchExpansionCandidates(String bggId) async {
     final candidates = await _relationshipSource.registrationCandidates(bggId);
     return _filterUnregisteredCandidates(bggId, candidates);
   }
   ```
   - 例外はそのまま投げる（呼び出し側のUIでハンドリングする。タスク4参照）。
   - `fetchParentCandidates`（前回タスクで追加済み）と並ぶ薄いラッパとして実装すること。

---

## タスク2: `search_registration_page.dart` から自動表示を削除
1. `_register()` 内の以下を削除する:
   ```dart
   if (expansionCandidates.isNotEmpty) {
     await _showExpansionCandidates(expansionCandidates);
   }
   ```
   （`switch` の分割代入から `expansionCandidates` も合わせて削除）
2. `_showExpansionCandidates()` メソッド本体はこのファイルから削除し、タスク3で共有ウィジェットへ移す。
3. `_showParentCandidates()`（親ゲーム候補ダイアログ）は変更しない。

---

## タスク3: 「拡張候補」ダイアログを共有ウィジェットへ抽出
1. 新規ファイル `lib/src/ui/widgets/expansion_candidate_dialog.dart` を作成し、`lib/src/ui/widgets/parent_game_candidate_dialog.dart` と同じパターンで、`search_registration_page.dart` から削除した `_showExpansionCandidates()` の内容（候補一覧表示＋各候補に「登録」ボタン）を移植する。
2. シグネチャ例:
   ```dart
   Future<void> showExpansionCandidateDialog({
     required BuildContext context,
     required I18n t,
     required List<NamedBggValue> candidates,
     required Future<void> Function(String bggId) onRegister,
   });
   ```
   - 内部の「登録中」状態管理（`StatefulBuilder`、登録ボタンの無効化、登録成功時にリストから除去、失敗時のエラー表示）は現行の実装を踏襲する。
   - `onRegister` は呼び出し元（`game_detail_page.dart`）が `BggRegistrationRepository.registerBggId()` を呼ぶ形にし、ウィジェット自体はリポジトリに依存しない。
3. i18nキーは既存の `expansion.candidatesTitle` / `expansion.candidatesEmpty` / `expansion.register` / `expansion.closeCandidates` をそのまま使う（新規キー不要）。

---

## タスク4: ゲーム詳細画面に「拡張候補を確認」を追加（`game_detail_page.dart`）
1. `_buildBody()` の既存アクション `Wrap`（`isBgg` のとき「情報更新」「説明を翻訳」が並んでいる箇所）に、新しいボタンを追加する:
   ```dart
   if (isBgg)
     OutlinedButton.icon(
       onPressed: _busy ? null : _checkExpansionCandidates,
       icon: const Icon(Icons.playlist_add),
       label: Text(t.t('expansion.checkCandidates')),
     ),
   ```
2. 新規メソッド `_checkExpansionCandidates()` を追加する:
   - `game.bggId` を使って `BggRegistrationRepository.fetchExpansionCandidates(bggId)` を呼ぶ。
   - 取得成功後、タスク3の `showExpansionCandidateDialog(...)` を表示する。`onRegister` には「`registerBggId(candidateId)` を呼び、成功したら何もしない（ダイアログ内のリストから除去するのみ）」を渡す。
   - ダイアログを閉じたあと `_reload()` を呼び、登録した拡張が画面に反映されるようにする（base gameなら「登録済み拡張」リストに即座に反映される）。
   - 取得時に例外が発生したら `_snack(t.t('search.errorGeneric'))` を表示する（`_chooseParent()` と同じパターン）。
   - `_busy` フラグの扱いも他の非同期処理（`_chooseParent` 等）と揃える。
3. `gameKind` を問わず（base / expansion どちらでも）表示してよい。BGG由来のゲーム（`isBgg`）であれば常に押せる。

---

## タスク5: i18n文言追加（`assets/i18n/ja.json`, `assets/i18n/en.json`）
新規キー1件のみ:
- `expansion.checkCandidates` （例: 「拡張候補を確認」 / "Check expansion candidates"）

既存の `expansion.candidatesTitle` / `expansion.candidatesEmpty` / `expansion.register` / `expansion.closeCandidates` はそのまま流用する。

---

## タスク6: テストの更新・追加
1. `test/t21_bgg_registration_repository_expansion_test.dart`:
   - `'registers base game and exposes only unregistered expansion candidates'` と `'uses the explicit relationship source instead of XML link direction'` は、`registerBggId()` の戻り値ではなく **新規 `fetchExpansionCandidates()`** を直接呼ぶ形に書き換える（期待値・モックデータはそのまま流用できるはず）。
   - `registerBggId()` を呼ぶ他のテストで `BggRegistrationCreated.expansionCandidates` を参照している箇所がないか確認し、フィールド削除に合わせて修正する。
2. `fetchExpansionCandidates()` 単体のテストとして、「自己ID除外」「重複除外」「DB登録済み除外」の3条件を満たすケースを追加する（既存ロジックの移植なので、現行テストの期待値をそのまま新メソッド向けに移せばよい）。
3. 可能であれば、`search_registration_page.dart` の `_register()` がダイアログを表示しなくなったことを確認するwidgetテスト、および `game_detail_page.dart` の新ボタンからダイアログが開くことを確認するwidgetテストを追加する。難しい場合はrepository層のテストで担保し、UI側はタスク7の手動確認に委ねる。

---

## タスク7: 手動確認
1. 検索登録で、拡張を多数持つ有名なベースゲーム（例: 「CATAN」「Dominion」等）を登録し、登録が**ダイアログなしで**完了し、即座にゲーム詳細画面に遷移することを確認する。
2. ゲーム詳細画面の「拡張候補を確認」を押すと、従来と同じ「拡張候補」ダイアログが開き、個別に拡張を登録できることを確認する。登録後、画面の「登録済み拡張」リストに反映されることを確認する。
3. 棚撮影一括登録・箱写真認識経由の登録でも、ダイアログが出ずに登録が完了することを確認する（いずれも内部で同じ `SearchRegistrationPage._register()` を通るため、タスク2の修正で同時に解消されるはず）。
4. 候補が0件のゲーム（マイナーな拡張など）を登録した場合に、「拡張候補を確認」ボタンを押すと `expansion.candidatesEmpty`（「候補はすべて登録済みです。」）が表示されることを確認する。

---

## タスク8: ドキュメント更新（README）
`README.md` / `README.ja.md` の該当箇所を更新:
- ゲーム登録時に「拡張候補」ダイアログは自動表示されなくなった旨。
- 関連ゲーム（拡張など）を追加登録したい場合は、ゲーム詳細画面の「拡張候補を確認」から行う旨。

---

## 実装順序
タスク0（現状確認）→ タスク1（リポジトリ層）→ タスク3（ダイアログ抽出）→ タスク2（自動表示削除）→ タスク5（i18n）→ タスク4（詳細画面ボタン）→ タスク6（テスト）→ タスク7（手動確認）→ タスク8（README）

## 完了条件
- 検索登録（バーコードスキャン・写真認識・棚撮影経由を含む）で「拡張候補」ダイアログが自動表示されなくなり、登録がそのまま完了してゲーム詳細画面に遷移する
- 親ゲーム候補ダイアログ（複数版の自動解決に必要なケース）は従来通り動作する（今回の変更で巻き込んで壊さない）
- ゲーム詳細画面から「拡張候補を確認」で、従来と同じ拡張候補一覧を見て個別に登録できる
- `BggRegistrationCreated` から `expansionCandidates` フィールドが削除され、`registerBggId()` は不要な関係先フェッチ・DB照会を行わなくなる（登録1件あたりの処理が軽くなる）
- 既存テスト（t05, t21, t29 等）が新ロジックに合わせて妥当に更新され、green
- 新規ユニットテストが追加されている（`fetchExpansionCandidates` のフィルタ条件）
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス
- 各タスク独立コミット、メッセージにタスク番号を記載
