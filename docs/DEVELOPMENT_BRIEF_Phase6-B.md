# Codex用開発文書: Board Game Shelf Phase 6-B（プレイ記録 UI）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase6-B.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底） ③`docs/DEVELOPMENT_BRIEF_Phase6-A.md`（`PlaySessionRepository`の仕様） |
| 対象スコープ | **Phase 6-B**: プレイ記録の追加・参照・削除UI |
| 非対象 | 記録の編集／ゲーム横断の履歴一覧／絞り込み・探す画面／傾向分析／写真添付 |
| 実装エージェント | Codex |
| 前提 | Phase 6-A完了済み（`PlaySessionRepository`、`AppConstants.playRatingMin`等のC-46〜C-49、`test/t26`・`t27`を確認済み）。本フェーズは **T-50** から開始する |

---

## 0. 設計根拠（rationale）

- **記録は基本ゲームの詳細画面に集約**: Phase 6-Aの制約（`play_sessions.gameKey`は`gameKind != 'expansion'`のみ）をUI側でも一貫させる。拡張の詳細画面に独自の記録UIを作ると、Phase 6-Aのバリデーション例外を頻発させるだけなので、案内文のみに留める。
- **追加・削除のみ（編集なし）**: 編集UIは「どの値が未入力で、どの値が意図的にnullか」の区別やフォームの初期値復元など複雑度が増す。v1では削除→再登録で十分とし、スコープを絞る。
- **評価系3項目はドロップダウン**: Phase 6-Aで定めた整数/0.5刻みスケールをそのまま選択肢化できるため、スライダーより実装・テストが容易で、`null`（未評価）も「未評価」という1つの選択肢として自然に扱える。
- **拡張チェックボックスは`findExpansions`の結果のみ**: 入力時点でPhase 6-Aのバリデーション条件（`gameKind=='expansion' && parentGameKey==対象gameKey`）を満たすことが保証されるため、フォーム入力からの`recordSession`で拡張関連のバリデーションエラーが発生しない。

---

## 1. 引き渡し手順（人間向け）

1. 本文書と`REQUIREMENTS_Phase6-B.md`を`docs/`に配置（配置済み）。
2. §2「冒頭プロンプト」をCodexに渡す。
3. Codexは§5のタスクを`T-50`から順に実行し、各完了時に「実装ファイル/テスト結果/受け入れ基準との対応」を報告する。
4. 設計と矛盾が出たら停止して報告する。

## 2. 冒頭プロンプト（Codexへ最初に渡す）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 6-B（プレイ記録UI）を実装します。
docs/REQUIREMENTS_Phase6-B.md と docs/DEVELOPMENT_BRIEF_Phase6-B.md が仕様書です。以下を厳守してください。

1. §5のタスクを T-50 から番号順に実装する。並行着手しない。
2. 記録の編集(Update)機能は実装しない。追加(recordSession)と削除(deleteSession)のみ。
3. 拡張(gameKind=='expansion')の詳細画面には、プレイ記録の入力フォーム・履歴一覧を表示せず、
   案内文(detail.playSessionExpansionNotice)のみを表示する。
4. プレイ記録フォームの「使用した拡張」チェックボックスは、
   AppDatabase.findExpansions(gameKey) の結果のみを選択肢にする。
5. 評価/また遊びたい度/重さの体感は DropdownButtonFormField とし、
   「未評価」(null)を選択肢に含める。範囲はPhase6-AのC-47〜C-49に準拠する。
6. 新規UI文言は assets/i18n/{ja,en}.json の両方に追加する（ハードコード禁止）。
7. game_detail_page.dart の既存セクション（拡張情報・分析・所持メタデータ等）の
   表示・挙動・順序は変更しない。新セクションは「拡張情報」の直後・「分析」の前に追加する。
8. §3 定数（既存 C-01〜49 / 本書 C-50）は変更禁止。曖昧なら質問する。
まず T-50 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-50 | 重さの体感の入力刻み | `playPerceivedWeightStep = 0.5` | プレイ記録フォームの「重さの体感」ドロップダウン選択肢生成 | 要件§4.2 |

---

## 4. リポジトリ構成（追加分）

