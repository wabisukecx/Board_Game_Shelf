# Codex用開発文書: Board Game Shelf Phase 6-A（プレイ記録 DB・Repository）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase6-A.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底） ③`docs/DEVELOPMENT_BRIEF_Phase5.md`（拡張親子構造・gameKind/parentGameKeyの参照） |
| 対象スコープ | **Phase 6-A**: プレイ記録のDBスキーマとRepository（UIなし） |
| 非対象 | プレイ記録UI／探す画面・絞り込み拡充／傾向分析／プレイヤー別スコア構造化／写真添付 |
| 実装エージェント | Codex |
| 前提 | Phase 0〜5完了済み（`games.gameKind`/`parentGameKey`、`schemaVersion=6`、`test/t20〜t25`を確認済み）。本フェーズは **T-46** から開始し、`schemaVersion`は6→7とする |

---

## 0. 設計根拠（rationale）

- **評価系スケールの既存BGGスケールへの統一**: `rating`（1-10）は`games.averageRating`（BGGの10点満点）、`perceivedWeight`（1.0-5.0）は`games.weight`（BGGの重さ1-5）と同尺度にする。これにより、Phase 6-Dで「自分の評価とBGG平均の差」「体感重さとBGG weightの差」を変換なしで比較できる。
- **`play_sessions`は基本ゲーム限定**: 拡張は「このプレイで使った拡張」として`play_session_expansions`に複数記録する設計のため、`play_sessions.gameKey`自体が拡張を指すことは許可しない。これにより「基本ゲーム1件＋使用拡張N件」という記録モデルが一貫する。
- **勝者・スコアは`winnerMemo`の自由記述のみ**: プレイヤー管理・スコア集計はデータモデルの複雑度を大きく増すため、v1では構造化しない。将来必要になれば別テーブルとして追加できるよう、`play_sessions`に専用カラムを設けるだけに留める。
- **新テーブル2つの追加のみで既存データへの影響なし**: schemaVersion 6→7のマイグレーションは`CREATE TABLE`相当の追加のみとし、既存カラムの変更・削除は行わない。

---

## 1. 引き渡し手順（人間向け）

1. 本文書と`REQUIREMENTS_Phase6-A.md`を`docs/`に配置（配置済み）。
2. §2「冒頭プロンプト」をCodexに渡す。
3. Codexは§5のタスクを`T-46`から順に実行し、各完了時に「実装ファイル/テスト結果/受け入れ基準との対応」を報告する。
4. 設計と矛盾が出たら停止して報告する。

## 2. 冒頭プロンプト（Codexへ最初に渡す）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 6-A（プレイ記録のDB・Repository）を実装します。
docs/REQUIREMENTS_Phase6-A.md と docs/DEVELOPMENT_BRIEF_Phase6-A.md が仕様書です。以下を厳守してください。

1. §5のタスクを T-46 から番号順に実装する。並行着手しない。
2. 本フェーズはUIを実装しない（詳細画面・履歴一覧・入力フォーム等はPhase 6-Bで対応）。
3. play_sessions の対象は gameKind != 'expansion' のゲームのみ。
   expansionGameKeys の各要素は gameKind == 'expansion' && parentGameKey == 対象gameKey であることを検証する。
4. 評価(rating)=1-10, また遊びたい度(replayDesire)=1-5, 重さの体感(perceivedWeight)=1.0-5.0
   の範囲チェックを行う（§3の定数C-46〜C-49を使用）。
5. schemaVersion を 6 から 7 に上げ、play_sessions / play_session_expansions の
   CREATE TABLE 相当のマイグレーションのみを追加する（既存カラムの変更・削除は行わない）。
6. ゲーム削除時のカスケード（§5 T-49参照）を実装し、既存の collection_repository.dart の
   deleteGame / deleteRequirement を拡張する。
7. 新規依存を追加しない（drift既存のみ）。
8. §3 定数（既存 C-01〜45 / 本書 C-46〜49）は変更禁止。曖昧なら質問する。
まず T-46 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-46 | DBスキーマバージョン | 6 → 7 | `AppDatabase.schemaVersion` | 要件§4.1/4.2 |
| C-47 | 評価スケール | `playRatingMin = 1` / `playRatingMax = 10` | `play_sessions.rating`の範囲チェック | 要件§4.3 |
| C-48 | また遊びたい度スケール | `playReplayDesireMin = 1` / `playReplayDesireMax = 5` | `play_sessions.replayDesire`の範囲チェック | 要件§4.3 |
| C-49 | 重さの体感スケール | `playPerceivedWeightMin = 1.0` / `playPerceivedWeightMax = 5.0` | `play_sessions.perceivedWeight`の範囲チェック | 要件§4.3 |

---

## 4. リポジトリ構成（追加分）

