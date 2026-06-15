# 要件定義書: Board Game Shelf Phase 6-A（プレイ記録 DB・Repository）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-14 |
| 位置づけ | Phase 0〜5（所持管理・登録基盤・拡張管理）完了後の新規系列「Phase 6: プレイを起点とした活用」の最初の段階。プレイ記録を保存するDB/Repositoryのみを整備する |
| 前提 | リポジトリ確認の結果、Phase 5実装済み（`games.gameKind`/`parentGameKey`、`schemaVersion=6`、`test/t20〜t25`等が存在）。本フェーズはこの上に積む。`flutter analyze`/`flutter test`は着手前に実行・確認すること |
| 後続 | Phase 6-B（プレイ記録UI）／Phase 6-C（遊ぶゲームを探す画面・絞り込み拡充）／Phase 6-D（プレイ傾向分析） |

---

## 1. 目的・背景

これまでのPhase 0〜5で「所持管理」と「BGG登録基盤」（メカニクス・デザイナー・拡張親子構造を含む）はかなり整っている。次に伸ばすべき中心は、①持っているゲームの中から「今日遊ぶゲームを選ぶ」ための絞り込み（Phase 6-C）と、②実際に遊んだ記録を残し振り返る「プレイ記録」（Phase 6-B）、さらにそれらを束ねる③傾向分析（Phase 6-D）である。これらはすべて「プレイ記録」という1つのデータソースに依存するため、最初にこのデータモデルとRepositoryを固めるのがPhase 6-Aの目的である。

### 1.1 設計の前提

- **評価系スケールは既存のBGGスケールに揃える**。
  - 「評価」は1〜10（BGGの総合評価と同じ尺度。将来、自分の評価とBGG平均評価を比較分析できるようにするため）
  - 「重さの体感」は1.0〜5.0（`games.weight`＝BGGの重さと同じ尺度。体感重さとBGG weightの差を後で分析できるようにするため）
  - 「また遊びたい度」は1〜5の5段階（独自スケールだが、上記2項目と桁を揃えたシンプルな尺度とする）
- **`play_sessions`の対象ゲームは基本ゲーム限定**。`games.gameKind == 'expansion'`のgameKeyに対するプレイ記録の作成はRepository層でエラーとする。拡張の詳細画面からプレイ記録を案内する際は「基本ゲームの詳細画面から記録してください」という導線になる想定だが、その導線（UI）自体はPhase 6-Bで対応する。
- **拡張は「このプレイで使用した拡張」として複数選択で記録する**。`play_session_expansions`で1プレイ記録に対し複数の拡張gameKeyを関連付ける。各拡張gameKeyは、記録対象の基本ゲームの拡張（`gameKind=='expansion' && parentGameKey==当該gameKey`）であることをRepository層で検証する。
- **勝者・スコアは構造化しない**。`winnerMemo`という自由記述の任意フィールド1つに留める。プレイヤー別のスコア・勝敗を構造化して記録・集計する機能はOut of Scope（将来別フェーズで検討）。
- **新規依存は追加しない**（drift既存のみ）。

---

## 2. スコープ

### 2.1 含むもの（In Scope）

- FR-6A-01 `play_sessions`テーブルの追加（schemaVersion 6→7・マイグレーション）。日付・人数・実プレイ時間・感想メモ・評価・また遊びたい度・重さの体感・勝者メモを保持
- FR-6A-02 `play_session_expansions`テーブルの追加。1プレイ記録に対し、使用した拡張gameKeyを複数関連付ける（複合主キー）
- FR-6A-03 `PlaySessionRepository`の新規実装: `recordSession`（記録作成）・`listForGame`（ゲーム別の履歴一覧）・`deleteSession`（記録削除）・`countForGame`（プレイ回数取得）
- FR-6A-04 評価（1-10）・また遊びたい度（1-5）・重さの体感（1.0-5.0）のスケールを定数化し、範囲外の値は`recordSession`でエラーとする
- FR-6A-05 `expansionGameKeys`の各要素について、記録対象の基本ゲームの拡張であることを検証する（無関係なgameKeyの混入を防ぐ）
- FR-6A-06 ゲーム削除時の整合性確保: 基本ゲーム削除時に紐づく`play_sessions`/`play_session_expansions`をカスケード削除し、`CollectionRepository.deleteRequirement`にプレイ記録の存在チェックを追加する

### 2.2 含まないもの（Out of Scope）

- プレイ記録の追加・編集・履歴一覧などのUI（詳細画面からの導線含む）→ Phase 6-B
- 人数・時間・メカニクス・デザイナー・拡張込み可否・未プレイ等での「探す」画面・フィルタ拡充 → Phase 6-C
- デザイナー別/メカニクス別の集計、評価傾向、実プレイ時間とBGG公称時間の差分analytics等 → Phase 6-D
- プレイヤー別スコア・勝敗の構造化記録・集計
- 写真添付
- 「最近遊んでいない」の判定ロジック・しきい値設計（6-Cで検討）

---

## 3. 対象・非機能要件

| 項目 | 方針 |
|---|---|
| 依存 | 追加なし（drift既存のみ） |
| データ | 新テーブル2つを追加するのみ。既存`games`/`collection`テーブルへの変更はなし |
| i18n | 本フェーズはUIを含まないため対象外。Repositoryの例外メッセージは英語の固定文字列でよい（UI文言化はPhase 6-B） |
| 後方互換 | schemaVersion7への移行は新テーブル追加のみで、既存データに影響しない |

---

## 4. データモデル仕様

### 4.1 `play_sessions`テーブル

