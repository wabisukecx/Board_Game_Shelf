# Codex用開発文書: Board Game Shelf Phase 1-B（箱表紙の画像AI認識）

| 項目 | 内容 |
|---|---|
| 文書バージョン | 0.1 |
| 作成日 | 2026-06-13 |
| 入力文書 | ①`docs/REQUIREMENTS_Phase1-B.md` ②`docs/DEVELOPMENT_BRIEF.md`（Phase 0 基底） ③`docs/DEVELOPMENT_BRIEF_Phase1-A.md`（直前フェーズ） |
| 対象スコープ | **Phase 1-B**: F-02 のうち **単一箱表紙画像**の認識→候補確認→既存登録動線への合流のみ |
| 非対象 | 棚全体の複数検出（Phase 1-C）／バーコード（1-A済）／オフライン認識／iOS・Desktop・Web |
| 実装エージェント | Codex |
| 前提 | Phase 0（T-01〜T-10）・Phase 1-A（T-11〜T-15）完了済み。本フェーズは T-16 から開始する |

---

## 0. 設計根拠（rationale）

- **単一箱表紙に限定する理由**: 棚全体の複数検出はオブジェクト検出・クロップ・バッチ確認が必要でリスクが高い。1枚→1候補群の素直な認識に絞り、確実に価値を出す。複数検出は Phase 1-C に分離。
- **Vision結果はBGG IDではなくタイトル文字列として扱う**（要件§1.1）。Geminiが返す推定タイトルを既存のBGGタイトル検索（S-03）に投げ、候補確認→登録する。VisionからBGG IDを直接確定する実装は作らない。
- **既存資産の最大再利用**: Gemini APIキーは Phase 0 の secure storage（翻訳と共用）を再利用。翻訳の `TranslationClient`/`GeminiTranslationClient` と同じ構成で `VisionClient`/`GeminiVisionClient` を追加する。候補確認・登録は既存 `SearchRegistrationPage` に **initialQuery** を渡して合流する。
- **明示送信・プライバシー**: 画像送信はユーザー操作起点のみ。自動送信しない。送信注記を表示する。

---

## 1. Codexへの引き渡し手順（人間向け）

1. 本文書を `docs/DEVELOPMENT_BRIEF_Phase1-B.md` として配置（配置済み）。
2. §2「冒頭プロンプト」をCodexの最初の指示として貼り付ける。
3. Codexは§5のタスクを `T-16` から順に実行し、各タスク完了時に受け入れ基準の充足を報告する。
4. 設計と矛盾が出たら実装を止めて報告（勝手に仕様を変えない）。本文書を改訂してから再開する。

## 2. 冒頭プロンプト（Codexへ最初に渡す指示）

```
あなたはFlutterアプリ「Board Game Shelf」の Phase 1-B（箱表紙の画像AI認識）を実装します。
docs/REQUIREMENTS_Phase1-B.md と docs/DEVELOPMENT_BRIEF_Phase1-B.md が仕様書です。
Phase 0 / Phase 1-A は完了済みで、既存コードを再利用します。以下を厳守してください。

1. §5のタスクを T-16 から番号順に実装する。並行着手しない。
2. 各タスクの受け入れ基準をテストコードで担保し、完了報告に
   「実装ファイル一覧 / テスト結果 / 基準との対応」を含める。
3. Vision結果はタイトル文字列として扱い、既存のBGGタイトル検索(S-03)に投げて
   候補確認→登録する。VisionからBGG IDを直接確定する実装は作らない。自動登録しない。
4. 画像送信はユーザーの明示操作でのみ行い、送信注記を表示する。Gemini APIキーは
   既存 secure storage（翻訳と共用）を再利用し、新規に鍵を保管・同梱しない。
5. 対象は Android のみ。iOS/Desktop/Web のビルドは壊さない。
6. 棚全体の複数検出・自動クロップ／オフライン認識／オンデバイスMLは本フェーズで実装しない。
7. UI文言はすべて assets/i18n/{ja,en}.json のキー経由（ハードコード禁止）。
8. §3 定数（Phase 0 C-01〜C-18 / 1-A C-19〜C-22 / 本書 C-23〜C-27）は変更禁止。曖昧なら質問する。
まず T-16 から開始してください。
```

---

## 3. 追加定数表（既存に追記。変更禁止）

