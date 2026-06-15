# Codex用開発文書: Board Game Shelf Phase 1-C（棚全体の複数ゲーム同時検出）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-13 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase1-C.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底） ③`docs/DEVELOPMENT_BRIEF_Phase1-B.md`（直前フェーズ・vision基盤） |
| 対象スコープ | **Phase 1-C**: 棚画像1枚からの複数候補抽出→一括レビュー→既存登録動線への順次合流 |
| 非対象 | 物体検出/クロップ/バウンディングボックス、オフライン認識、BGG ID直接確定/自動登録、iOS・Desktop・Web |
| 実装エージェント | Codex |
| 前提 | Phase 0（T-01〜T-10）・1-A（T-11〜T-15）・1-B（T-16〜T-20）完了済み。本フェーズは T-21 から開始する |

---

## 0. 設計根拠（rationale）

- **物体検出/クロップを作らない理由**: 自前検出・トリミングは精度/実装/テストのコストが高い。棚画像をそのまま Gemini に渡し**検出ゲームのJSON配列**を得る方式に限定し、1-Bの vision クライアントを多検出に拡張するだけにする。
- **自動登録は禁止**（要件§1.1）。複数検出は誤り・取りこぼしが前提のため、**一括レビューでユーザーが選別・確認**してから既存の登録動線で確定する。
- **Vision はタイトル文字列を返すだけ**で BGG ID を確定しない。各候補は既存 `SearchRegistrationPage(initialQuery)` に順次流す（1-Bで追加済みの仕組みを再利用）。
- **既存資産の最大再利用**: `VisionClient`/`GeminiVisionClient`、`preprocessBoxImage`、`searchQueryForCandidate`、`SecureSettingsRepository.readGeminiApiKey()`、`SearchRegistrationPage(initialQuery)`、`image_picker` をそのまま使う。新規は「多検出の推論・パース／一括レビューUI／順次登録の状態管理」に限定する。

---

## 1. Codexへの引き渡し手順（人間向け）

1. 本文書を `docs/DEVELOPMENT_BRIEF_Phase1-C.md` として配置（配置済み）。
2. §2「冒頭プロンプト」をCodexの最初の指示として貼り付ける。
3. Codexは§5のタスクを `T-21` から順に実行し、各タスク完了時に受け入れ基準の充足を報告する。
4. 設計と矛盾が出たら実装を止めて報告（勝手に仕様を変えない）。本文書を改訂してから再開する。

## 2. 冒頭プロンプト（Codexへ最初に渡す指示）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 1-C（棚全体の複数ゲーム同時検出）を実装します。
docs/REQUIREMENTS_Phase1-C.md と docs/DEVELOPMENT_BRIEF_Phase1-C.md が仕様書です。
Phase 0 / 1-A / 1-B は完了済みで、既存コードを再利用します。以下を厳守してください。

1. §5のタスクを T-21 から番号順に実装する。並行着手しない。
2. 各タスクの受け入れ基準をテストコードで担保し、完了報告に
   「実装ファイル一覧 / テスト結果 / 基準との対応」を含める。
3. 物体検出・クロップ・バウンディングボックスは実装しない。棚画像をGeminiに渡し
   検出ゲームのJSON配列を得る方式に限定する（1-Bのvisionクライアントを多検出に拡張）。
4. 検出結果は一括レビューでユーザーが選別・確認してから登録する。自動登録しない。
   VisionからBGG IDを直接確定しない。各候補は既存 SearchRegistrationPage(initialQuery) に流す。
5. 画像送信はユーザー明示操作のみ。Gemini APIキーは既存 secure storage を再利用し新規保管しない。
6. 対象は Android のみ。iOS/Desktop/Web のビルドは壊さない。
7. UI文言はすべて assets/i18n/{ja,en}.json のキー経由（ハードコード禁止）。
8. §3 定数（Phase 0 C-01〜18 / 1-A C-19〜22 / 1-B C-23〜27 / 本書 C-28〜30）は変更禁止。曖昧なら質問する。
まず T-21 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-28 | 棚の最大検出数 | 30（超過は確信度上位に絞る） | 一括レビュー件数上限 | 要件§7 |
| C-29 | 棚画像の長辺上限 | 1600px（単一箱の C-24 より大きめ。JPEG品質は C-24 を流用） | 細部保持と送信量の両立 | 要件§4 |
| C-30 | 棚Vision出力スキーマ | `{ "detections": [ { "title": string, "japaneseTitle"?: string, "publisher"?: string, "confidence": number, "positionHint"?: string } ], "note"?: string }`（JSONのみ） | パース契約 | 要件§4 |

補足: 各検出の確信度下限判定は既存 **C-26（visionConfidenceThreshold）** を流用する（低信頼は捨てず印をつけて残す）。

---

## 4. 技術スタック・リポジトリ構成（追加分）

