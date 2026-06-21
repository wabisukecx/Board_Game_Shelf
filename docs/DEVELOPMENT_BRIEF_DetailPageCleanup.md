# Board Game Shelf 改修ブリーフ：ゲーム詳細画面の表示改善（学習分析の文章化／説明欄整理／日本語フォント修正）（Codex向け）

## 前提・対象
- 対象: `C:\Users\tucon\StudioProjects\bg_shelf_scanner`（Flutter / Riverpod / Drift）
- 本ブリーフは独立した3つの改修をまとめたもの。タスクのグループごとに別コミットにしてよい（むしろ推奨）。
- **「情報更新」ボタンと「拡張候補を確認」ボタンは残す**。今回のどの変更でも削除・変更しないこと（タスク2でWrap内の隣接ボタンを編集する際に誤って巻き込まないこと）。
- 各タスク完了時に `flutter analyze` と `flutter test` を実行する。

---

## グループA: 学習分析セクションを文章化する

### 背景・原因
`lib/src/ui/pages/game_detail_page.dart` の `_AnalysisSection` で、以下の4つの値をラベルなしのChipとして並べているだけだった:
```dart
Chip(label: Text(t.t('learning_curve.types.${analysis.learningCurveType}'))),
Chip(label: Text(t.t('mastery_time.${analysis.masteryTime}'))),
Chip(label: Text(t.t('analysis.depth.${analysis.strategicDepthLabel}'))),
Chip(label: Text(t.t('replayability.${analysis.replayabilityLabel}'))),
```
4つとも別々の軸（学習曲線タイプ／習熟時間／戦略深度／リプレイ性）の値だが、どの軸の値かを示すラベルが一切無いため、「緩やかで中程度」「中程度」とだけ見せられても何の指標か分からない。値自体は下に表示されている10指標バー（`initialBarrier`/`strategicDepth`等）から導出済みのもので、**新しい計算ロジックは不要**。UI表示を「どの軸の話か分かる文章」に組み替えるだけでよい。

### タスクA1: `learning_curve.types.*` の文言を「短いラベル」から「説明文」に差し替え（`assets/i18n/ja.json`, `assets/i18n/en.json`）
9パターンの**値テーブルの中身だけ**を、ユーザー確定済みの文言に差し替える（キー構造・呼び出し側コードは変更不要）。「初期ハードル」「戦略深度」という言葉自体を使わず、「最初の覚えやすさ」と「慣れたあとの深さ」を平易な日本語で説明する文にする。

`learning_curve.types`（ja）を以下に置き換える:
```json
"steep": "最初は覚えることが多くて大変な上に、慣れてからも奥が深く、極めるまで時間がかかります。",
"steep_then_moderate": "最初は覚えることが多くて大変ですが、深さ自体はそこまで底なしではありません。",
"steep_then_shallow": "最初は覚えることが多い割に、慣れてしまえば打ち手のパターンは限られています。",
"moderate_then_deep": "覚えることはそれなりにありますが、突き詰めるほど奥が深く、長く遊んでも飽きません。",
"moderate": "覚えることも深さも、ちょうど中くらいです。気負わず遊びながら上達できます。",
"moderate_then_shallow": "覚えることはそれなりにありますが、慣れてしまえば打ち手のパターンはそれほど多くありません。",
"gentle_then_deep": "ルールはすぐに覚えられますが、突き詰めるほど奥が深く、長く遊んでも新しい発見があります。",
"gentle_then_moderate": "ルールはすぐに覚えられて、深さもほどよくあります。気軽に始めて少しずつ戦略を深められます。",
"gentle": "ルールはすぐに覚えられ、戦略もシンプルです。気軽に何度でも遊べます。"
```
`learning_curve.types`（en、対応する内容）:
```json
"steep": "There's a lot to learn at first, and it stays deep once you're comfortable with it — mastering it takes real time.",
"steep_then_moderate": "There's a lot to learn at first, but the depth itself isn't bottomless.",
"steep_then_shallow": "There's a lot to learn at first, but once you're comfortable, there isn't a huge range of viable plays.",
"moderate_then_deep": "There's a fair amount to learn, but it keeps getting deeper the more you play — you won't run out of new things to discover.",
"moderate": "Both the learning curve and the depth are middle-of-the-road — easy to pick up and improve at gradually.",
"moderate_then_shallow": "There's a fair amount to learn, but once you're comfortable, there isn't a huge range of strategies to explore.",
"gentle_then_deep": "The rules are easy to pick up, but it keeps getting deeper the more you play.",
"gentle_then_moderate": "The rules are easy to pick up, with a reasonable amount of depth to grow into.",
"gentle": "The rules are easy to pick up and the strategy stays simple — easy to enjoy again and again."
```
`analysis.depth.*` / `replayability.*` の値テーブルは**変更しない**（こちらは短いラベルのままでよいとユーザー確定済み）。

