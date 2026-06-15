# Codex用開発文書: Board Game Shelf Phase 1-A（バーコードスキャン登録）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-13 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase1-A.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0・定数表/構成の基底） |
| 対象スコープ | **Phase 1-A**: F-01 のうち JAN/EAN-13 バーコードのカメラ読み取り登録のみ |
| 非対象 | 画像AI（Phase 1-B）／seed一括投入（別タスク）／Desktop・Web |
| 実装エージェント | Codex |
| 前提 | Phase 0（T-01〜T-10）が完了済み。本フェーズは T-11 から開始する |

---

## 0. 設計根拠（rationale）

- **バーコードのみに限定する理由**: 画像AI・棚検出は精度/コスト/権限の不確実性が高い。確実な「カメラでJAN→既知なら即ヒット／未知なら既存の検索・手動登録に合流」だけを先に閉じ、テストの壊れにくさを担保する。画像AIは Phase 1-B として分離。
- **JAN→BGG自動解決は不可能**（要件§1.1）。BGG APIにバーコード検索が無いため、未知JANは必ず既存のタイトル検索（S-03）か手動登録（F-03後半）を経由し、**登録成功時に学習保存**する。Codexはこの非対称構造を崩してはならない（JANをBGGに投げる実装を作らない）。
- **既存資産を最大限再利用**: `barcode_map` テーブル（Phase 0 T-02で器だけ作成済み）、`BggRegistrationRepository`、`LocalGameRepository`、`SearchRegistrationPage`、`LocalGameFormPage`、`GameDetailPage`、Riverpod providers をそのまま使う。新規は「JAN処理・barcode_mapリポジトリ・S-02実装・動線結線」に限定する。
- **学習保存は将来のseed importと共通経路**: `BarcodeMapRepository.learn()` を唯一の書き込み口とし、後日のCSV/YAMLインポートが同じ口を呼べるようにする。

---

## 1. Codexへの引き渡し手順（人間向け）

1. 本文書を `docs/DEVELOPMENT_BRIEF_Phase1-A.md` として配置（配置済み）。
2. §2「冒頭プロンプト」をCodexの最初の指示として貼り付ける。
3. Codexは§5のタスクを `T-11` から順に実行し、各タスク完了時に受け入れ基準の充足を報告する。
4. 設計と矛盾が出たら実装を止めて報告（勝手に仕様を変えない）。本文書を改訂してから再開する。

## 2. 冒頭プロンプト（Codexへ最初に渡す指示）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 1-A（バーコードスキャン登録）を実装します。
docs/REQUIREMENTS_Phase1-A.md と docs/DEVELOPMENT_BRIEF_Phase1-A.md が仕様書です。
Phase 0 は完了済みで、既存コードを再利用します。以下を厳守してください。

1. §5のタスクを T-11 から番号順に実装する。並行着手しない。
2. 各タスクの受け入れ基準をテストコードで担保し、完了報告に
   「実装ファイル一覧 / テスト結果 / 基準との対応」を含める。
3. JANコードをBGG APIに投げて自動解決する実装は作らない（BGGにバーコード検索は無い）。
   未知JANは既存のタイトル検索(S-03)/手動登録(F-03後半)を経由し、登録成功時に学習保存する。
4. 対象は Android のみ。iOS/Desktop/Web のビルドは壊さないが、カメラ非対応環境では
   手入力JANフォームにフォールバックする。
