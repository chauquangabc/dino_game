import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  SecureStorage._({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static final SecureStorage instance = SecureStorage._();

  factory SecureStorage() => instance;

  /// Constructor dành cho unit test, cho phép truyền secure storage đã mock.
  factory SecureStorage.withStorage(FlutterSecureStorage storage) {
    return SecureStorage._(storage: storage);
  }

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> writeAccessToken(String token) {
    _validateToken(token, 'accessToken');
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> writeRefreshToken(String token) {
    _validateToken(token, 'refreshToken');
    return _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _validateToken(accessToken, 'accessToken');
    _validateToken(refreshToken, 'refreshToken');

    // Ghi refresh token trước để tránh access token mới đi cùng refresh token cũ.
    await writeRefreshToken(refreshToken);
    await writeAccessToken(accessToken);
  }

  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);

  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshTokenKey);

  /// Chỉ xóa dữ liệu phiên đăng nhập, không xóa các secret khác của ứng dụng.
  Future<void> clearSession() => Future.wait([
    deleteAccessToken(),
    deleteRefreshToken(),
  ]);

  // Alias tương thích với API cũ. Có thể xóa sau khi đã migrate nơi sử dụng.
  Future<String?> getToken() => readAccessToken();
  Future<String?> getRefreshToken() => readRefreshToken();
  Future<void> setToken(String token) => writeAccessToken(token);
  Future<void> setRefreshToken(String token) => writeRefreshToken(token);
  Future<void> clearToken() => deleteAccessToken();
  Future<void> clearRefreshToken() => deleteRefreshToken();
  Future<void> clearAll() => clearSession();

  void _validateToken(String token, String name) {
    if (token.trim().isEmpty) {
      throw ArgumentError.value(token, name, 'Token không được để trống.');
    }
  }
}