| ID | 定数 | 値 | 用途 | 出典 |
|---|---|---|---|---|
| C-23 | Vision モデル | Gemini マルチモーダル（current stable、定数で切替可） | 画像認識 | 要件§4 |
| C-24 | 送信前画像の長辺上限 / JPEG品質 | 長辺 1024px / 品質 80 | 送信量・コスト制御 | 要件§4 |
| C-25 | 候補最大数 | 5 | 候補リスト | 要件§4 |
| C-26 | 確信度下限 | 0.4（未満は「自信がありません」→手動検索） | 低信頼判定 | 要件§4 |
| C-27 | Vision出力スキーマ | `{ "candidates": [ { "title": string, "japaneseTitle"?: string, "publisher"?: string, "confidence": number } ], "note"?: string }`（JSONのみ） | パース契約 | 要件§4 |

---

## 4. 技術スタック・リポジトリ構成（追加分）

| 項目 | 指定 |
|---|---|
| 画像取得 | `image_picker`（カメラ／ギャラリー）。APIはパッケージ現行版に従う |
| 画像前処理 | 長辺リサイズ＋JPEG圧縮（C-24）。`package:image` 等の利用可。base64化してGeminiへ |
| Vision | Gemini マルチモーダル。HTTPは既存 `dio` を流用可。鍵は `SecureSettingsRepository.readGeminiApiKey()` を再利用 |
| 状態管理 | 既存どおり Riverpod |
| 権限(Android) | カメラ撮影に `CAMERA`（1-Aで設定済み）。`image_picker` のギャラリー取得に必要なメディア権限はパッケージ現行版の要件に従う |
| テスト | flutter_test。Vision呼び出しはモック化。出力JSONのパース・確信度判定・クエリ変換を純Dartに切り出してユニットテスト |

```
追加/変更ファイル（想定）:
lib/src/
  data/
    vision/
      gemini_vision_service.dart   … NEW: VisionClient(抽象) / GeminiVisionClient
    repo/
      box_recognition_repository.dart … NEW: recognize(imageBytes) → RecognitionResult(candidates / lowConfidence / missingApiKey / failed / noNetwork)
  app/providers.dart               … EDIT: visionClientProvider / boxRecognitionRepositoryProvider 追加
  ui/pages/
    photo_recognition_page.dart    … NEW: S-07 画像取得→プレビュー→明示送信→候補表示
    collection_list_page.dart      … EDIT: FAB登録メニューに「写真で認識」を追加
    search_registration_page.dart  … EDIT: initialQuery を受け取り自動検索
assets/i18n/{ja,en}.json           … EDIT: photo.* を追加
test/
  t13_box_recognition_test.dart    … NEW: 出力JSONパース / 確信度判定(C-26) / クエリ変換
README.md                          … EDIT: 写真認識手順・Geminiキー・画像送信の注記
```

---

## 5. 実装タスク（execution order・T-16〜T-20）

### T-16 依存追加・権限・ビルド健全性
- 内容: `image_picker`（必要なら前処理用に `image`）を追加。ギャラリー/カメラ取得に必要なAndroid権限を設定（カメラは1-Aで設定済み）。iOS/Desktop/Web ビルドを壊さない。
- 受け入れ基準:
  - [ ] `flutter pub get` 成功、Android デバッグビルドが通る
  - [ ] 既存の `flutter test`（t01〜t12＋widget_test）が引き続き全件パスする

### T-17 Vision抽出ロジック＋GeminiVisionClient
- 内容: `data/vision/gemini_vision_service.dart` に `VisionClient`(抽象) と `GeminiVisionClient`（既存翻訳クライアントと同型の構成）。`data/repo/box_recognition_repository.dart` に `recognize(imageBytes)`。鍵は `SecureSettingsRepository.readGeminiApiKey()` から取得（未設定は missingApiKey を返す）。画像前処理（C-24）、プロンプト（C-27のJSONのみ出力を要求）、安全パース、確信度判定（C-26）、候補上限（C-25）。
- 受け入れ基準:
  - [ ] C-27スキーマのJSONを正しくパースし、`confidence` 降順で最大C-25件に整形する
  - [ ] 確信度が全件C-26未満のとき lowConfidence を返す
  - [ ] キー未設定で missingApiKey、ネットワーク例外で noNetwork、パース失敗で failed を返す（クラッシュしない）
  - [ ] Vision呼び出しはモックで、ネットワーク・鍵・乱数に直接依存しない

### T-18 画像取得・認識UI（S-07）
- 内容: `photo_recognition_page.dart` を新規作成。カメラ撮影／ギャラリー選択、プレビュー、「この箱を認識」明示送信ボタン（送信注記表示）、認識中インジケータ、候補タイトル一覧（確信度つき）。S-01のFAB登録メニューに「写真で認識」を追加。
- 受け入れ基準:
  - [ ] 画像取得→プレビュー→明示操作でのみ recognize が呼ばれる（自動送信しない）
  - [ ] 「画像をGeminiに送信します」相当の注記が表示される
  - [ ] 候補一覧が確信度つきで表示され、低信頼/抽出不能時は手動検索導線が出る

