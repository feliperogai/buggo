import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/config/env_config.dart';
import '../../../core/net/server_diagnostics.dart';
import 'ranking_entry.dart';

/// Thrown when the leaderboard couldn't be read from the backend. Carries a
/// message naming the real cause: the screen shows it with a "Tentar de novo"
/// button instead of quietly displaying invented people.
class RankingUnavailable implements Exception {
  final String message;
  RankingUnavailable(this.message);
  @override
  String toString() => message;
}

/// Backs the Ranking screen with the real accounts stored in Neon, read
/// through the Vercel API (see `server/api/leaderboard.ts`). The endpoint is
/// public, so this works for guests too — signing in is only needed to
/// *appear* in the ranking, not to see it.
///
/// There is deliberately no mock/sample fallback: showing fake names when the
/// request fails made a broken connection look like a working leaderboard.
class RankingRepository {
  /// Injectable for tests; defaults to the shared client.
  final http.Client _client;

  RankingRepository({http.Client? client}) : _client = client ?? http.Client();

  bool get isLive => EnvConfig.isApiConfigured;

  Future<List<RankingEntry>> fetchTopByXp({int limit = 20}) =>
      _fetch(by: 'xp', limit: limit);

  Future<List<RankingEntry>> fetchTopByStreak({int limit = 20}) =>
      _fetch(by: 'streak', limit: limit);

  Future<List<RankingEntry>> _fetch({
    required String by,
    required int limit,
  }) async {
    if (!isLive) {
      throw RankingUnavailable(
        'Esta build não tem URL de API para chamar.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse(
              '${EnvConfig.apiBaseUrl}/api/leaderboard?by=$by&limit=$limit'))
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e) {
      throw RankingUnavailable(
        'Sem conexão com o servidor (${e.osError?.message ?? e.message}).',
      );
    } on HandshakeException catch (e) {
      throw RankingUnavailable('Falha de TLS ao falar com o servidor: ${e.message}');
    } on TimeoutException {
      throw RankingUnavailable('O servidor demorou mais de 20s para responder.');
    } on http.ClientException catch (e) {
      throw RankingUnavailable('Falha de rede: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw RankingUnavailable(
        ServerDiagnostics.describeNonJson(response) ??
            'O servidor respondeu HTTP ${response.statusCode} ao buscar o ranking.',
      );
    }

    try {
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
      throw RankingUnavailable(
        ServerDiagnostics.describeNonJson(response) ??
            'Resposta inesperada do servidor ao ler o ranking.',
      );
    }
  }
}

/// Weekly coin prize for the top 3 of the streak ranking. Purely
/// informational until a server-side job actually pays it out.
const weeklyStreakPrizeCoins = [150, 100, 50];