### タスクA2: i18nテンプレート追加（`assets/i18n/ja.json`, `assets/i18n/en.json`）
`analysis` セクションに以下3キーを追加する:
- `analysis.narrativeLearningCurve`
  - ja: `"学習曲線: {type}"`
  - en: `"Learning curve: {type}"`
- `analysis.narrativeMasteryTime`
  - ja: `"ゲームに慣れて、安定して良い判断ができるようになるまでの目安は{masteryTime}です。"`
  - en: `"{masteryTime} — roughly how long it takes to start making consistently good decisions once you're comfortable with the rules."`
- `analysis.narrativeDepthReplay`
  - ja: `"戦略の深さは{depth}です。リプレイ性は{replay}です。"`
  - en: `"Strategic depth is {depth}. Replayability is {replay}."`

**注意（文法的安全性）**: `analysis.depth.*` / `replayability.*` の値（例: 「やや深い」「中程度」）を文中で活用変化させて埋め込む書き方（連用形に変えて接続する等）は、語尾パターンが多く自動生成では活用ミスが起きやすい。`analysis.narrativeDepthReplay` は**必ず「{ラベル}は{値}です。」の文を2つ並べる形**にし、値を活用させないこと。`learning_curve.types.*` はタスクA1で既に完全な文として作成済みなので、`analysis.narrativeLearningCurve` 側はラベルを前置するだけでよい。

### タスクA3: `game_detail_page.dart` の表示を差し替え
`_AnalysisSection.build()` 内、4つのChipの `Wrap` を削除し、代わりに以下のような `Text` 3つに置き換える:
```dart
Text(
  t.t('analysis.narrativeLearningCurve', {
    'type': t.t('learning_curve.types.${analysis.learningCurveType}'),
  }),
),
const SizedBox(height: 4),
Text(
  t.t('analysis.narrativeMasteryTime', {
    'masteryTime': t.t('mastery_time.${analysis.masteryTime}'),
  }),
),
const SizedBox(height: 4),
Text(
  t.t('analysis.narrativeDepthReplay', {
    'depth': t.t('analysis.depth.${analysis.strategicDepthLabel}'),
    'replay': t.t('replayability.${analysis.replayabilityLabel}'),
  }),
),
const SizedBox(height: 8),
```
- 配置場所（10指標バーの直前）は変更しない。10指標バー（`_MetricBar`）とプレイヤータイプ行（`カジュアル / 経験者 / ...`）はそのまま残す。

### （任意・今回は実装不要）将来的な拡張案
10指標のうち特に高い/低い指標を名指しする一文（例:「特に意思決定量(4.34)が高く、メカニクス複雑度(2.93)は控えめです。」）を追加すると、より「グラフから読み取れる」内容になる。ただし最大/最小の選定・同値時のタイブレーク等の設計が必要になるため、今回のスコープには含めない。要望があれば別ブリーフで対応する。

---

## グループB: 説明欄・「説明を翻訳」ボタンをUIから外す（データは保持）

### 方針
`description`（BGG原文の英語説明）・`descriptionJa`（翻訳済み日本語説明）は、DBカラム・YAMLエクスポートともに**そのまま維持する**（削除しない）。翻訳バックエンド（`DescriptionTranslationRepository` / `GeminiTranslationClient` / `descriptionTranslationRepositoryProvider` 等）も削除しない。**`game_detail_page.dart` の表示と、それを操作するボタンだけを外す。**

### タスクB1: 説明欄の表示ブロックを削除
`_buildBody()` 内の以下2ブロックを削除する:
```dart
if (game.description != null && game.description!.isNotEmpty) ...[
  const SizedBox(height: 8),
  Text(t.t('detail.description'), style: Theme.of(context).textTheme.labelLarge),
  Text(game.description!),
],
if (game.descriptionJa != null && game.descriptionJa!.isNotEmpty) ...[
  const SizedBox(height: 8),
  Text(t.t('detail.descriptionJa'), style: Theme.of(context).textTheme.labelLarge),
  Text(game.descriptionJa!),
],
```

