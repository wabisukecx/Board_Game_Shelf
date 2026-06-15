# Board Game Shelf 改修ブリーフ：設定画面での言語選択（Phase 7 / Codex向け）

## 前提・対象
- 対象: `C:\Users\tucon\StudioProjects\bg_shelf_scanner`（Flutter / Riverpod）
- 目的: 設定画面で UI 言語を選べるようにする。`assets/i18n/` 内の JSON を動的に列挙し、追加すれば自動で選択肢に出る。初回は「システムに従う」をデフォルトとし、手動選択も可能。選択は即時に UI へ反映され、再起動後も保持される。
- 各タスクは独立コミット可能な粒度。既存テストを壊さないこと。各タスク完了時に `flutter test` を実行。

## 現状（調査済みの事実 — これに合わせて実装すること）
- `main.dart` が起動時に `assets/i18n/ja.json` をハードコードで読み、`i18nProvider.overrideWithValue(i18n)` で注入している。`i18nProvider` は読み取り専用 `Provider<I18n>`。
- `I18n`（`lib/src/i18n/i18n.dart`）は不変。`I18n.fromJsonString(String)` でJSONから生成し、`t(key, [vars])` でルックアップ。欠損キーはキー文字列を返すフォールバック挙動。
- `pubspec.yaml` の assets は `assets/i18n/ja.json` と `assets/i18n/en.json` を**個別列挙**。フォルダ一括ではない。
- `BgShelfScannerApp`（`lib/src/app/app.dart`）は `StatelessWidget` で `MaterialApp` を返す。現状 `i18n` を監視していない。
- 設定の永続化は `SecureSettingsRepository`（`flutter_secure_storage`）。キーは `SecureSettingKeys`。**言語設定は秘密情報ではないため、セキュアストレージには入れない**（理由はタスク2参照）。
- 設定画面 `SettingsPage`（`lib/src/ui/pages/settings_page.dart`）は `ConsumerStatefulWidget`。各設定が「見出し＋状態表示＋入力＋保存/クリアボタン」＋`Divider`で区切られたパターンで並ぶ。i18n文言は `t.t('settings.xxx')`。

---

## タスク0: アセット列挙の方式決定（実装前の判断と報告）
言語ファイルを「動的に列挙」する必要があるが、Flutterは実行時にassetsフォルダを直接走査できない。`AssetManifest`（ビルド時に生成されるアセット一覧）を使う。

1. `AssetManifest.loadFromAssetBundle(rootBundle)`（Flutter 3.x の新API）で `assets/i18n/` 配下の `.json` を列挙できることを確認し、使用すること。`*.json` のうち `assets/i18n/` 直下のものを対象とする。
2. **重要**: `pubspec.yaml` の assets 指定を、個別ファイル列挙から **`assets/i18n/` フォルダ指定** に変更する。これで新規JSONを置くだけで `AssetManifest` に載り、列挙対象になる。
   ```yaml
   assets:
     - assets/i18n/
     - assets/analysis/
   ```
3. 各言語ファイルの**表示名と言語コード**をどう得るか決める。方針: 各 JSON のトップレベルにメタ情報キー `"_meta": {"locale": "ja", "name": "日本語"}` を持たせる規約とする。`ja.json` / `en.json` に `_meta` を追加すること（`name` はその言語自身での表記＝endonym：`日本語` / `English`）。`_meta` が無いファイルは locale をファイル名（拡張子除く）から推定し、name はファイル名を表示する、というフォールバックも実装する。
4. `_meta` は翻訳キーではないので、`I18n.t` のルックアップ対象から自然に外れる（`t('_meta.name')` を呼ばない限り無害）。既存の `t()` 挙動は変更しないこと。

---

## タスク1: 言語カタログのロード（domain/data層）
1. `LocaleOption` 値クラスを新設（`lib/src/i18n/locale_option.dart` など）。フィールド: `assetPath`(String), `localeCode`(String), `displayName`(String)。
2. `LanguageCatalog`（または同等のサービス）を新設し、`Future<List<LocaleOption>> load()` を実装:
   - `AssetManifest` から `assets/i18n/*.json` を列挙
   - 各ファイルを読み、`_meta` から `localeCode`/`displayName` を取得（無ければファイル名フォールバック）
   - `localeCode` で安定ソート（ja, en の順は問わないが決定的に）
3. ユニットテストを追加: `_meta` あり/なし両方のダミーJSONを与えて、正しく `LocaleOption` 一覧が生成されること、欠損時フォールバックが効くことを検証。AssetManifest依存部分はテスト可能なよう、列挙結果（パス一覧）と「パス→JSON文字列」取得を注入可能な形に分離すること。

---

## タスク2: 言語設定の永続化（秘密情報と分離）
言語設定は秘密ではないので `flutter_secure_storage` ではなく `shared_preferences` に保存する。

1. `shared_preferences` を `pubspec.yaml` の dependencies に追加（`flutter pub add shared_preferences`）。
2. `LanguagePreferenceRepository` を新設。保存値の意味:
   - 未設定（キーなし）= 「システムに従う」
   - `"system"` = 明示的にシステム追従
   - それ以外 = 選択された `localeCode`（例 `"en"`）
   - API: `Future<String?> read()` / `Future<void> save(String value)` / `Future<void> clear()`
3. ユニットテスト追加（`shared_preferences` のモック/インメモリ実装を使用）。

