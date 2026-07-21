import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env_config.dart';
import 'ranking_entry.dart';

/// Backs the Ranking screen with Supabase data once configured, falling back
/// to local mock entries otherwise (missing `.env` keys, table not created
/// yet, network error, etc).
///
/// Expected Supabase table (create this once you're ready to go live):
///
/// ```sql
/// create table profiles (
///   id uuid primary key default gen_random_uuid(),
///   name text not null,
///   avatar_index int4 not null default 0,
///   xp int4 not null default 0,
///   streak int4 not null default 0,
///   updated_at timestamptz not null default now()
/// );
/// ```
class RankingRepository {
  static const _table = 'profiles';

  bool get isLive => EnvConfig.isSupabaseConfigured;

  Future<List<RankingEntry>> fetchTopByXp({int limit = 20}) async {
    if (!isLive) return _mockXpRanking;
    try {
      final rows = await Supabase.instance.client
          .from(_table)
          .select('id, name, avatar_index, xp, streak')
          .order('xp', ascending: false)
          .limit(limit);
      return _parseRows(rows);
    } catch (_) {
      return _mockXpRanking;
    }
  }

  Future<List<RankingEntry>> fetchTopByStreak({int limit = 20}) async {
    if (!isLive) return _mockStreakRanking;
    try {
      final rows = await Supabase.instance.client
          .from(_table)
          .select('id, name, avatar_index, xp, streak')
          .order('streak', ascending: false)
          .limit(limit);
      return _parseRows(rows);
    } catch (_) {
      return _mockStreakRanking;
    }
  }

  List<RankingEntry> _parseRows(List<dynamic> rows) {
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      return RankingEntry(
        id: map['id'] as String,
        name: map['name'] as String? ?? '—',
        avatarIndex: map['avatar_index'] as int? ?? 0,
        xp: map['xp'] as int? ?? 0,
        streak: map['streak'] as int? ?? 0,
      );
    }).toList();
  }

  // ── Mock data (shown until Supabase is configured) ──────────────────────
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