### タスクB2: 「説明を翻訳」ボタンを削除
1. アクション `Wrap`（「情報更新」ボタンと同じ場所）から、以下の条件分岐ボタンのみを削除する。**「情報更新」ボタン（`_runInfoUpdate`）はこの直前にあるが、絶対に削除・変更しないこと**:
   ```dart
   if (isBgg && game.description != null && game.description!.isNotEmpty)
     OutlinedButton.icon(
       onPressed: _busy ? null : _translate,
       icon: const Icon(Icons.translate),
       label: Text(t.t('detail.translate')),
     ),
   ```
2. 呼び出し元が無くなる `_translate()` メソッド本体を `_GameDetailPageState` から削除する（`flutter analyze` の未使用警告防止）。
3. `_translate()` だけで使われていた `import '../../data/translation/gemini_translation_service.dart';` も、他に使用箇所が無ければ削除する（`DescriptionTranslationStatus` 等の参照が無くなることを確認してから）。
4. `descriptionTranslationRepositoryProvider`（`lib/src/app/providers.dart`）・`DescriptionTranslationRepository`・`GeminiTranslationClient` 等のファイル自体は**削除しない**（将来的な再利用や既存テストのために温存する）。

### 確認事項
- `detail.description` / `detail.descriptionJa` / `detail.translate` / `detail.translated` 等のi18nキーは、JSON内に残っていても `flutter analyze` の警告対象にはならないため、削除は任意（削除してもよいが必須ではない）。
- `t08_information_update_repository_test.dart` 等、情報更新の差分プレビュー（`_confirmChanges`）に関するテストは今回のスコープ外。説明文のフィールド自体は引き続き取得・保存されるため、影響しないはず。念のため既存テストが green であることを確認する。

---

## グループC: 日本語フォント／字形（Han Unification）の修正

### 背景・原因
`lib/src/app/app.dart` の `MaterialApp` には `locale: localeCode == null ? null : Locale(localeCode)` のみが設定されており、**`localizationsDelegates` と `supportedLocales` が未設定**。`pubspec.yaml` にも `flutter_localizations` が依存関係として入っていない。

これにより、ロケール情報がアプリ全体（特にプラットフォームのテキストレンダリング層）に正しく伝播せず、日本語と簡体字で字形が異なる統合漢字（Han Unification対象。例: 「情」「直」「確」等）が、日本語フォントの字形ではなく中国語フォットの字形で描画されることがある（「情報更新」の「情」が中華フォントに見える、というご指摘はこれに該当する可能性が高い）。

### タスクC1: `flutter_localizations` を依存関係に追加
`pubspec.yaml` の `dependencies:` に追加する:
```yaml
  flutter_localizations:
    sdk: flutter
```
追加後 `flutter pub get` を実行する。

### タスクC2: `MaterialApp` に `localizationsDelegates` / `supportedLocales` を設定
`lib/src/app/app.dart` を以下のように変更する:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

...

return MaterialApp(
  title: 'Board Game Shelf',
  debugShowCheckedModeBanner: false,
  locale: localeCode == null ? null : Locale(localeCode),
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('ja'),
    Locale('en'),
  ],
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F7A8C)),
    useMaterial3: true,
  ),
  ...
);
```
- `supportedLocales` は現状 `assets/i18n/` にある `ja.json` / `en.json` に合わせて `ja` / `en` の2件とする。将来 `assets/i18n/` に言語を追加する際は、このリストにも追記する必要がある旨をコード上にコメントで残しておくこと（`LanguageCatalog` はアセットから動的に言語一覧を読むが、`MaterialApp.supportedLocales` は同期的に必要なため、現状は静的リストで揃える設計とする）。

### タスクC3: 既存テストへの影響確認
`localizationsDelegates` 追加により、`flutter_test` 内でMaterial標準ウィジェット（日付選択・テキスト選択ツールバー等）に依存する既存テストの挙動が変わる可能性はゼロではない。`flutter test` を実行し、失敗があれば原因を確認のうえ修正する（基本的には改善方向の変更なので、失敗は想定していない）。

### 手動確認（実機が必要なため、Codexでの自動確認は不可。ユーザー側で確認）
修正後、実機（Galaxy S25等）で「情報更新」ボタンの「情」を含め、画面全体の漢字表示が日本語フォントの字形になっているか確認する。もし改善しない場合は、特定のテキストウィジェットに `TextStyle(locale: Locale('ja'))` を明示する、またはアプリ全体のフォントに日本語対応フォント（Noto Sans JP等）を `ThemeData.fontFamily` で指定する、という追加対応を別途検討する。

---

## グループD: 学習分析エンジン（`learning_curve.dart`）の計算ロジック修正

### 背景
コードレビューで以下5点の問題を確認済み。いずれも`Game`テーブルに保存されず毎回動的に計算される値なので、データ移行は不要。`test/t19_learning_curve_test.dart` は `strategicDepth`/`replayability`/`decisionPoints`/`interactionComplexity`/`rulesComplexity` の**正確な値をピンしていない**（`inInclusiveRange(1.0, 5.0)` のに）ため、以下の修正で既存テストが壊れる可能性は低い。

### タスクD1: 戦略深度の `weight` 二重カウントとプレイ時間補正の三重掛けを整理
`_calculateStrategicDepth` 内の `strategicDepth` 計算式が以下の2点で問題:
1. `weight * 0.20` と `weight * 0.10` が別々の項として足されており、実質 `weight * 0.30` と同じだが意図不明な二重記述になっている（他の4項の重みは0.35+0.10+0.25+0.20+0.10=1.00なので、「本来weightは0.30で1項にまとめるつもりだった」と解釈するのが最も自然）。
2. `decisionPoints`と`interactionComplexity`はそれぞれの内部計算で既に `playtime.complexityFactor` による補正を受けており（`_estimateDecisionPoints`/`_estimateInteractionComplexity`内）、その2つを含む `strategicDepth` 合計値全体にさらに同じ `playtime.complexityFactor` を最後にもう一度掛けているため、プレイ時間の影響が二重（`weight`/`rulesComplexity`部分には本来不要な補正まで）になっている。

修正: 以下のコードブロック
```dart
final strategicDepth =
    (weight * 0.20 +
        decisionPoints * 0.35 +
        rulesComplexity * 0.10 +
        interactionComplexity * 0.25 +
        weight * 0.10 +
        math.min(0.4, strategyBonus) +
        math.min(0.1, playtime.strategicBonus * 0.6) +
        hiddenInfoBonus) *
    (1.0 + (playtime.complexityFactor - 1.0) * 0.95);
