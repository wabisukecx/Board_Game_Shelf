import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../lib/src/core/constants.dart';
import '../lib/src/i18n/i18n.dart';

void main() {
  test('loads dotted i18n keys and replaces variables', () {
    final source = File('assets/i18n/ja.json').readAsStringSync();
    final i18n = I18n.fromJsonString(source);

    expect(i18n.t('search.title'), 'ゲームを検索');
    expect(i18n.t('missing.key'), 'missing.key');
    expect(i18n.t('search.resultCount', {'count': 3}), '3件');
    expect(i18n.t('settings.tokenApprovalNotice'), '承認に1週間以上かかる場合があります。');
    expect(
      i18n.t('analysis.narrativeLearningCurve', {'type': 'ルールはすぐに覚えられます。'}),
      '学習曲線: ルールはすぐに覚えられます。',
    );
    expect(
      i18n.t('analysis.narrativeMasteryTime', {'masteryTime': '短い'}),
      'ゲームに慣れて、安定して良い判断ができるようになるまでの目安は短いです。',
    );
    expect(
      i18n.t('analysis.narrativeDepthReplay', {'depth': '深い', 'replay': '高い'}),
      '戦略の深さは深いです。リプレイ性は高いです。',
    );
  });

  test('defines phase 0 constants in one place', () {
    expect(AppConstants.bggThingRateLimitPerMinute, 15);
    expect(AppConstants.bggSearchRateLimitPerMinute, 20);
    expect(AppConstants.thingCacheTtl, const Duration(hours: 48));
    expect(AppConstants.searchCacheTtl, const Duration(hours: 24));
    expect(AppConstants.numericDiffTolerance, 1e-6);
    expect(AppConstants.localIdPrefix, 'L');
    expect(AppConstants.localIdDigits, 5);
  });
}