| カラム | 型 | 制約/既定値 | 説明 |
|---|---|---|---|
| `id` | INTEGER | PK, autoIncrement | プレイ記録ID |
| `gameKey` | TEXT | FK → `games.gameKey` | 遊んだ基本ゲーム（`gameKind != 'expansion'`） |
| `playedDate` | TEXT | 必須、`DateTime.parse`可能な形式（`YYYY-MM-DD`） | 遊んだ日 |
| `playerCount` | INTEGER | nullable | プレイ人数 |
| `actualPlayingTime` | INTEGER | nullable（分） | 実プレイ時間 |
| `notes` | TEXT | nullable | 感想メモ |
| `rating` | INTEGER | nullable、1〜10 | 評価（BGG準拠スケール） |
| `replayDesire` | INTEGER | nullable、1〜5 | また遊びたい度 |
| `perceivedWeight` | REAL | nullable、1.0〜5.0 | 重さの体感（`games.weight`準拠スケール） |
| `winnerMemo` | TEXT | nullable | 勝者・スコア等の自由記述 |
| `createdAt` | DATETIME | 既定値 `currentDateAndTime` | 記録作成日時（同日複数記録の並び順に使用） |

`gameKey`に対するインデックス（`play_sessions_game_key_idx`）を追加し、`listForGame`/`countForGame`の検索効率を確保する。

### 4.2 `play_session_expansions`テーブル

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| `playSessionId` | INTEGER | FK → `play_sessions.id`、複合PKの一部 | 対象のプレイ記録 |
| `expansionGameKey` | TEXT | FK → `games.gameKey`、複合PKの一部 | このプレイで使用した拡張 |

例: 「ドミニオン」のプレイ記録に対し、`(playSessionId=1, expansionGameKey=<陰謀のgameKey>)`と`(playSessionId=1, expansionGameKey=<繁栄のgameKey>)`の2行で「陰謀・繁栄を使用した」を表現する。

### 4.3 評価系スケール定義

| 項目 | 範囲 | 既存スケールとの対応 |
|---|---|---|
| `rating`（評価） | 1〜10の整数 | BGGの総合評価（10点満点）と同尺度 |
| `replayDesire`（また遊びたい度） | 1〜5の整数 | 独自だが5段階に統一 |
| `perceivedWeight`（重さの体感） | 1.0〜5.0の実数 | `games.weight`（BGGの重さ1〜5）と同尺度 |

いずれもnullable（未入力可）。値が設定される場合のみ範囲チェックを行う。

### 4.4 バリデーション規則（`recordSession`）

1. `gameKey`が`games`テーブルに存在し、かつ`gameKind != 'expansion'`であること。存在しない、または`gameKind=='expansion'`の場合はエラー
2. `playedDate`が`DateTime.parse`可能な形式であること
3. `rating`/`replayDesire`/`perceivedWeight`は、値が設定されている場合のみ4.3の範囲内であること
4. `expansionGameKeys`の各要素は、`games`テーブルに存在し、かつ`gameKind=='expansion' && parentGameKey==<対象gameKey>`であること。条件を満たさない要素が1つでもあればエラー（部分的な記録は行わない）

### 4.5 削除時の整合性

- 基本ゲーム（`gameKind != 'expansion'`）の削除時、当該`gameKey`に紐づく`play_sessions`およびその`play_session_expansions`をすべて削除する
- 任意のゲーム削除時、削除対象の`gameKey`を`expansionGameKey`として参照する`play_session_expansions`行を削除する（プレイ記録自体は残るが、削除された拡張の使用履歴は失われる）
- `CollectionRepository.deleteRequirement`は、既存の所持メタデータチェックに加え、対象`gameKey`に`play_sessions`が1件以上存在する場合も`confirmationRequired`とする

---

## 5. Repository仕様（概要）

`PlaySessionRepository`は以下を提供する。

- `recordSession(PlaySessionInput input) -> Future<int>`: 4.4のバリデーションを行い、`play_sessions`1行と`play_session_expansions`0件以上をトランザクションで挿入し、新規`id`を返す。バリデーション失敗時は`PlaySessionValidationException`をスローする
- `listForGame(String gameKey) -> Future<List<PlaySessionRecord>>`: 指定ゲームのプレイ記録を`playedDate`降順（同日は`id`降順）で返す。各記録には関連する`expansionGameKeys`を含める
- `deleteSession(int id) -> Future<void>`: 指定プレイ記録と、その`play_session_expansions`を削除する
- `countForGame(String gameKey) -> Future<int>`: 指定ゲームのプレイ記録件数を返す（`deleteRequirement`およびPhase 6-Bでの「N回プレイ済み」表示に使用）

---

## 6. 受け入れ基準（概要）

- `play_sessions`/`play_session_expansions`テーブルが追加され、schemaVersion 6→7への移行が既存データに影響なくエラーなく動作する
- `recordSession`で、基本ゲーム以外（`gameKind=='expansion'`または存在しないgameKey）を指定するとエラーになる
- `recordSession`で、`rating`/`replayDesire`/`perceivedWeight`が範囲外の場合エラーになり、範囲内・未指定では正常に記録できる
- `recordSession`で、`expansionGameKeys`に「対象の基本ゲームの拡張ではないgameKey」が含まれる場合エラーになり、記録は作成されない
- `listForGame`が`playedDate`降順で記録を返し、各記録に紐づく`expansionGameKeys`が正しく含まれる
- `deleteSession`で記録と紐づく`play_session_expansions`が削除される
- `countForGame`が正しい件数を返す
- 基本ゲームを削除すると、紐づく`play_sessions`/`play_session_expansions`がカスケード削除される
- プレイ記録が存在するゲームの削除は`deleteRequirement`が`confirmationRequired`を返す
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス（新規テストを含む）

詳細なタスク分割・定数・実装制約は `docs/DEVELOPMENT_BRIEF_Phase6-A.md` を参照。
