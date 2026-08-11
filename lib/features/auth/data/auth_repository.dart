import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env_config.dart';
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

/// Talks to the Vercel API in front of Neon Postgres — the app never
/// connects to Postgres directly. See `server/README.md`.
class AuthRepository {
  final _session = AuthSession();

  bool get isConfigured => EnvConfig.isApiConfigured;

  Uri _uri(String path) => Uri.parse('${EnvConfig.apiBaseUrl}$path');

  Future<UserProfile> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      _uri('/api/auth/signup'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    return _handleAuthResponse(response);
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleAuthResponse(response);
  }

  /// Entra com a conta Google do aparelho.
  ///
  /// O app só pega o ID token; quem decide se ele é válido é o backend, que
  /// confere a assinatura do Google e a audiência. Se a conta já existir com
  /// o mesmo e-mail, o servidor vincula o Google a ela em vez de criar uma
  /// conta nova com o progresso zerado.
  ///
  /// Lança [AuthException] com mensagem pronta para exibir. Cancelar a
  /// escolha de conta não é erro: devolve `null`.
  Future<UserProfile?> loginWithGoogle() async {
    if (!EnvConfig.isGoogleSignInConfigured) {
      throw AuthException('Login com Google não está configurado neste app.');
    }

    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw AuthException('Login com Google não é suportado neste aparelho.');
    }

    String? idToken;
    try {
      // initialize() é idempotente; chamar aqui evita depender da ordem de
      // boot só para uma tela que a maioria dos usuários nem abre.
      await signIn.initialize(
        serverClientId: EnvConfig.googleServerClientId,
      );
      final account = await signIn.authenticate();
      idToken = account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthException('Não foi possível entrar com o Google: ${e.code.name}');
    }

    if (idToken == null) {
      throw AuthException('O Google não devolveu um token válido.');
    }

    final response = await http.post(
      _uri('/api/auth/google'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    return _handleAuthResponse(response);
  }

  Future<UserProfile> _handleAuthResponse(http.Response response) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(body['error'] as String? ?? 'Não foi possível completar a operação.');
    }
    final token = body['token'] as String;
    await _session.saveToken(token);
    return UserProfile.fromMap(body['profile'] as Map<String, dynamic>);
  }

  Future<String> forgotPassword(String email) async {
    final response = await http.post(
      _uri('/api/auth/forgot-password'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
      final response = await http.get(
        _uri('/api/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 401) {
        await _session.clearToken();
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
      await http.put(
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
