import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/env_config.dart';

/// Wraps `google_sign_in` 7.x, whose API is initialize-then-authenticate and
/// whose errors are a single [GoogleSignInException] with a code.
///
/// Returns the Google **ID token**, which is all the backend needs: it
/// verifies the signature against Google's keys and reads the identity from
/// there, so nothing this app claims about the user is trusted.
class GoogleSignInService {
  static bool _initialized = false;

  bool get isConfigured => EnvConfig.isGoogleSignInConfigured;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: EnvConfig.googleServerClientId,
    );
    _initialized = true;
  }

  /// Runs the interactive sign-in. Returns null when the user dismisses the
  /// picker — a cancel is not an error and must not surface as one.
  Future<String?> signInAndGetIdToken() async {
    await _ensureInitialized();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      // Sempre no log, inclusive em release: é o que permite descobrir por
      // que o login falhou num aparelho que não é o seu, com `adb logcat`.
      debugPrint('GoogleSignIn falhou · code=${e.code.name} '
          'description=${e.description} details=${e.details}');

      // Cancelamento de verdade — a pessoa fechou o seletor — vem sem
      // descrição. Quando o Credential Manager desiste por configuração
      // (certificado que não bate com nenhum client OAuth, client id errado),
      // o motivo vem em `description`, e engolir isso é o pior resultado
      // possível: a tela volta ao normal sem dizer nada e não há o que
      // investigar.
      final description = e.description?.trim() ?? '';
      if (e.code == GoogleSignInExceptionCode.canceled && description.isEmpty) {
        return null;
      }
      throw GoogleSignInFailure(_messageFor(e));
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw GoogleSignInFailure(
        'O Google não devolveu o token de identidade. Confira se o '
        'GOOGLE_SERVER_CLIENT_ID é o client ID do tipo Web e se o SHA-1 da '
        'chave de assinatura da Play está cadastrado no client Android.',
      );
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }

  String _messageFor(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        // Só chega aqui com descrição — cancelamento limpo já saiu como
        // `null` lá em cima. A descrição é o motivo real e vai junto.
        return 'O Google encerrou o login: ${e.description ?? e.code.name}. '
            'Se isso acontece só na versão publicada, quase sempre é o SHA-1: '
            'a Play assina o app com a chave dela, e essa impressão digital '
            'também precisa estar no client OAuth Android.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Configuração do Google incorreta: confira o client ID e o '
            'SHA-1 do app no Google Cloud.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'O Google Play Services deste aparelho não está configurado.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Não foi possível abrir a tela do Google.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'A conta escolhida não confere com a esperada.';
      case GoogleSignInExceptionCode.unknownError:
        return 'Erro no login do Google: ${e.description ?? e.code.name}';
    }
  }
}

/// Falha do lado do Google (não do backend), com mensagem já pronta para a UI.
class GoogleSignInFailure implements Exception {
  final String message;
  GoogleSignInFailure(this.message);
  @override
  String toString() => message;
}
