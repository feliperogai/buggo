import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads app config from `.env` (see `.env.example`).
///
/// The app works without `API_BASE_URL` set — features backed by it (login,
/// profile sync, the real ranking) fall back to guest-only / mock data until
/// the key is filled in.
class EnvConfig {
  EnvConfig._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  /// Base URL of the Vercel API in front of Neon Postgres, e.g.
  /// `https://buggo-api.vercel.app`. A trailing slash (if present in
  /// `.env`) is stripped so it can be safely concatenated with `/api/...`.
  static String get apiBaseUrl {
    final raw = dotenv.env['API_BASE_URL'] ?? '';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;

  /// OAuth *Web* client ID do projeto no Google Cloud — não o client ID
  /// Android. É ele que vira a `aud` do ID token, e o backend recusa o
  /// token se não bater (ver `server/api/auth/google.ts`).
  ///
  /// Sem essa chave o botão "Entrar com Google" some da tela de login, em
  /// vez de aparecer e falhar no toque.
  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  static bool get isGoogleSignInConfigured =>
      isApiConfigured && googleServerClientId.isNotEmpty;

  /// Unidade de anúncio premiado do AdMob.
  ///
  /// O padrão é a unidade **de teste** oficial do Google: em debug ela é
  /// sempre usada, mesmo que o .env traga a de produção. Usar a unidade real
  /// durante o desenvolvimento gera tráfego inválido e é motivo de suspensão
  /// da conta AdMob.
  static const _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static String rewardedAdUnitId({required bool isDebug}) {
    if (isDebug) return _testRewardedAdUnitId;
    final id = dotenv.env['ADMOB_REWARDED_AD_UNIT_ID'] ?? '';
    return id.isEmpty ? _testRewardedAdUnitId : id;
  }
}
