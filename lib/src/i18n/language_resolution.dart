import '../core/constants.dart';
import 'language_preference_repository.dart';
import 'locale_option.dart';

LocaleOption resolveLocaleOption({
  required String preference,
  required List<LocaleOption> options,
  required List<String> systemLocaleCodes,
}) {
  if (options.isEmpty) {
    throw StateError('No locale bundles are available.');
  }

  if (preference != LanguagePreferenceRepository.systemValue) {
    return _findByCode(options, preference) ?? _fallback(options);
  }

  for (final code in systemLocaleCodes) {
    final exact = _findByCode(options, code);
    if (exact != null) {
      return exact;
    }
    final languageCode = code.split(RegExp('[-_]')).first;
    final languageMatch = _findByCode(options, languageCode);
    if (languageMatch != null) {
      return languageMatch;
    }
  }
  return _fallback(options);
}

LocaleOption? _findByCode(List<LocaleOption> options, String code) {
  for (final option in options) {
    if (option.localeCode.toLowerCase() == code.toLowerCase()) {
      return option;
    }
  }
  return null;
}

LocaleOption _fallback(List<LocaleOption> options) {
  return _findByCode(options, AppConstants.fallbackLocaleCode) ?? options.first;
}
