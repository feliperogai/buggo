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
  /// `https://buggo-api.vercel.app`. No trailing slash.
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