```
追加/変更ファイル（想定）:
lib/src/
  data/
    db/
      app_database.dart            … EDIT: PlaySessions/PlaySessionExpansionsテーブル追加、
                                      schemaVersion 7、migration追加（CREATE TABLE相当のみ）、
                                      play_sessions_game_key_idx インデックス追加
      app_database.g.dart          … EDIT(自動生成): build_runner再実行
    repo/
      play_session_repository.dart  … NEW: PlaySessionRepository
                                      （recordSession/listForGame/deleteSession/countForGame、
                                      PlaySessionInput/PlaySessionRecord/PlaySessionValidationException）
      collection_repository.dart    … EDIT: deleteGame/deleteRequirementにプレイ記録の
                                      カスケード削除・確認要件を追加
  core/
    constants.dart                  … EDIT: C-46〜C-49を追加
test/
  t26_play_session_repository_test.dart … NEW: PlaySessionRepositoryの単体テスト
  t27_database_migration_v7_test.dart   … NEW: schemaVersion 6→7マイグレーション
  t07_collection_repository_test.dart   … EDIT: 削除カスケード・deleteRequirementの
                                      プレイ記録チェックを追加
```
（テスト番号は既存の最終番号(t25)＋1から連番。）

---

## 5. 実装タスク（execution order・T-46〜T-49）

### T-46 スキーマ追加（play_sessions / play_session_expansions）
- 内容:
  - `core/constants.dart`にC-46〜C-49（評価スケール3種＋schemaVersion）を追加
  - `app_database.dart`に以下のテーブルを追加:
    - `PlaySessions`（tableName `play_sessions`）: `id`（INTEGER, autoIncrement, PK）、`gameKey`（TEXT, references Games.gameKey）、`playedDate`（TEXT）、`playerCount`（INTEGER, nullable）、`actualPlayingTime`（INTEGER, nullable）、`notes`（TEXT, nullable）、`rating`（INTEGER, nullable）、`replayDesire`（INTEGER, nullable）、`perceivedWeight`（REAL, nullable）、`winnerMemo`（TEXT, nullable）、`createdAt`（DATETIME, withDefault currentDateAndTime）
    - `@TableIndex(name: 'play_sessions_game_key_idx', columns: {#gameKey})`を`PlaySessions`に付与
    - `PlaySessionExpansions`（tableName `play_session_expansions`）: `playSessionId`（INTEGER, references PlaySessions.id）、`expansionGameKey`（TEXT, references Games.gameKey）。複合主キー`{playSessionId, expansionGameKey}`
  - `@DriftDatabase`の`tables`リストに両テーブルを追加
  - `schemaVersion`を6→7（C-46）に変更し、`migration.onUpgrade`に`if (from < 7) { await m.createTable(playSessions); await m.createTable(playSessionExpansions); }`を追加
- 受け入れ基準:
  - [ ] `flutter pub run build_runner build`相当の生成が成功し、`app_database.g.dart`に両テーブルが反映される
  - [ ] schemaVersion6のDBをschemaVersion7に開き直すと、エラーなく両テーブルが作成され、既存テーブルのデータは変化しない

### T-47 PlaySessionRepository実装
- 内容: `lib/src/data/repo/play_session_repository.dart`を新規作成。
  - `PlaySessionInput`: `gameKey`/`playedDate`（必須）、`playerCount`/`actualPlayingTime`/`notes`/`rating`/`replayDesire`/`perceivedWeight`/`winnerMemo`（nullable）、`expansionGameKeys`（`List<String>`, 既定`const []`）
  - `PlaySessionRecord`: `id`/`gameKey`/`playedDate`/`playerCount`/`actualPlayingTime`/`notes`/`rating`/`replayDesire`/`perceivedWeight`/`winnerMemo`/`createdAt`/`expansionGameKeys`
  - `PlaySessionValidationException implements Exception`（メッセージは英語固定文字列）
  - `class PlaySessionRepository { PlaySessionRepository({required AppDatabase database}); ... }`
  - `Future<int> recordSession(PlaySessionInput input)`:
    1. `database.findGame(input.gameKey)`を取得し、null または `gameKind == AppConstants.gameKindExpansion` なら`PlaySessionValidationException`
    2. `DateTime.tryParse(input.playedDate) == null` なら`PlaySessionValidationException`
    3. `rating`/`replayDesire`/`perceivedWeight`が非nullのとき、C-47〜C-49の範囲外なら`PlaySessionValidationException`
    4. `input.expansionGameKeys`の各要素について`database.findGame(key)`を取得し、`gameKind == AppConstants.gameKindExpansion && parentGameKey == input.gameKey`を満たさない要素が1件でもあれば`PlaySessionValidationException`（1件目で即時例外、部分挿入は行わない）
    5. トランザクションで`play_sessions`に1行挿入し、生成された`id`で`play_session_expansions`に`expansionGameKeys`件数分の行を挿入。`id`を返す
  - `Future<List<PlaySessionRecord>> listForGame(String gameKey)`:
    - `play_sessions`を`gameKey`で絞り込み、`playedDate`降順・同値は`id`降順でソート
    - 各行について`play_session_expansions`から`expansionGameKey`一覧を取得し`PlaySessionRecord.expansionGameKeys`に設定
  - `Future<void> deleteSession(int id)`:
    - トランザクションで`play_session_expansions`（`playSessionId == id`）と`play_sessions`（`id == id`）を削除
  - `Future<int> countForGame(String gameKey)`:
    - `play_sessions`を`gameKey`で絞り込んだ件数を返す
