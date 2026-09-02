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

  /// **Web** OAuth client id from Google Cloud — the audience the backend
  /// validates the Google ID token against (`GOOGLE_WEB_CLIENT_ID` there).
  /// It is deliberately the web id, not the Android one: the Android app
  /// requests a token addressed to the backend.
  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '';

  /// Google sign-in is only offered when both the API and the client id are
  /// configured — without them the button could only ever fail.
  static bool get isGoogleSignInConfigured =>
      isApiConfigured && googleServerClientId.isNotEmpty;
}
