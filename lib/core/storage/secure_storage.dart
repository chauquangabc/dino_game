import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureStorage {
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  factory SecureStorage() => instance;

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() async =>
      await _storage.read(key: _refreshTokenKey);

  Future<void> writeAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> writeRefreshToken(String token) {
    return _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);

    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<void> deleteAccessToken() async =>
      _storage.delete(key: _accessTokenKey);

  Future<void> deleteRefreshToken() async =>
      _storage.delete(key: _refreshTokenKey);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
