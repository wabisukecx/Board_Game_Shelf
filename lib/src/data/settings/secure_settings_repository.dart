import 'dart:math';

import '../bgg/bgg_token_provider.dart';
import 'secret_store.dart';
import 'secure_setting_keys.dart';

class SecureSettingsRepository implements BggTokenProvider {
  const SecureSettingsRepository({required SecretStore secretStore})
    : _secretStore = secretStore;

  final SecretStore _secretStore;

  Future<void> saveBggBearerToken(String token) {
    return _writeOrDelete(SecureSettingKeys.bggBearerToken, token);
  }

  @override
  Future<String?> readToken() {
    return _secretStore.read(SecureSettingKeys.bggBearerToken);
  }

  Future<void> deleteBggBearerToken() {
    return _secretStore.delete(SecureSettingKeys.bggBearerToken);
  }

  Future<void> saveBggUsername(String username) {
    return _writeOrDelete(SecureSettingKeys.bggUsername, username);
  }

  Future<String?> readBggUsername() {
    return _secretStore.read(SecureSettingKeys.bggUsername);
  }

  Future<void> deleteBggUsername() {
    return _secretStore.delete(SecureSettingKeys.bggUsername);
  }

  Future<void> saveGeminiApiKey(String apiKey) {
    return _writeOrDelete(SecureSettingKeys.geminiApiKey, apiKey);
  }

  Future<String?> readGeminiApiKey() {
    return _secretStore.read(SecureSettingKeys.geminiApiKey);
  }

  Future<void> deleteGeminiApiKey() {
    return _secretStore.delete(SecureSettingKeys.geminiApiKey);
  }

  Future<String> readOrCreateGameUpcUserId() async {
    final existing = await _secretStore.read(SecureSettingKeys.gameUpcUserId);
    if (existing != null && existing.length >= 8) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final generated =
        'bgshelf-${bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}';
    await _secretStore.write(SecureSettingKeys.gameUpcUserId, generated);
    return generated;
  }

  Future<void> _writeOrDelete(String key, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return _secretStore.delete(key);
    }
    return _secretStore.write(key, trimmed);
  }
}

class TokenAcquisitionGuide {
  const TokenAcquisitionGuide();

  String get bggTokenUrl => 'https://boardgamegeek.com/applications';

  String get approvalNoticeKey => 'settings.tokenApprovalNotice';

  String get keyNotBundledPolicyKey => 'settings.keyNotBundledPolicy';
}
