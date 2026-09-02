import '../../../shared/models/user_profile.dart';
import '../data/auth_repository.dart';
import '../data/google_sign_in_service.dart';

sealed class GoogleAuthResult {
  const GoogleAuthResult();
}

class GoogleAuthSuccess extends GoogleAuthResult {
  final UserProfile profile;
  const GoogleAuthSuccess(this.profile);

  /// A conta voltou sem nenhum progresso, então dá para levar para ela o que
  /// o convidado já fez neste aparelho. Uma conta que já tem histórico
  /// próprio não pode ser sobrescrita pelo estado local.
  bool get carryGuestProgress =>
      profile.xp == 0 && profile.completedLessons.isEmpty;
}

/// O usuário fechou o seletor de contas. Não é erro e não vira mensagem.
class GoogleAuthCanceled extends GoogleAuthResult {
  const GoogleAuthCanceled();
}

class GoogleAuthError extends GoogleAuthResult {
  final String message;
  const GoogleAuthError(this.message);
}

/// Fluxo completo do login com Google: abre o seletor, troca o ID token por
/// uma sessão do backend e devolve o perfil.
///
/// Fica aqui, e não dentro de uma tela, porque a de boas-vindas e a de login
/// oferecem o mesmo botão e precisam do mesmo comportamento — inclusive as
/// mesmas mensagens de erro.
class GoogleAuthFlow {
  GoogleAuthFlow({GoogleSignInService? signIn, AuthRepository? repository})
      : _signIn = signIn ?? GoogleSignInService(),
        _repository = repository ?? AuthRepository();

  final GoogleSignInService _signIn;
  final AuthRepository _repository;

  /// Falso quando falta `GOOGLE_SERVER_CLIENT_ID` no .env — aí o botão nem
  /// é exibido, em vez de aparecer e falhar no toque.
  bool get isConfigured => _signIn.isConfigured;

  Future<GoogleAuthResult> run() async {
    try {
      final idToken = await _signIn.signInAndGetIdToken();
      if (idToken == null) return const GoogleAuthCanceled();
      return GoogleAuthSuccess(await _repository.loginWithGoogle(idToken));
    } on GoogleSignInFailure catch (e) {
      return GoogleAuthError(e.message);
    } on NetworkException catch (e) {
      return GoogleAuthError(e.message);
    } on AuthException catch (e) {
      return GoogleAuthError(e.message);
    } catch (e) {
      return GoogleAuthError('Erro inesperado: $e');
    }
  }
}
