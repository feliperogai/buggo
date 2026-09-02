import 'dart:convert';
import 'dart:io';

import 'package:buggo/features/purchases/data/purchase_repository.dart';
import 'package:buggo/features/purchases/data/store_products.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Nenhuma compra pode ser creditada pela palavra do app: o repositório só
/// manda o purchaseToken e aceita o perfil que o servidor devolve depois de
/// confirmar com a Play Developer API.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.exemplo.test');
    // O token de sessão vive no keystore; em teste, um valor em memória.
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'jwt-de-teste'});
  });

  Map<String, dynamic> profileJson({int coins = 0}) => {
        'id': 'uuid-1',
        'email': 'a@b.co',
        'name': 'Felipe',
        'language': 'python',
        'level': 'adult',
        'dailyGoalMinutes': 15,
        'xp': 100,
        'coins': coins,
        'streak': 3,
        'completedLessons': <String>[],
        'unlockedAchievements': <String>[],
        'avatarIndex': 0,
        'lives': 5,
        'streakFreezes': 0,
      };

  test('manda productId e purchaseToken, e devolve o perfil do servidor', () async {
    late Map<String, dynamic> sent;
    late String auth;
    final repo = PurchaseRepository(client: MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      auth = req.headers['Authorization'] ?? '';
      return http.Response(
        jsonEncode({'profile': profileJson(coins: 450)}),
        200,
      );
    }));

    final profile = await repo.verify(
      productId: StoreProducts.coins450,
      purchaseToken: 'token-do-play',
    );

    expect(sent, {'productId': 'coins_450', 'purchaseToken': 'token-do-play'});
    expect(auth, 'Bearer jwt-de-teste');
    // O saldo vem do servidor, não de uma conta feita no app.
    expect(profile.coins, 450);
  });

  test('erro do servidor vira mensagem, não crédito silencioso', () async {
    final repo = PurchaseRepository(client: MockClient((_) async =>
        http.Response(jsonEncode({'error': 'Assinatura não está ativa'}), 402)));
    expect(
      () => repo.verify(productId: StoreProducts.buggoPlusMonthly, purchaseToken: 't'),
      throwsA(isA<PurchaseVerificationFailure>().having(
          (e) => e.message, 'message', contains('Assinatura'))),
    );
  });

  test('sem rede, avisa que a compra não foi perdida', () async {
    final repo = PurchaseRepository(
      client: MockClient((_) async => throw const SocketException('offline')),
    );
    expect(
      () => repo.verify(productId: StoreProducts.coins200, purchaseToken: 't'),
      throwsA(isA<PurchaseVerificationFailure>().having(
          (e) => e.message, 'message', contains('não foi perdida'))),
    );
  });

  test('sem sessão, pede login em vez de tentar creditar', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final repo = PurchaseRepository(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    expect(
      () => repo.verify(productId: StoreProducts.coins200, purchaseToken: 't'),
      throwsA(isA<PurchaseVerificationFailure>().having(
          (e) => e.message, 'message', contains('Entre na sua conta'))),
    );
  });

  test('os ids do app batem com o catálogo do servidor', () {
    // server/lib/products.ts — se um lado mudar, o outro recusa a compra.
    expect(StoreProducts.all, {
      'coins_200',
      'coins_450',
      'coins_950',
      'buggo_plus_monthly',
    });
  });
}