5. UI文言はすべて assets/i18n/{ja,en}.json のキー経由（ハードコード禁止）。
6. 画像AI/Vision/棚検出/seed一括投入は本フェーズで実装しない。
7. §3 定数（Phase 0 の C-01〜C-18 と本書 C-19〜C-22）は変更禁止。曖昧なら質問する。
まず T-11 から開始してください。
```

---

## 3. 追加定数表（Phase 0 §3 の C-01〜C-18 に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-19 | 受理バーコード形式 | EAN-13（ISBN-13含む）／UPC-A は先頭`0`付与でEAN-13正規化。他形式は無視 | スキャン検証 | 要件§4 |
| C-20 | 同一コード連続検出の抑止時間 | 2.5 秒（直近に確定した同一JANを再発火しない） | 多重登録防止 | 要件§5.1 |
| C-21 | 学習保存の source 値 | `scan`（カメラ）/ `manual`（手入力フォーム） | barcode_map.source | 要件§6 |
| C-22 | 未検出ヒント表示までの時間 | 8 秒（この間未検出なら手入力導線を強調表示） | スキャンUX | 要件§7 |

---

## 4. 技術スタック・リポジトリ構成（追加分）

| 項目 | 指定 |
|---|---|
| バーコード | `mobile_scanner`（stable最新）。コントローラ/検出APIはパッケージ現行版に従う |
| 権限(Android) | `android/app/src/main/AndroidManifest.xml` に `<uses-permission android:name="android.permission.CAMERA"/>`（パッケージが自動付与する場合は重複させない） |
| 状態管理 | 既存どおり Riverpod。スキャナのライフサイクルは ConsumerStatefulWidget で管理 |
| テスト | flutter_test。カメラ実機依存部分はロジック（JAN正規化/解決/学習/動線判定）を純Dartに切り出してユニットテストする。`AppDatabase(NativeDatabase.memory())` を使う |

```
追加/変更ファイル（想定）:
lib/src/
  core/
    barcode.dart            … NEW: JAN正規化・検証(C-19), 重複抑止判定(C-20)
  data/
    repo/
      barcode_map_repository.dart  … NEW: resolve(jan)→hit/miss, learn(jan, gameKey, source)
    db/app_database.dart    … EDIT: barcode_map の DAO メソッド追加(findByJan, upsertBarcode)
  app/providers.dart        … EDIT: barcodeMapRepositoryProvider 追加
  ui/pages/
    scan_page.dart          … REPLACE: S-02 カメラスキャン + 手入力フォールバック
    manual_jan_page.dart    … NEW(任意): 手入力JANフォーム（scan_page内に内包でも可）
    search_registration_page.dart … EDIT: pendingJan を受け取り登録成功時に learn
    local_game_form_page.dart      … EDIT: pendingJan を受け取りローカル登録成功時に learn
assets/i18n/{ja,en}.json    … EDIT: scan.* を拡充, jan.* を追加
test/
  t11_barcode_test.dart            … NEW: JAN正規化/検証/重複抑止
  t12_barcode_map_repository_test.dart … NEW: resolve/learn(upsert, source, 再ヒット)
