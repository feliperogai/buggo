import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'purchase_service.dart';

/// Serviço de compras vivo enquanto o app estiver aberto.
///
/// Fica num provider (e não dentro da tela) porque o Google Play reentrega
/// compras pendentes de sessões anteriores assim que alguém escuta o stream:
/// quem pagou e fechou o app antes da confirmação recebe as moedas na
/// próxima vez que a loja for aberta.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

/// Dispara `init()` uma única vez e expõe o carregamento para a tela.
final purchaseInitProvider = FutureProvider<void>((ref) async {
  await ref.watch(purchaseServiceProvider).init();
});
