import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env_config.dart';
import 'ranking_entry.dart';

/// Backs the Ranking screen with real accounts from the Vercel API (see
/// `server/api/leaderboard.ts`) once `API_BASE_URL` is configured, falling
/// back to local mock entries otherwise (missing `.env` key, network error,
/// backend not deployed yet, etc).
class RankingRepository {
  bool get isLive => EnvConfig.isApiConfigured;

  Future<List<RankingEntry>> fetchTopByXp({int limit = 20}) =>
      _fetch(by: 'xp', limit: limit, fallback: _mockXpRanking);

  Future<List<RankingEntry>> fetchTopByStreak({int limit = 20}) =>
      _fetch(by: 'streak', limit: limit, fallback: _mockStreakRanking);

  Future<List<RankingEntry>> _fetch({
    required String by,
    required int limit,
    required List<RankingEntry> fallback,
  }) async {
    if (!isLive) return fallback;
    try {
      final uri = Uri.parse('${EnvConfig.apiBaseUrl}/api/leaderboard?by=$by&limit=$limit');
      final response = await http.get(uri);
      if (response.statusCode != 200) return fallback;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = body['entries'] as List<dynamic>;
      return entries.map((e) {
        final map = e as Map<String, dynamic>;
        return RankingEntry(
          id: map['id'] as String,
          name: map['name'] as String? ?? '—',
          avatarIndex: map['avatarIndex'] as int? ?? 0,
          xp: map['xp'] as int? ?? 0,
          streak: map['streak'] as int? ?? 0,
        );
      }).toList();
    } catch (_) {
      return fallback;
    }
  }

  // ── Mock data (shown until the API is configured) ───────────────────────
  static const _mockXpRanking = [
    RankingEntry(id: 'mock-1', name: 'Marina', avatarIndex: 2, xp: 2340, streak: 41),
    RankingEntry(id: 'mock-2', name: 'Lucas', avatarIndex: 0, xp: 2110, streak: 18),
    RankingEntry(id: 'mock-3', name: 'Bia', avatarIndex: 4, xp: 1980, streak: 27),
    RankingEntry(id: 'mock-4', name: 'Enzo', avatarIndex: 1, xp: 1750, streak: 9),
    RankingEntry(id: 'mock-5', name: 'Sofia', avatarIndex: 5, xp: 1420, streak: 14),
  ];

  static const _mockStreakRanking = [
    RankingEntry(id: 'mock-1', name: 'Marina', avatarIndex: 2, xp: 2340, streak: 41),
    RankingEntry(id: 'mock-3', name: 'Bia', avatarIndex: 4, xp: 1980, streak: 27),
    RankingEntry(id: 'mock-2', name: 'Lucas', avatarIndex: 0, xp: 2110, streak: 18),
    RankingEntry(id: 'mock-5', name: 'Sofia', avatarIndex: 5, xp: 1420, streak: 14),
    RankingEntry(id: 'mock-4', name: 'Enzo', avatarIndex: 1, xp: 1750, streak: 9),
  ];
}

/// Weekly coin prize for the top 3 of the streak ranking. Purely
/// informational until a server-side job actually pays it out.
const weeklyStreakPrizeCoins = [150, 100, 50];
