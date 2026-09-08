import 'dart:convert';
import 'dart:io';

import 'package:buggo/core/config/env_config.dart';
import 'package:buggo/features/ranking/data/ranking_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// O ranking é público: convidado tem que ver as contas reais do banco.
/// Antes, qualquer falha caía num mock (Marina, Lucas, Bia...) exibido sem
/// aviso nenhum — um backend fora do ar parecia um ranking saudável.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.exemplo.test/');
  });

  const payload = {
    'entries': [
      {'id': 'uuid-1', 'name': 'Felipe', 'avatarIndex': 4, 'xp': 474, 'streak': 1},
      {'id': 'uuid-2', 'name': 'Luciana', 'avatarIndex': 2, 'xp': 212, 'streak': 1},
    ]
  };

  test('convidado recebe as contas reais devolvidas pelo servidor', () async {
    final repo = RankingRepository(
      client: MockClient((_) async => http.Response(
            jsonEncode(payload),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
    );
    final entries = await repo.fetchTopByXp();
    expect(entries, hasLength(2));
    expect(entries.first.name, 'Felipe');
    expect(entries.first.id, 'uuid-1');
    expect(entries.first.xp, 474);
  });

  test('a barra final do API_BASE_URL não duplica na URL', () async {
    late Uri seen;
    final repo = RankingRepository(client: MockClient((req) async {
      seen = req.url;
      return http.Response(jsonEncode(payload), 200);
    }));
    await repo.fetchTopByStreak(limit: 5);
    expect(seen.path, '/api/leaderboard');
    expect(seen.queryParameters, {'by': 'streak', 'limit': '5'});
  });

  group('falhas nunca viram dados inventados', () {
    Future<Object?> errorFrom(RankingRepository repo) async {
      try {
        await repo.fetchTopByXp();
        return null;
      } catch (e) {
        return e;
      }
    }

    test('sem rede, propaga o erro em vez de devolver mock', () async {
      final repo = RankingRepository(
        client: MockClient((_) async => throw const SocketException('no route')),
      );
      final e = await errorFrom(repo);
      expect(e, isA<RankingUnavailable>());
      expect(e.toString(), contains('Sem conexão'));
    });

    test('HTTP 500 propaga o status', () async {
      final repo = RankingRepository(
        client: MockClient((_) async => http.Response('boom', 500)),
      );
      final e = await errorFrom(repo);
      expect(e, isA<RankingUnavailable>());
      expect(e.toString(), contains('500'));
    });

    test('corpo não-JSON propaga erro', () async {
      final repo = RankingRepository(
        client: MockClient((_) async => http.Response('<html>', 200)),
      );
      expect(await errorFrom(repo), isA<RankingUnavailable>());
    });

    test('muro de autenticação da Vercel é nomeado, não vira erro genérico',
        () async {
      final repo = RankingRepository(
        client: MockClient((_) async => http.Response(
              '<html><body>Authentication Required</body></html>',
              401,
              headers: {'content-type': 'text/html; charset=utf-8'},
            )),
      );
      final e = await errorFrom(repo);
      expect(e, isA<RankingUnavailable>());
      expect(e.toString(), contains('Deployment Protection'));
    });

    test('.env vazio cai na URL de produção em vez de desligar o ranking',
        () async {
      dotenv.loadFromString(envString: 'API_BASE_URL=');
      late Uri seen;
      final repo = RankingRepository(client: MockClient((req) async {
        seen = req.url;
        return http.Response(jsonEncode(payload), 200);
      }));
      await repo.fetchTopByXp();
      expect(seen.origin, EnvConfig.defaultApiBaseUrl);
    });
  });
}