> 注: 既存の秘密情報（トークン/APIキー）は `SecureSettingsRepository` のまま。言語設定だけ別リポジトリにする理由をコードコメントに1行残すこと。

---

## タスク3: i18n を実行時切り替え可能にする（providers / main）
1. `i18nProvider` を読み取り専用 `Provider` から、現在の言語に追従するものへ変更する。設計:
   - `localeOptionsProvider`（`FutureProvider<List<LocaleOption>>`）= タスク1の `LanguageCatalog.load()`
   - `languagePreferenceProvider`（`NotifierProvider` か `AsyncNotifierProvider`）= 保存済み設定（`system` or localeCode）を保持し、`select(localeCode)` / `useSystem()` を公開。変更時に `LanguagePreferenceRepository` へ保存。
   - `effectiveLocaleProvider` = preference が `system` の場合、
     `WidgetsBinding.instance.platformDispatcher.locales` の先頭と利用可能
     `LocaleOption` を突き合わせて解決する。解決順序は次のとおり:
       1. システム言語コードに一致する LocaleOption があればそれ
       2. 無ければ英語（localeCode == "en"）にフォールバック
       3. 英語の LocaleOption すら存在しなければ一覧先頭にフォールバック
     つまり既定フォールバックは英語。フォールバック先の localeCode は定数として
     1か所に定義し（例 `AppConstants.fallbackLocaleCode = 'en'`）、後から変更しやすくすること。
   - `i18nProvider` = `effectiveLocale` に対応する JSON をロードした `I18n` を返す。**即時反映**のため、preference 変更で `i18nProvider` が再評価され UI が更新される構成にする。
2. `main.dart`: 起動時に必要な初期化（preference読み込み・カタログ初回ロード）を行い、`overrideWithValue` のハードコード注入をやめる。初期ロード中はスプラッシュ/ローディング表示でよい。
3. `app.dart`: `BgShelfScannerApp` を `ConsumerWidget` 化し、`MaterialApp` が現在の `I18n`（および必要なら `locale`）を監視して、言語変更で再ビルドされるようにする。`MaterialApp.title` はアプリ名 `Board Game Shelf` のまま固定でよい。

> 反映タイミングは**即時反映**を採用（選んだ瞬間に画面が切り替わる）。再起動方式にはしないこと。`NotifierProvider`＋`MaterialApp`の購読で実現できる。

### フォールバック挙動（確定仕様）
現状の `ja.json` / `en.json` のみがある場合:
- システム言語が**日本語** → 日本語
- システム言語が**英語** → 英語
- システム言語が**それ以外（仏・独・中・韓など）** → **英語**（既定フォールバック）
- `en.json` が存在しない場合 → 一覧先頭（保険）

---

## タスク4: 設定画面に言語セクションを追加（UI）
`SettingsPage` に既存パターンに沿った「言語」セクションを追加する。配置はトークン等より上（画面先頭）が望ましいが、既存セクションのスタイル（見出し `titleMedium` ＋ `Divider(height:32)` 区切り）に合わせること。

1. 見出し: `t.t('settings.language')`
2. 選択UI: `localeOptionsProvider` の一覧 ＋ 先頭に「システムに従う」項目を加えた `DropdownButton`（または `RadioListTile` 群）。現在の有効選択を初期値表示。
3. 選択変更で `languagePreferenceProvider` の `select()/useSystem()` を呼ぶ。即時にUI文言が切り替わることを確認（`SettingsPage` 自身の文言も切り替わる）。
4. ローディング/エラー状態（カタログ未ロード時）を `AsyncValue` で適切に処理。
5. 新規i18nキーを `ja.json` / `en.json` 両方に追加: `settings.language`（例 "言語" / "Language"）、`settings.languageSystem`（"システムに従う" / "Follow system"）。両ファイルでキー構造を一致させること。

---

## タスク5: ドキュメント更新
- `README.md` / `README.ja.md` の Localization / 多言語化 節を、実装後の挙動に更新:
  - システム追従がデフォルトで、設定画面から手動選択できる
  - 日本語・英語以外のシステム言語のときは英語にフォールバックする
  - `assets/i18n/` に `_meta` 付きJSONを追加すれば選択肢に自動で出る
  - `pubspec.yaml` はフォルダ指定済みなので個別列挙の追記は不要になった旨
- 旧記述（「日本語固定」「main.dartでパス変更」「個別列挙が必要」）は削除・修正すること。

---

## 実装順序
タスク0（方式決定＋pubspec/assets変更＋_meta付与）→ タスク1（カタログ）→ タスク2（永続化）→ タスク3（providers/main/app）→ タスク4（設定UI）→ タスク5（README）

## 完了条件
- `assets/i18n/` にJSONを追加するだけで設定画面の選択肢に表示される
- 「システムに従う」で端末言語に追従し、一致が無ければ英語にフォールバック（英語も無ければ一覧先頭）
- 手動選択が即時にUIへ反映され、再起動後も保持される
- `_meta` の有無どちらのファイルも扱える
- フォールバック先言語コードが定数1か所で定義されている
- 新規ユニットテスト（カタログ列挙・フォールバック・永続化）追加、既存テスト緑
- 言語設定は `shared_preferences`、秘密情報は `SecureSettings` のまま分離
- 各タスク独立コミット、メッセージにタスク番号を記載
