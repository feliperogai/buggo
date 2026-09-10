import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../../shared/models/user_profile.dart';
import 'purchase_repository.dart';
import 'store_products.dart';

/// Resultado de uma tentativa de compra, já traduzido para a UI.
sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

class PurchaseGranted extends PurchaseOutcome {
  final UserProfile profile;
  const PurchaseGranted(this.profile);
}

class PurchaseCanceled extends PurchaseOutcome {
  const PurchaseCanceled();
}

class PurchaseFailed extends PurchaseOutcome {
  final String message;
  const PurchaseFailed(this.message);
}

/// Ponte com o Google Play Billing.
///
/// O fluxo do `in_app_purchase` é assíncrono e fora de ordem: a compra é
/// iniciada com `buy*`, e o resultado chega depois pelo [purchaseStream] —
/// inclusive compras de sessões anteriores que ficaram pendentes. Por isso o
/// serviço escuta o stream sempre que está ativo, e não só durante um toque
/// no botão.
class PurchaseService {
  PurchaseService({InAppPurchase? iap, PurchaseRepository? repository})
      : _iap = iap ?? InAppPurchase.instance,
        _repository = repository ?? PurchaseRepository();

  final InAppPurchase _iap;
  final PurchaseRepository _repository;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Preços e títulos vindos do Play, por id de produto.
  final Map<String, ProductDetails> _products = {};
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  bool _available = false;
  bool get isStoreAvailable => _available;

  /// Emite sempre que uma compra termina de ser processada (inclusive as que
  /// chegam sozinhas, sem toque no botão).
  final _outcomes = StreamController<PurchaseOutcome>.broadcast();
  Stream<PurchaseOutcome> get outcomes => _outcomes.stream;

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchasesUpdated,
      onError: (Object e) => _outcomes.add(PurchaseFailed('Erro na loja: $e')),
    );

    final response = await _iap.queryProductDetails(StoreProducts.all);
    for (final product in response.productDetails) {
      _products[product.id] = product;
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        'Play não encontrou estes produtos: ${response.notFoundIDs.join(", ")}. '
        'Confira os ids no Play Console e se o app já foi publicado num canal de teste.',
      );
    }

    // Compra paga mas ainda não creditada volta por aqui. Como nada é
    // consumido antes do servidor confirmar (ver [_finish]), o Play ainda tem
    // o token e o reentrega — é o que transforma uma falha de rede em uma
    // nova tentativa, em vez de dinheiro perdido.
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Não foi possível reconsultar compras pendentes: $e');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _outcomes.close();
  }

  /// Abre a folha de pagamento do Google. O resultado NÃO volta aqui — chega
  /// pelo [outcomes] quando o Play responde.
  Future<void> buy(String productId) async {
    final product = _products[productId];
    if (product == null) {
      _outcomes.add(const PurchaseFailed(
        'Produto indisponível na loja agora. Tente de novo em instantes.',
      ));
      return;
    }
    final param = PurchaseParam(productDetails: product);
    if (StoreProducts.subscriptions.contains(productId)) {
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      // autoConsume: false é essencial. Com `true`, o plugin consome a compra
      // ANTES de entregá-la no stream (ver `_maybeAutoConsumePurchase` no
      // in_app_purchase_android): se o crédito falhasse depois disso, o token
      // já não existia mais e o Play nunca reentregava a compra — pagamento
      // aprovado, moedas nenhuma, sem retentativa possível. Aqui o consumo
      // virou a última etapa, depois do servidor creditar.
      await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
    }
  }

  /// Reentrega compras já feitas (troca de aparelho, reinstalação) para que a
  /// assinatura ativa volte a valer.
  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Pagamento em análise (boleto, aprovação dos pais). A compra volta
          // sozinha pelo stream quando o Play resolver.
          break;
        case PurchaseStatus.canceled:
          _outcomes.add(const PurchaseCanceled());
          break;
        case PurchaseStatus.error:
          _outcomes.add(PurchaseFailed(
            purchase.error?.message ?? 'A compra não foi concluída.',
          ));
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Encerrar a compra é o ÚLTIMO passo, e só depois do servidor
          // creditar. Se a verificação falhar, a compra fica em aberto no
          // Play de propósito: ela é reentregue na próxima abertura da loja,
          // e se nunca for creditada o Google devolve o dinheiro sozinho em
          // três dias. Encerrar antes é dar a compra por concluída sem ter
          // entregue nada.
          if (await _verifyAndGrant(purchase)) {
            await _finish(purchase);
          }
          break;
      }
    }
  }

  /// Fecha a compra junto ao Play. Pacote de moedas é consumível: precisa ser
  /// consumido para poder ser comprado de novo (consumir já confirma junto ao
  /// Google). Assinatura só precisa ser confirmada.
  Future<void> _finish(PurchaseDetails purchase) async {
    try {
      if (Platform.isAndroid &&
          StoreProducts.consumables.contains(purchase.productID)) {
        await _iap
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
            .consumePurchase(purchase);
        return;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } catch (e) {
      // As moedas já estão creditadas no servidor. Falhar aqui só significa
      // que o Play vai reentregar a compra depois; o servidor reconhece o
      // token repetido e devolve o perfil sem creditar de novo.
      debugPrint('Não foi possível encerrar a compra no Play: $e');
    }
  }

  /// `true` quando o servidor confirmou a compra e creditou.
  Future<bool> _verifyAndGrant(PurchaseDetails purchase) async {
    try {
      final profile = await _repository.verify(
        productId: purchase.productID,
        // No Android este campo é o purchaseToken que a Play Developer API
        // usa para confirmar a compra.
        purchaseToken: purchase.verificationData.serverVerificationData,
      );
      _outcomes.add(PurchaseGranted(profile));
      return true;
    } on PurchaseVerificationFailure catch (e) {
      debugPrint('Compra ${purchase.productID} não creditada: ${e.message}');
      _outcomes.add(PurchaseFailed(
        '${e.message} Sua compra não foi perdida: abra a loja de novo para '
        'tentar outra vez.',
      ));
      return false;
    } catch (e) {
      debugPrint('Compra ${purchase.productID} não creditada: $e');
      _outcomes.add(PurchaseFailed(
        'Erro inesperado ao confirmar a compra: $e. Sua compra não foi '
        'perdida: abra a loja de novo para tentar outra vez.',
      ));
      return false;
    }
  }
}