```
追加/変更ファイル（想定）:
lib/src/
  app/
    providers.dart                 … EDIT: playSessionRepositoryProvider
                                      （Provider<PlaySessionRepository>）、
                                      playSessionListProvider
                                      （FutureProvider.family<List<PlaySessionRecord>, String>）を追加
  core/
    constants.dart                 … EDIT: C-50 (playPerceivedWeightStep) を追加
  ui/
    pages/
      play_session_form_page.dart  … NEW: PlaySessionFormPage
                                      （日付/人数/実時間/拡張チェックボックス/評価系3種/感想/勝者メモ、保存）
      game_detail_page.dart         … EDIT: _PlaySessionSectionを新規追加し、
                                      「拡張情報」直後・「分析」の前に配置
assets/i18n/{ja,en}.json            … EDIT: 要件§5のキーを追加
```

---

## 5. 実装タスク（execution order・T-50〜T-53）

### T-50 i18n追加・Providers追加・定数追加
- 内容:
  - `core/constants.dart`にC-50（`playPerceivedWeightStep = 0.5`）を追加
  - `assets/i18n/{ja,en}.json`に要件§5に列挙した`detail.*`・`play_session.*`の全キーを追加
  - `app/providers.dart`に以下を追加:
    - `playSessionRepositoryProvider = Provider<PlaySessionRepository>((ref) => PlaySessionRepository(database: ref.watch(appDatabaseProvider)))`
    - `playSessionListProvider = FutureProvider.family<List<PlaySessionRecord>, String>((ref, gameKey) => ref.watch(playSessionRepositoryProvider).listForGame(gameKey))`
- 受け入れ基準:
  - [ ] 要件§5の全キーが`ja.json`/`en.json`の両方に存在する
  - [ ] `playSessionRepositoryProvider`/`playSessionListProvider`が定義され、既存の`appDatabaseProvider`を参照する

### T-51 PlaySessionFormPage新規作成
- 内容: `lib/src/ui/pages/play_session_form_page.dart`を新規作成。
  - `class PlaySessionFormPage extends ConsumerStatefulWidget { const PlaySessionFormPage({required this.gameKey}); final String gameKey; }`
  - 状態: `playedDate`（`DateTime`、初期値=本日）、`playerCount`/`actualPlayingTime`（`TextEditingController`、数値）、`rating`/`replayDesire`（`int?`、初期値null）、`perceivedWeight`（`double?`、初期値null）、`notes`/`winnerMemo`（`TextEditingController`）、`selectedExpansionKeys`（`Set<String>`、初期値空）
  - 画面構築:
    - 日付: `ListTile`等で現在の選択日を表示し、タップで`showDatePicker`（`firstDate`は十分過去、`lastDate`は本日または近い将来）
    - プレイ人数/実プレイ時間: `TextField`（`keyboardType: TextInputType.number`）
    - 使用した拡張: `ref.watch(appDatabaseProvider).findExpansions(gameKey)`を`FutureBuilder`で取得し、`CheckboxListTile`を表示。0件なら`play_session.expansionsUsedNone`
    - 評価/また遊びたい度/重さの体感: `DropdownButtonFormField<int?>`/`DropdownButtonFormField<double?>`。先頭に`play_session.unset`（値`null`）、続けてC-47/C-48/C-49（＋C-50刻み）に基づく選択肢
    - 感想メモ/勝者メモ: `TextField`（`maxLines`複数）
  - 保存処理:
    1. `playedDate`を`'YYYY-MM-DD'`形式の文字列に変換（例: `playedDate.toIso8601String().substring(0, 10)`）
    2. `playerCount`/`actualPlayingTime`は`int.tryParse`し、空欄や不正値は`null`として扱う
    3. `PlaySessionInput`を構築し`ref.read(playSessionRepositoryProvider).recordSession(input)`を呼ぶ
    4. 成功時: `play_session.saved`をスナックバー表示し、`ref.invalidate(playSessionListProvider(widget.gameKey))`した上で`Navigator.pop`
    5. `PlaySessionValidationException`発生時: メッセージに応じて`play_session.invalidDate`（日付関連）または`play_session.validationError`（その他）を表示し、画面に留まる
- 受け入れ基準:
  - [ ] フォームを開くと日付が本日に初期化されている
  - [ ] 登録済み拡張がある基本ゲームでは、その拡張がチェックボックスとして表示され、複数選択できる
  - [ ] 登録済み拡張が0件の場合、`play_session.expansionsUsedNone`が表示される
  - [ ] 評価/また遊びたい度/重さの体感を「未評価」のまま保存すると、`PlaySessionInput`の該当フィールドが`null`になる
  - [ ] 保存に成功すると`play_session.saved`が表示され、前の画面に戻る