README.md                   … EDIT: カメラ権限・対象OS・スキャン手順
```

---

## 5. 実装タスク（execution order・T-11〜T-15）

### T-11 依存追加・権限設定・ビルド健全性
- 内容: `mobile_scanner` 追加。Android のカメラ権限を設定。iOS/Desktop/Web ビルドを壊さない（カメラ未対応時の分岐は T-13 で実装）。
- 受け入れ基準:
  - [ ] `flutter pub get` 成功、Android のデバッグビルドが通る
  - [ ] Android `CAMERA` 権限が設定されている
  - [ ] 既存の `flutter test`（t01〜t10＋widget_test）が引き続き全件パスする

### T-12 JAN処理 + barcode_map リポジトリ
- 内容: `core/barcode.dart` に正規化/検証（C-19、UPC-A→EAN-13、チェックディジット検証）と重複抑止判定（C-20）。`data/repo/barcode_map_repository.dart` に `resolve(jan) → BarcodeResolution(hit: game / miss)` と `learn(jan, gameKey, source) → upsert`。`app_database.dart` に barcode_map の DAO（findByJan / upsertBarcode）を追加。`learn` を唯一の書き込み口にする（将来のseed import再利用のため）。
- 受け入れ基準:
  - [ ] 12桁UPC-Aが先頭0付与でEAN-13化される／不正桁・チェックディジット不正は無効と判定される
  - [ ] `resolve` が既知JANで対応 `Game` を返し、未知JANで miss を返す
  - [ ] `learn` 後に同一JANの `resolve` がヒットする（インメモリDBで検証）
  - [ ] 同一JANを別game_keyで再 `learn` すると最新で上書きされ、`source` が記録される

### T-13 S-02 スキャンUI（カメラ・検出・フォールバック）
- 内容: `scan_page.dart` を置換。カメラプレビュー＋検出枠、トーチトグル、同一JAN連続検出の抑止（C-20）、未検出ヒント（C-22）。カメラ権限要求と、拒否/非対応時の**手入力JANフォーム**フォールバック。検出/手入力ともに同一の解決ハンドラに渡す。
- 受け入れ基準:
  - [ ] 同一JANの連続検出が抑止時間内に1回だけ確定ハンドラを発火する（純Dartのデバウンス判定をユニットテスト）
  - [ ] 権限拒否時に手入力フォームが表示され、設定アプリ導線の文言が出る
  - [ ] Desktop/Web 等カメラ非対応で例外を出さず手入力フォームにフォールバックする

### T-14 解決動線の結線（E2Eコア）
- 内容: 解決ハンドラを実装。hit→`GameDetailPage` へ。miss→オンラインなら `SearchRegistrationPage(pendingJan)` へ、登録/既存確定時に `learn(jan, gameKey, source: scan)`。検索で該当なし→`LocalGameFormPage(pendingJan)` へ、登録時に `learn(jan, localKey, source: scan)`。オフラインの miss は手動登録へ誘導。`SearchRegistrationPage` / `LocalGameFormPage` に任意引数 `pendingJan` を追加し、成功コールバックで学習する。
- 受け入れ基準:
  - [ ] 既知JANで詳細画面に遷移する（ネットワーク層を例外化したオフライン条件で成立）
  - [ ] 未知JAN→検索→登録成功で barcode_map に `scan` ソースで学習され、再 `resolve` がヒットする
  - [ ] 検索該当なし→手動登録でも学習され、再 `resolve` がヒットする
  - [ ] 既存の検索・手動登録の単体動線（pendingJan 無し）が回帰しない

### T-15 失敗時UX・i18n・ドキュメント仕上げ
- 内容: 要件§7の各失敗ケースの文言・分岐（読取不可継続、候補多数は既存S-03、トークン未設定は既存S-05誘導、ネットワークなし、同人）。`scan.*`/`jan.*` のi18nキーを ja/en に追加。README にカメラ権限・対象OS・スキャン手順を追記。
- 受け入れ基準:
  - [ ] 追加文言がすべて ja/en のキー経由で、ハードコード文字列が無い
  - [ ] トークン未設定・ネットワークなし・読取不可の各メッセージが表示される
  - [ ] `flutter analyze` 警告ゼロ、`flutter test` 全件パス

---

## 6. 既存資産マッピング（実装時に参照）

| 用途 | 既存シンボル | 所在 |
|---|---|---|
| barcode_map テーブル | `BarcodeMapEntries`（janCode PK / gameKey FK→Games / resolvedAt / source） | `lib/src/data/db/app_database.dart` |
| ゲーム取得 | `AppDatabase.findGame(gameKey)` | 同上 |
| BGG検索・登録 | `BggRegistrationRepository.search(query, exact:) / registerBggId(bggId)`（Created/AlreadyExists/TokenRequired/Invalid/ApiException） | `lib/src/data/repo/bgg_registration_repository.dart` |
| 同人ローカル登録 | `LocalGameRepository.register(...)` → `game.gameKey` | `lib/src/data/repo/local_game_repository.dart` |
| 詳細画面 | `GameDetailPage(gameKey:)` | `lib/src/ui/pages/game_detail_page.dart` |
| 検索登録画面 | `SearchRegistrationPage`（pendingJan を追加） | `lib/src/ui/pages/search_registration_page.dart` |
| 手動登録画面 | `LocalGameFormPage`（pendingJan を追加） | `lib/src/ui/pages/local_game_form_page.dart` |
| DI | `lib/src/app/providers.dart`（`barcodeMapRepositoryProvider` を追加） | 同上 |
| i18n | `I18n.t(key, vars)`（未定義キーはキー文字列を返す） | `lib/src/i18n/i18n.dart` |

barcode_map の現行スキーマ（変更しない）:

```dart
class BarcodeMapEntries extends Table {        // tableName: 'barcode_map'
  TextColumn get janCode => text()();           // PK
  TextColumn get gameKey => text().references(Games, #gameKey)();
  DateTimeColumn get resolvedAt => dateTime()();
  TextColumn get source => text()();            // C-21: 'scan' | 'manual'
  Set<Column> get primaryKey => {janCode};
}
```

---

## 7. 禁止事項・制約

1. **JAN→BGG自動解決の実装禁止**（BGGにバーコード検索が無い）。未知JANは必ず既存の検索/手動登録を経由する。
2. **画像AI/Vision/棚検出を本フェーズで実装しない**（Phase 1-B）。`mobile_scanner` 以外のVision系依存を追加しない。
3. **seed一括投入を本フェーズで実装しない**（別タスク）。ただし学習は `BarcodeMapRepository.learn()` の単一経路に集約する。
4. **Phase 0 の定数・YAML互換・移植ロジックを変更しない**（`docs/DEVELOPMENT_BRIEF.md` §3/§6/§7）。barcode_map スキーマも変更しない。
5. 対象は **Android のみ**。iOS/Desktop/Web のビルドを壊さず、カメラ非対応時は手入力フォールバック。
6. UI文言ハードコード禁止（i18nキー経由）。カメラ・時刻・乱数に直接依存するテストを書かず、ロジックを純Dartに切り出して注入可能にする。

---

## 8. 完了の定義（Phase 1-A Done）

- T-11〜T-15 の全受け入れ基準がテストで担保され、`flutter test` が全件成功する
- `flutter analyze` 警告ゼロ
- 実機（Android）で「**既知JANスキャン→詳細** / **未知JANスキャン→タイトル検索→登録→同一JAN再スキャンで即ヒット**」のE2E動線が通る
- カメラ権限拒否/非対応環境で手入力JANフォームから全動線が成立する
- README にカメラ権限・対象OS・スキャン手順が追記されている
