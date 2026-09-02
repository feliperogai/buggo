import 'dart:convert';
import 'dart:io';

import 'package:buggo/features/auth/data/auth_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Regressão do bug em que *qualquer* falha no login virava
/// "Não foi possível conectar. Verifique sua internet." — inclusive quando o
/// servidor tinha respondido normalmente. Só falha de rede de verdade pode
/// produzir [NetworkException].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.exemplo.test/');
  });

  AuthRepository repoThatReturns(http.Response response) =>
      AuthRepository(client: MockClient((_) async => response));

  AuthRepository repoThatThrows(Object error) =>
      AuthRepository(client: MockClient((_) async => throw error));

  Future<Object?> loginError(AuthRepository repo) async {
    try {
      await repo.login(email: 'a@b.co', password: 'senha123');
      return null;
    } catch (e) {
      return e;
    }
  }

  group('erros que NÃO são de conexão', () {
    test('credencial errada vira AuthException com a mensagem do servidor',
        () async {
      final repo = repoThatReturns(
        http.Response(jsonEncode({'error': 'E-mail ou senha incorretos'}), 401),
      );
      final e = await loginError(repo);
      expect(e, isA<AuthException>());
      expect(e.toString(), 'E-mail ou senha incorretos');
    });

    test('resposta não-JSON reporta o status, não "sem internet"', () async {
      final repo = repoThatReturns(http.Response('<html>500</html>', 500));
      final e = await loginError(repo);
      expect(e, isA<AuthException>());
      expect(e, isNot(isA<NetworkException>()));
      expect(e.toString(), contains('500'));
    });

    test('200 sem token não é reportado como falha de conexão', () async {
      final repo = repoThatReturns(http.Response(jsonEncode({}), 200));
      final e = await loginError(repo);
      expect(e, isA<AuthException>());
      expect(e, isNot(isA<NetworkException>()));
      expect(e.toString(), contains('token'));
    });

    test('sem API_BASE_URL a mensagem aponta o .env, não a internet', () async {
      dotenv.loadFromString(envString: 'API_BASE_URL=');
      final e = await loginError(repoThatReturns(http.Response('{}', 200)));
      expect(e, isA<AuthException>());
      expect(e, isNot(isA<NetworkException>()));
      expect(e.toString(), contains('.env'));
    });
  });

  group('erros que SÃO de conexão', () {
    test('SocketException vira NetworkException', () async {
      final e = await loginError(
        repoThatThrows(const SocketException('Failed host lookup')),
      );
      expect(e, isA<NetworkException>());
    });

    test('ClientException vira NetworkException', () async {
      final e = await loginError(repoThatThrows(http.ClientException('reset')));
      expect(e, isA<NetworkException>());
    });
  });

  test('a barra final do API_BASE_URL não duplica na URL', () async {
    late Uri seen;
    final repo = AuthRepository(client: MockClient((req) async {
      seen = req.url;
      return http.Response(jsonEncode({'error': 'x'}), 401);
    }));
    await loginError(repo);
    expect(seen.toString(), 'https://api.exemplo.test/api/auth/login');
  });
}