### T-52 GameDetailPageへの「プレイ記録」セクション追加
- 内容: `game_detail_page.dart`に`_PlaySessionSection`（`ConsumerWidget`）を新規追加し、`_ExpansionInfoSection`の直後・`_AnalysisSection`の前に配置する。
  - `game.gameKind == AppConstants.gameKindExpansion`の場合:
    - `Card`内に`detail.playSessionsTitle`（タイトル）と`detail.playSessionExpansionNotice`（案内文）のみを表示する
  - それ以外の場合:
    - `ref.watch(playSessionListProvider(game.gameKey))`を`when`で処理
    - `data: (records)`:
      - `records.isEmpty`なら`detail.noPlaySessions`
      - それ以外:
        - `detail.playSessionCount`（`{count: records.length}`）を表示
        - 全記録の`expansionGameKeys`を集約し重複除去した上で`AppDatabase.findGame`を1回ずつ呼び、gameKey→表示名の`Map<String, String>`を構築（`Future.wait`等で並行取得してよい）
        - 各記録を`ListTile`等で表示: 日付、プレイ人数/実プレイ時間（あれば）、評価/また遊びたい度/重さの体感（あれば）、使用拡張名（Mapを参照、あれば）、感想メモ（あれば）、勝者メモ（あれば）、削除アイコン
        - 削除アイコン押下時、`play_session.deleteConfirmTitle`/`play_session.deleteConfirmBody`の確認ダイアログ→確認後`ref.read(playSessionRepositoryProvider).deleteSession(id)`→`play_session.deleted`表示→`ref.invalidate(playSessionListProvider(game.gameKey))`
    - セクション末尾に`detail.addPlaySession`ボタン。押下で`PlaySessionFormPage(gameKey: game.gameKey)`へ`push`し、戻り後`ref.invalidate(playSessionListProvider(game.gameKey))`
- 受け入れ基準:
  - [ ] 拡張の詳細画面では案内文のみが表示され、入力フォーム・履歴一覧・追加ボタンは表示されない
  - [ ] 基本ゲームの詳細画面で、記録0件時は`detail.noPlaySessions`、1件以上で`detail.playSessionCount`と各記録が表示される
  - [ ] 「プレイ記録を追加」から`PlaySessionFormPage`に遷移し、保存後に戻ると一覧が更新されている
  - [ ] 削除アイコンから確認ダイアログを経て記録を削除でき、一覧が更新される
  - [ ] 複数記録が同じ拡張を参照していても、拡張名解決のための`findGame`呼び出しは拡張gameKeyの種類数分のみ（記録数分にならない）
  - [ ] 既存の「拡張情報」「分析」「所持メタデータ」セクションの表示・挙動・順序に変化がない

### T-53 仕上げ
- 内容:
  - `flutter analyze`警告ゼロを確認
  - `flutter test`全件パス（t01〜t27）を確認。i18nキーの整合性を検証する既存テストがある場合、新規キーが両言語に存在することを確認
- 受け入れ基準:
  - [ ] `flutter analyze`警告ゼロ
  - [ ] `flutter test`全件パス

---

## 6. 禁止事項・制約

1. **記録の編集(Update)機能を実装しない**。追加・削除のみ。
2. **拡張の詳細画面にプレイ記録の入力フォーム・履歴一覧を表示しない**。案内文のみ。
3. **「使用した拡張」の選択肢を`findExpansions(gameKey)`の結果以外から構成しない**（自由入力・全ゲームからの選択等は行わない）。
4. **既存セクション（拡張情報・分析・所持メタデータ・更新履歴等）の表示・挙動・順序を変更しない**。新セクションは指定位置に追加するのみ。
5. **新規依存を追加しない**（Flutter標準Widget・既存パッケージのみ）。
6. UI文言ハードコード禁止（i18nキー経由、ja/en両方に追加）。
7. `play_sessions`/`play_session_expansions`のスキーマ変更は行わない（Phase 6-Aのまま）。

---

## 7. 完了の定義（Phase 6-B Done）

- T-50〜T-53の全受け入れ基準がテストおよび目視確認で担保される
- `flutter analyze`警告ゼロ、`flutter test`全件パス
- 基本ゲームの詳細画面から、プレイ記録の追加（拡張の複数選択を含む）・履歴一覧表示・削除が一通り行える
- 拡張の詳細画面はプレイ記録について案内文のみを表示する
- 新規UI文言がすべてja/enのi18nファイルに存在する
- 既存機能（Phase 0〜6-A）に後退が発生しない