### T-19 動線結線（候補→検索→登録）
- 内容: `SearchRegistrationPage` に任意引数 `initialQuery`（と必要なら自動検索フラグ）を追加。候補タップで推定タイトルを initialQuery として渡し、自動検索→既存の候補確認→登録動線に合流。手動検索への切替導線も常設。
- 受け入れ基準:
  - [ ] 候補タップで S-03 に推定タイトルが渡り自動検索が走る
  - [ ] そこから既存の登録（Created/AlreadyExists）→詳細遷移が成立する
  - [ ] 既存の検索動線（initialQuery 無し）・1-Aのスキャン動線が回帰しない

### T-20 失敗時UX・i18n・ドキュメント仕上げ
- 内容: 要件§7の各失敗ケース（キー未設定→S-05誘導、ネットワークなし、抽出不能/低信頼→手動検索、候補多数→S-03、誤認→手動切替、呼び出し失敗→フォールバック）。`photo.*` のi18nキーを ja/en に追加。README に写真認識手順・Geminiキー・画像送信の注記を追記。
- 受け入れ基準:
  - [ ] 追加文言がすべて ja/en のキー経由で、ハードコード文字列が無い
  - [ ] キー未設定・ネットワークなし・低信頼・呼び出し失敗の各メッセージ/誘導が表示される
  - [ ] `flutter analyze` 警告ゼロ、`flutter test` 全件パス

---

## 6. 既存資産マッピング（実装時に参照）

| 用途 | 既存シンボル | 所在 |
|---|---|---|
| Gemini APIキー取得 | `SecureSettingsRepository.readGeminiApiKey()` | `lib/src/data/settings/secure_settings_repository.dart` |
| クライアント構成の手本 | `TranslationClient` / `GeminiTranslationClient` / `DescriptionTranslationRepository`（鍵未設定→status分岐の手本） | `lib/src/data/translation/gemini_translation_service.dart` |
| BGGタイトル検索 | `BggRegistrationRepository.search(query, exact:)` | `lib/src/data/repo/bgg_registration_repository.dart` |
| 検索登録画面 | `SearchRegistrationPage`（`initialQuery` を追加） | `lib/src/ui/pages/search_registration_page.dart` |
| 詳細画面 | `GameDetailPage(gameKey:)` | `lib/src/ui/pages/game_detail_page.dart` |
| 登録メニュー | `CollectionListPage` の FAB ボトムシート（「写真で認識」を追加） | `lib/src/ui/pages/collection_list_page.dart` |
| HTTP | 既存 `dio`（`bgg_transport.dart` の利用パターン参照） | `lib/src/data/bgg/bgg_transport.dart` |
| DI | `lib/src/app/providers.dart`（`visionClientProvider` / `boxRecognitionRepositoryProvider` を追加） | 同上 |
| i18n | `I18n.t(key, vars)`（未定義キーはキー文字列を返す） | `lib/src/i18n/i18n.dart` |

---

## 7. 禁止事項・制約

1. **VisionからBGG IDを直接確定しない／自動登録しない**。推定タイトルを既存検索に投げ、ユーザー確認を経て登録する。
2. **棚全体の複数検出・自動クロップを本フェーズで実装しない**（Phase 1-C）。1画像=1候補群に限定。
3. **オフライン認識・オンデバイスML（TFLite等）を実装しない**。Gemeniオンライン前提。
4. **新規の鍵保管・同梱をしない**。既存 secure storage の Gemini キーを再利用。画像はユーザー明示操作でのみ送信し、送信注記を出す。
5. **Phase 0 / 1-A の定数・YAML互換・barcode_map・移植ロジックを変更しない**。
6. 対象は **Android のみ**。iOS/Desktop/Web のビルドを壊さない。
7. UI文言ハードコード禁止（i18nキー経由）。Vision・ネットワーク・鍵に直接依存するテストを書かず、ロジックを純Dartに切り出して注入可能にする。

---

## 8. 完了の定義（Phase 1-B Done）

- T-16〜T-20 の全受け入れ基準がテストで担保され、`flutter test` が全件成功する
- `flutter analyze` 警告ゼロ
- 実機（Android）で「**箱表紙を撮影→認識→候補タイトル→検索→登録→詳細**」のE2E動線が通る
- Gemini APIキー未設定・ネットワークなし・低信頼の各ケースで手動検索へフォールバックする
- 画像送信の注記がUIに表示される
- README に写真認識手順・Geminiキー・画像送信の注記が追記されている
