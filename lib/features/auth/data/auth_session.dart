import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the session token in the platform keystore/keychain — unlike the
/// (unencrypted) Hive boxes used for the rest of local state, this is where
/// a JWT belongs.
class AuthSession {
  static const _tokenKey = 'auth_token';
  static const _storage = FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
