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
