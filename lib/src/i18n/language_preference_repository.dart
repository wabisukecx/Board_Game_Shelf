import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreferenceRepository {
  const LanguagePreferenceRepository({required SharedPreferences preferences})
    : _preferences = preferences;

  static const systemValue = 'system';
  static const _key = 'languagePreference';

  final SharedPreferences _preferences;

  Future<String?> read() async {
    final value = _preferences.getString(_key);
    return value == null || value.trim().isEmpty ? null : value;
  }

  Future<void> save(String value) async {
    await _preferences.setString(_key, value.trim());
  }

  Future<void> clear() async {
    await _preferences.remove(_key);
  }
}