- 受け入れ基準:
  - [ ] 基本ゲームへの`recordSession`が成功し、正の`id`が返る
  - [ ] `gameKind=='expansion'`のgameKey、または存在しないgameKeyへの`recordSession`は`PlaySessionValidationException`
  - [ ] `rating`/`replayDesire`/`perceivedWeight`が範囲外のとき`PlaySessionValidationException`、範囲内・未指定では成功する
  - [ ] `expansionGameKeys`に「対象基本ゲームの拡張ではないgameKey」を含めると`PlaySessionValidationException`になり、`play_sessions`/`play_session_expansions`に行が残らない（ロールバックされる）
  - [ ] `listForGame`が`playedDate`降順で返り、各記録の`expansionGameKeys`が正しい
  - [ ] `deleteSession`で`play_sessions`と対応する`play_session_expansions`が削除される
  - [ ] `countForGame`が正しい件数を返す

### T-48 ゲーム削除時のカスケード・確認要件
- 内容: `collection_repository.dart`を拡張。
  - `deleteRequirement(gameKey)`: 既存の`_hasUserMetadata`チェックに加え、`play_sessions`に`gameKey`一致行が1件以上存在する場合も`DeleteRequirement.confirmationRequired`を返す
  - `deleteGame(gameKey, {confirmed})`:
    - 既存処理（`collectionEntries`/`games`の削除）の前に、
      1. `play_session_expansions`から`expansionGameKey == gameKey`の行を削除
      2. 対象が基本ゲーム（`gameKind != 'expansion'`）の場合、`play_sessions`から`gameKey == gameKey`の行と、それらの`id`に対応する`play_session_expansions`の行を削除
    - 上記をすべて1トランザクション内で実行する
- 受け入れ基準:
  - [ ] プレイ記録が存在する基本ゲームの`deleteRequirement`は`confirmationRequired`を返す
  - [ ] プレイ記録のない基本ゲーム・拡張の`deleteRequirement`は既存どおり（既存の所持メタデータ条件のみで判定）
  - [ ] 基本ゲームを`deleteGame(confirmed: true)`した場合、紐づく`play_sessions`/`play_session_expansions`が削除される
  - [ ] ある拡張を使用したプレイ記録がある状態でその拡張を削除すると、`play_sessions`本体は残り、当該拡張への`play_session_expansions`参照のみ削除される

### T-49 テスト整備・仕上げ
- 内容:
  - `test/t26_play_session_repository_test.dart`: T-47の受け入れ基準をカバー
  - `test/t27_database_migration_v7_test.dart`: schemaVersion 6→7マイグレーションで両テーブルが作成され、既存テーブルのデータが変化しないことを確認
  - `test/t07_collection_repository_test.dart`: T-48の受け入れ基準をカバーするケースを追加
  - `flutter analyze`警告ゼロ・`flutter test`全件パス（t01〜t27）を確認
- 受け入れ基準:
  - [ ] 上記3テストファイルが追加/更新され、全件パスする
  - [ ] `flutter analyze`警告ゼロ

---

## 6. 禁止事項・制約

1. **本フェーズでUIを実装しない**（詳細画面・履歴一覧・入力フォーム・i18nキー追加はPhase 6-B）。
2. **`play_sessions.gameKey`に拡張（`gameKind=='expansion'`）を許可しない**。拡張は必ず`play_session_expansions`経由。
3. **プレイヤー別スコア・勝敗の構造化テーブルを追加しない**（`winnerMemo`の自由記述のみ）。
4. **既存カラムの変更・削除を行わない**。schemaVersion 6→7は新テーブル追加のみ。
5. **新規依存を追加しない**（drift既存のみ）。
6. バリデーション失敗時は部分書き込みを残さない（トランザクションでロールバック）。
7. テストは時計・乱数・ネットワークに依存させない（`createdAt`はDB既定値`currentDateAndTime`を使用し、テストでは値そのものの厳密一致ではなく存在確認・相対順序の確認に留める）。

---

## 7. 完了の定義（Phase 6-A Done）

- T-46〜T-49の全受け入れ基準がテストで担保され、`flutter test`が全件成功する
- `flutter analyze`警告ゼロ
- schemaVersion7への移行が既存DBに対してエラーなく動作し、既存データに影響がない
- `PlaySessionRepository`が要件§5の4メソッドを提供し、バリデーション（基本ゲーム限定・拡張の親子関係・評価系スケール範囲）が機能する
- ゲーム削除時にプレイ記録が適切にカスケード削除・確認要件に反映される
- 既存テスト（t01〜t25）に後退が発生しない
