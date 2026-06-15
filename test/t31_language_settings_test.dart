import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bg_shelf_scanner/src/app/providers.dart';
import 'package:bg_shelf_scanner/src/i18n/language_catalog.dart';
import 'package:bg_shelf_scanner/src/i18n/language_preference_repository.dart';
import 'package:bg_shelf_scanner/src/i18n/language_resolution.dart';
import 'package:bg_shelf_scanner/src/i18n/locale_option.dart';

void main() {
  test(
    'loads locale catalog from direct i18n json assets with meta fallback',
    () async {
      final catalog = LanguageCatalog(
        loadAssetPaths: () async => const [
          'assets/i18n/ja.json',
          'assets/i18n/en.json',
          'assets/i18n/nested/ignored.json',
          'assets/i18n/readme.txt',
          'assets/other/fr.json',
        ],
        loadString: (path) async {
          return switch (path) {
            'assets/i18n/ja.json' => '{"_meta":{"locale":"ja","name":"日本語"}}',
            'assets/i18n/en.json' => '{"common":{"save":"Save"}}',
            _ => '{}',
          };
        },
      );

      final options = await catalog.load();

      expect(options.map((option) => option.assetPath), [
        'assets/i18n/en.json',
        'assets/i18n/ja.json',
      ]);
      expect(options.first.localeCode, 'en');
      expect(options.first.displayName, 'en');
      expect(options.last.localeCode, 'ja');
      expect(options.last.displayName, '日本語');
    },
  );

  test('resolves selected system language then falls back to English', () {
    const options = [
      LocaleOption(
        assetPath: 'assets/i18n/en.json',
        localeCode: 'en',
        displayName: 'English',
      ),
      LocaleOption(
        assetPath: 'assets/i18n/ja.json',
        localeCode: 'ja',
        displayName: '日本語',
      ),
    ];

    expect(
      resolveLocaleOption(
        preference: LanguagePreferenceRepository.systemValue,
        options: options,
        systemLocaleCodes: const ['ja-JP'],
      ).localeCode,
      'ja',
    );
    expect(
      resolveLocaleOption(
        preference: LanguagePreferenceRepository.systemValue,
        options: options,
        systemLocaleCodes: const ['fr-FR'],
      ).localeCode,
      'en',
    );
    expect(
      resolveLocaleOption(
        preference: 'ja',
        options: options,
        systemLocaleCodes: const ['en-US'],
      ).localeCode,
      'ja',
    );
  });

  test('persists language preference outside secure settings', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LanguagePreferenceRepository(preferences: preferences);

    expect(await repository.read(), isNull);

    await repository.save('en');
    expect(await repository.read(), 'en');

    await repository.save(LanguagePreferenceRepository.systemValue);
    expect(await repository.read(), LanguagePreferenceRepository.systemValue);

    await repository.clear();
    expect(await repository.read(), isNull);
  });

  testWidgets('bootstraps selected language into the active i18n provider', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'languagePreference': 'en'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final i18n = await container.read(languageBootstrapProvider.future);

    expect(i18n.t('settings.language'), 'Language');
    expect(
      container.read(i18nProvider).t('settings.languageSystem'),
      'Follow system',
    );
    expect(container.read(currentLocaleCodeProvider), 'en');
  });
}
