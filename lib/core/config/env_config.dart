import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase credentials from `.env` (see `.env.example`).
///
/// The app works without these set — features backed by Supabase (like the
/// ranking) fall back to local/mock data until the keys are filled in.
class EnvConfig {
  EnvConfig._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
