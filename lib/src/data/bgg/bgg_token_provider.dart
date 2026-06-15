import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../settings/secure_setting_keys.dart';

abstract interface class BggTokenProvider {
  Future<String?> readToken();
}

class SecureStorageBggTokenProvider implements BggTokenProvider {
  SecureStorageBggTokenProvider({
    FlutterSecureStorage? storage,
    this.key = SecureSettingKeys.bggBearerToken,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final String key;

  @override
  Future<String?> readToken() => _storage.read(key: key);
}

class EmptyBggTokenProvider implements BggTokenProvider {
  const EmptyBggTokenProvider();

  @override
  Future<String?> readToken() async => null;
}