| 項目 | 指定 |
|---|---|
| 画像取得 | 既存 `image_picker` 再利用 |
| 画像前処理 | 既存 `preprocessBoxImage` を踏襲しつつ、棚は長辺上限 C-29 を使う前処理を用意（既存関数の引数化 or 棚用関数） |
| Vision | 既存 `VisionClient`/`GeminiVisionClient` を多検出に拡張（棚用プロンプト・スキーマ C-30） |
| 状態管理 | 既存 Riverpod。一括レビューの選別・各アイテム状態は ConsumerStatefulWidget で管理 |
| テスト | flutter_test。Vision呼び出しはモック。多検出JSONのパース・確信度仕分け・クエリ変換・件数上限を純Dartでユニットテスト |

```
追加/変更ファイル（想定）:
lib/src/
  data/
    vision/gemini_vision_service.dart … EDIT: 棚用メソッド（recognizeShelf）を追加 or 汎用化
    repo/
      shelf_recognition_repository.dart … NEW: recognizeShelf(imageBytes) → ShelfRecognitionResult(detections / lowConfidenceのみ / 各status)
      box_recognition_repository.dart    … 参照（parseVisionJson / searchQueryForCandidate を共通化して再利用可）
  app/providers.dart                  … EDIT: shelfRecognitionRepositoryProvider 追加
  ui/pages/
    shelf_recognition_page.dart       … NEW: S-08 取得→プレビュー→明示送信→一括レビュー→順次登録
    collection_list_page.dart         … EDIT: FAB登録メニューに「棚を撮影して一括登録」を追加
    search_registration_page.dart     … 参照（initialQuery を再利用。変更不要の想定）
assets/i18n/{ja,en}.json              … EDIT: shelf.* を追加
test/
  t14_shelf_recognition_test.dart     … NEW: 多検出パース / 確信度仕分け / 件数上限(C-28) / クエリ変換
README.md                            … EDIT: 棚一括登録の手順・コスト/精度の注記
```

共通化の方針: 1-B の `parseVisionJson` / `searchQueryForCandidate` / `BoxRecognitionCandidate` 等は棚でも使える。配列キー名が `candidates`（1-B）と `detections`（棚 C-30）で異なる点だけ吸収し、候補モデルは共有する（重複実装を避ける）。

---

## 5. 実装タスク（execution order・T-21〜T-25）

### T-21 多検出 Vision ロジック＋リポジトリ
- 内容: `VisionClient` に棚用メソッド（または汎用 `recognize(prompt, jpegBytes)`）を追加。`shelf_recognition_repository.dart` に `recognizeShelf(imageBytes)`。鍵は既存 `readGeminiApiKey()`（未設定は missingApiKey）。前処理は C-29、プロンプトは C-30（JSONのみ）。パースは1-Bの共通関数を再利用しつつ `detections` 配列に対応、確信度降順、最大 C-28 件。低信頼（全件 C-26 未満）でも候補は残し lowConfidence 印をつける。
- 受け入れ基準:
  - [ ] C-30スキーマのJSONをパースし、確信度降順で最大 C-28 件に整形する
  - [ ] 各検出に低信頼フラグ（confidence < C-26）が付与される（捨てない）
  - [ ] キー未設定で missingApiKey、ネットワーク例外で noNetwork、パース失敗で failed、検出ゼロで empty を返す（クラッシュしない）
  - [ ] Vision呼び出しはモックで、ネットワーク・鍵に直接依存しない

### T-22 S-08 取得・認識UI
- 内容: `shelf_recognition_page.dart` を新規作成。カメラ撮影／ギャラリー選択、プレビュー、「棚を認識」明示送信ボタン（送信注記＋取りこぼし/誤検出の注意表示）、認識中インジケータ。S-01のFAB登録メニューに「棚を撮影して一括登録」を追加。
- 受け入れ基準:
  - [ ] 画像取得→プレビュー→明示操作でのみ recognizeShelf が呼ばれる（自動送信しない）
  - [ ] 送信注記と「取りこぼし・誤検出が起こりうる」旨が表示される
  - [ ] 検出ゼロ時に再撮影/手動登録の導線が出る

### T-23 一括レビューUI
- 内容: 検出候補リスト（タイトル・出版社・確信度・低信頼印）。チェックボックスで選別（既定: 確信度 C-26 以上をオン）。タイトル一致で「登録済みの可能性」を表示（既存コレクションと照合）。各アイテムに 未処理/登録済み/スキップ の状態。手動追加・個別スキップ導線。
- 受け入れ基準:
  - [ ] 低信頼候補は既定オフ・印つきで表示され、ユーザーが任意でオンにできる
  - [ ] 既存コレクションとタイトル一致する候補に「登録済みの可能性」が表示される
  - [ ] 取りこぼし用の「手動で追加」導線が常設される

