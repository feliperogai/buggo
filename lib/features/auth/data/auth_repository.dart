import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env_config.dart';
import '../../../core/net/server_diagnostics.dart';
import '../../../shared/models/user_profile.dart';
import 'auth_session.dart';

/// Thrown when a backend auth call fails with a user-facing message (bad
/// credentials, email already registered, invalid/expired reset link, ...).
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Thrown only when the request never reached the backend — no internet,
/// DNS/TLS failure, timeout. Kept separate from [AuthException] so the UI
/// stops blaming the connection for errors that happened *after* the server
/// answered (that was hiding the real cause of login failures).
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Vercel API in front of Neon Postgres — the app never
/// connects to Postgres directly. See `server/README.md`.
class AuthRepository {
  final _session = AuthSession();

  /// Injectable so the error-classification paths can be tested; defaults to
  /// the same client `http.post`/`http.get` use internally.
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  bool get isConfigured => EnvConfig.isApiConfigured;

  Uri _uri(String path) => Uri.parse('${EnvConfig.apiBaseUrl}$path');

  /// Single entry point for every backend call: turns "never reached the
  /// server" into [NetworkException] and everything else into an
  /// [AuthException] that names the real cause, instead of letting the UI's
  /// generic catch report all of them as "verifique sua internet".
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    if (!isConfigured) {
      throw AuthException(
        'Esta build não tem URL de API para chamar.',
      );
    }
    try {
      return await call().timeout(const Duration(seconds: 20));
    } on SocketException catch (e) {
      throw NetworkException(
        'Sem conexão com o servidor (${e.osError?.message ?? e.message}).',
      );
    } on HandshakeException catch (e) {
      throw NetworkException('Falha de TLS ao falar com o servidor: ${e.message}');
    } on TimeoutException {
      throw NetworkException('O servidor demorou mais de 20s para responder.');
    } on http.ClientException catch (e) {
      throw NetworkException('Falha de rede: ${e.message}');
    }
  }

  /// Decodes a JSON body. Quando o servidor não respondeu JSON,
  /// [ServerDiagnostics] nomeia o motivo — foi assim que a Deployment
  /// Protection da Vercel deixou de aparecer como um 'erro inesperado'.
  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException(
        ServerDiagnostics.describeNonJson(response) ??
            'Resposta inesperada do servidor (HTTP ${response.statusCode}).',
      );
    }
  }

  Future<UserProfile> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _send(() => _client.post(
          _uri('/api/auth/signup'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password, 'name': name}),
        ));
    return _handleAuthResponse(response);
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _send(() => _client.post(
          _uri('/api/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ));
    return _handleAuthResponse(response);
  }

  Future<UserProfile> _handleAuthResponse(http.Response response) async {
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw AuthException(body['error'] as String? ?? 'Não foi possível completar a operação.');
    }
    final token = body['token'] as String?;
    final profile = body['profile'];
    if (token == null || profile is! Map<String, dynamic>) {
      throw AuthException('Servidor não devolveu token/perfil (HTTP ${response.statusCode}).');
    }
    // Writing to the platform keystore can fail on some devices. That must
    // not fail a login that the server already accepted — the session stays
    // valid for this run, it just won't survive a restart.
    try {
      await _session.saveToken(token);
    } catch (e) {
      debugPrint('AuthSession: falha ao gravar o token no keystore: $e');
    }
    return UserProfile.fromMap(profile);
  }

  /// Exchanges a Google ID token for a backend session. The server verifies
  /// the token with Google, then links it to an existing account with the
  /// same e-mail or creates a new one — see `server/api/auth/google.ts`.
  Future<UserProfile> loginWithGoogle(String idToken) async {
    final response = await _send(() => _client.post(
          _uri('/api/auth/google'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        ));
    return _handleAuthResponse(response);
  }

  Future<String> forgotPassword(String email) async {
    final response = await _send(() => _client.post(
          _uri('/api/auth/forgot-password'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        ));
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw AuthException(body['error'] as String? ?? 'Não foi possível enviar o e-mail.');
    }
    return body['message'] as String? ?? 'Verifique seu e-mail.';
  }

  /// Fetches the current profile from the server using the stored token.
  /// Returns null (and clears the token) if there is none, or if it's no
  /// longer valid.
  Future<UserProfile?> fetchProfile() async {
    final token = await _session.readToken();
    if (token == null) return null;
    try {
      final response = await _client.get(
        _uri('/api/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 401) {
        // Só descarta o token quando o 401 veio da nossa API (JSON). Um 401
        // em HTML é um muro na frente do servidor (Deployment Protection,
        // proxy, portal de wi-fi) e deslogar por causa dele tiraria da conta
        // gente com sessão perfeitamente válida.
        if (ServerDiagnostics.describeNonJson(response) == null) {
          await _session.clearToken();
        }
        return null;
      }
      if (response.statusCode >= 400) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromMap(body['profile'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort background sync — swallows errors so a flaky connection
  /// never interrupts local play.
  Future<void> pushProfile(UserProfile profile) async {
    final token = await _session.readToken();
    if (token == null) return;
    try {
      await _client.put(
        _uri('/api/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profile.toMap()),
      );
    } catch (_) {
      // Ignored — next mutation will retry the sync anyway.
    }
  }

  Future<void> logout() => _session.clearToken();
}