```
を以下に差し替える:
```dart
final strategicDepth =
    weight * 0.30 +
        decisionPoints * 0.35 +
        rulesComplexity * 0.10 +
        interactionComplexity * 0.25 +
        math.min(0.4, strategyBonus) +
        math.min(0.1, playtime.strategicBonus * 0.6) +
        hiddenInfoBonus;
```
（`weight`の項を2つから1つに統合し、末尾の `* (1.0 + (playtime.complexityFactor - 1.0) * 0.95)` を削除。`decisionPoints`/`interactionComplexity`自体の内部補正はそのまま残すので、それら単体の表示値（「意思決定量」「相互作用の複雑さ」）は影響を受けない）。直後の `roundScore(clampScore(strategicDepth))` はそのままでよい。

### タスクD2: 習熟時間のメカニクス数分岐が逆転している件を修正
`_masteryTime` で `strategicDepth > 4.3` の分岐が、メカニクス数が多いほど習熟時間が短く評価される逆転した状態になっている。さらに2番目の閾値 `3.2` が、`strategicDepthLabel`や`_learningCurveType`が使う `3.5` と不一致。

修正前:
```dart
String _masteryTime({
  required double initialBarrier,
  required double strategicDepth,
  required int mechanicCount,
}) {
  if (strategicDepth > 4.3) {
    return mechanicCount >= 6 ? 'medium_to_long' : 'long';
  }
  if (strategicDepth > 3.2) {
    return initialBarrier > 4.0 ? 'medium_to_long' : 'medium';
  }
  return initialBarrier > 4.0 ? 'medium' : 'short';
}
```
修正後:
```dart
String _masteryTime({
  required double initialBarrier,
  required double strategicDepth,
  required int mechanicCount,
}) {
  if (strategicDepth > 4.3) {
    return mechanicCount >= 6 ? 'long' : 'medium_to_long';
  }
  if (strategicDepth > 3.5) {
    return initialBarrier > 4.0 ? 'medium_to_long' : 'medium';
  }
  return initialBarrier > 4.0 ? 'medium' : 'short';
}
```
（メカニクス数分岐の戻り値を入れ替えて「多いほど長い」に修正。閾値3.2を3.5に統一）。

### タスクD3: リプレイ性の「古さボーナス」を現在もランクされているゲームに限定
`_longevityFactor` が発売年が古いだけで無条件にボーナスを付けている（評価の質を一切見ていない）。BGG順位が付いている（=現在も一定の人気を保っている）ゲームのみに長期ボーナスを適用するようにゲートする。

`_calculateReplayability` 内:
```dart
final replayability =
    (2.0 + diversityScore + rankBonus) *
        _longevityFactor(_yearPublished(game)) +
    playtimeReplayBonus;