### T-24 順次登録の結線（E2Eコア）
- 内容: 「選択を順に登録」で、選択候補を1件ずつ既存 `SearchRegistrationPage(initialQuery=候補タイトル)` へ遷移→候補確認→登録。1件完了で次へ、または都度一括レビューへ戻り状態更新（未処理/登録済み/スキップ）。全件処理後にサマリ（登録n件/スキップm件）を表示し S-01 へ。`searchQueryForCandidate` を再利用。
- 受け入れ基準:
  - [ ] 選択した複数候補が順に S-03 へ流れ、各々で登録/スキップできる
  - [ ] 各アイテムの状態（登録済み/スキップ/未処理）が更新表示される
  - [ ] 全件処理後に登録結果サマリが表示される
  - [ ] 1-B（単一）・1-A（スキャン）・既存検索の各動線が回帰しない

### T-25 失敗時UX・i18n・ドキュメント仕上げ
- 内容: 要件§7の各ケース（キー未設定→S-05、ネットワークなし、検出ゼロ、件数過多→上位に絞る注記、誤検出→オフ可、呼び出し失敗→フォールバック）。`shelf.*` のi18nキーを ja/en に追加。README に棚一括登録の手順・**コスト/精度の注記**（表紙が見える向き推奨、取りこぼし前提）を追記。
- 受け入れ基準:
  - [ ] 追加文言がすべて ja/en のキー経由で、ハードコード文字列が無い
  - [ ] キー未設定・ネットワークなし・検出ゼロ・件数過多・呼び出し失敗の各表示/誘導が出る
  - [ ] `flutter analyze` 警告ゼロ、`flutter test` 全件パス

---

## 6. 既存資産マッピング（実装時に参照）

| 用途 | 既存シンボル | 所在 |
|---|---|---|
| Visionクライアント | `VisionClient` / `GeminiVisionClient`（棚メソッドを追加/汎用化） | `lib/src/data/vision/gemini_vision_service.dart` |
| 画像前処理・JSONパース・クエリ変換・候補モデル | `preprocessBoxImage` / `parseVisionJson` / `searchQueryForCandidate` / `BoxRecognitionCandidate` / `BoxRecognitionStatus` | `lib/src/data/repo/box_recognition_repository.dart` |
| Gemini APIキー | `SecureSettingsRepository.readGeminiApiKey()` | `lib/src/data/settings/secure_settings_repository.dart` |
| 検索登録画面 | `SearchRegistrationPage(initialQuery:)`（1-Bで追加済み） | `lib/src/ui/pages/search_registration_page.dart` |
| 既存コレクション照合 | `CollectionRepository.list(...)`（タイトル一致判定に利用） | `lib/src/data/repo/collection_repository.dart` |
| 画像取得 | `image_picker`（1-Bで導入済み） | pubspec |
| 登録メニュー | `CollectionListPage` の FAB ボトムシート（「棚を撮影して一括登録」を追加） | `lib/src/ui/pages/collection_list_page.dart` |
| DI | `lib/src/app/providers.dart`（`shelfRecognitionRepositoryProvider` を追加） | 同上 |
| i18n | `I18n.t(key, vars)`（未定義キーはキー文字列を返す） | `lib/src/i18n/i18n.dart` |

---

## 7. 禁止事項・制約

1. **物体検出・クロップ・バウンディングボックスを実装しない**。Geminiの多検出JSON配列のみで扱う。
2. **自動登録しない／VisionからBGG IDを直接確定しない**。一括レビューの確認を経て既存検索で登録する。
3. **オフライン認識・オンデバイスMLを実装しない**。Geminiオンライン前提。
4. **新規の鍵保管・同梱をしない**。既存 secure storage の Gemini キーを再利用。画像はユーザー明示操作でのみ送信し、送信注記を出す。
5. **共通ロジックを重複実装しない**。1-Bの parse/preprocess/query/候補モデルを再利用し、配列キー差（candidates/detections）のみ吸収する。
6. **Phase 0 / 1-A / 1-B の定数・YAML互換・barcode_map・vision基盤・移植ロジックを変更しない**。
7. 対象は **Android のみ**。iOS/Desktop/Web のビルドを壊さない。
8. UI文言ハードコード禁止（i18nキー経由）。Vision・ネットワーク・鍵に直接依存するテストを書かず、ロジックを純Dartに切り出して注入可能にする。

---

## 8. 完了の定義（Phase 1-C Done）

- T-21〜T-25 の全受け入れ基準がテストで担保され、`flutter test` が全件成功する
- `flutter analyze` 警告ゼロ
- 実機（Android）で「**棚撮影→一括レビュー→選択を順に登録→サマリ**」のE2E動線が通る
- キー未設定・ネットワークなし・検出ゼロ・呼び出し失敗の各ケースで手動登録へフォールバックする
- 取りこぼしに対する手動追加導線が用意されている
- 送信注記・コスト/精度の注記が UI / README に表示される
