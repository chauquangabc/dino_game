import '../storage/secure_storage.dart';

class SessionManager {
  final SecureStorage _storage;

  SessionManager(this._storage);

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  Future<void> initialize() async {
    final tokens = await Future.wait([
      _storage.readAccessToken(),
      _storage.readRefreshToken(),
    ]);

    _accessToken = tokens[0];
    _refreshToken = tokens[1];
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<void> clearSession() async {
    await _storage.clearSession();
    _accessToken = null;
    _refreshToken = null;
  }
}