```
を以下に差し替える（`rank` ローカル変数はすでに同じメソッド内に存在するのでそのまま使う）:
```dart
final replayability =
    (2.0 + diversityScore + rankBonus) *
        _longevityFactor(_yearPublished(game), isRanked: rank != null) +
    playtimeReplayBonus;
```
`_longevityFactor` の定義を以下に変更:
```dart
double _longevityFactor(int? yearPublished, {required bool isRanked}) {
  if (yearPublished == null || !isRanked) {
    return 1.0;
  }
  final years = clock.now().year - yearPublished;
  if (years >= 20) {
    return 1.1;
  }
  if (years >= 10) {
    return 1.07;
  }
  if (years >= 5) {
    return 1.05;
  }
  return 1.0;
}
```
**注意**: `test/t19_learning_curve_test.dart` の `'longevity factor uses injected clock instead of wall clock'` テストは `ranks: GameRanks([GameRank(type: 'boardgame', rank: '1000')])` を指定しているので `rank != null` は成立し、このテストは修正後もそのまま green のはず。必ず実行して確認すること。

### タスクD4: 新規テスト追加
`test/t19_learning_curve_test.dart` に、以下の振る舞いを検証するテストを追加する。式が多段階で手計算が難しいため、**正確な数値をピンするのではなく、相対比較・振る舞いの有無で検証する**方針とする:
1. **weight二重カウントの回帰防止**: 他の条件を全て同じにし、`weight` のみ異なる2ゲーム（例: 2.0 と 5.0）を作り、`strategicDepth`の差がおおよそ `(5.0-2.0) * 0.30 = 0.9` 付近（上限クリップにかからない範囲で）になることを確認する（以前の二重カウントだと約倍の差になっていたはず）。
2. **習熟時間のメカニクス数分岐**: `strategicDepth > 4.3` となるようなゲームを作り、メカニクス数が6以上のケースと未満のケースで `masteryTime` を比較し、前者が `'long'`、後者が `'medium_to_long'` になることを確認する。
3. **閾値統一**: `strategicDepth` がおおよそ3.3〜3.4の範囲になるようなゲームを作り（計算式を逆算して調整）、`masteryTime` が `strategicDepthLabel` と同じ 3.5 を境目に振る舞うことを確認する。
4. **ランクゲート**: 同一の古い `yearPublished`・同一の`mechanics`/`categories`で、`ranks` が空（`GameRanks([])`）のゲームと `ranks` が付いているゲームを比較し、**ランクが無い方は古さボーナスが乗らない**（`years>=5`の年数差をつけても `replayability` が変わらない）ことを確認する。

既存テスト（`t19_learning_curve_test.dart` 3件）は修正不要で green のはずだが、必ず `flutter test` で確認する。

### タスクD5: 手動確認
修正前後で実際のゲームデータ（いくつか手元のコレクションから重いゲーム・軽いゲーム・プレイ時間が極端に長い/短いゲームなど）で `analyze()` の出力を見比べ、以前と比べて不自然な値がないかを目視で確認する（自動テストだけでは検出しづらい、組み合わせによる不自然な値の有無を確認するため）。

---

## 実装順序
グループA → グループB → グループC → グループD（互いに独立しているため順不同でも可。グループDはさらにD1→D2→D3を小さく別コミットに分けることを推奨。基本的に1グループ＝1コミット以上を推奨）

## 完了条件
- ゲーム詳細画面の「学習分析」セクションで、4つの値が「どの指標の話か」分かる文章として表示される（10指標バー・プレイヤータイプ行は従来通り）
- 説明欄（英語原文・日本語訳）の表示と「説明を翻訳」ボタンが画面から消えている。`description`/`descriptionJa` はDB・YAMLエクスポートには引き続き保存される
- 「情報更新」ボタン・「拡張候補を確認」ボタンは変更前と同じ位置・同じ動作で残っている
- `pubspec.yaml` に `flutter_localizations` が追加され、`MaterialApp` に `localizationsDelegates` / `supportedLocales`（ja, en）が設定されている
- 戦略深度計算で `weight` が二重カウントされず、プレイ時間補正が三重に掛からない
- 習熟時間のメカニクス数分岐が「多いほど長い」に修正され、閾値が3.5に統一されている
- リプレイ性の古さボーナスが、BGG順位が付いていない（未ランクの）ゲームには適用されない
- `t19_learning_curve_test.dart` の既存テストが green、タスクD4の新規テストが追加されている
- `flutter analyze` 警告ゼロ、`flutter test` 全件パス
- 各グループ独立コミット、メッセージにグループ名を記載
