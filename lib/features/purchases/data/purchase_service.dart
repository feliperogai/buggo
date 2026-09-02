import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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
      // autoConsume deixa o Play consumir o item, liberando recompra do mesmo
      // pacote de moedas depois.
      await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
    }
  }

  /// Reentrega compras já feitas (troca de aparelho, reinstalação) para que a
  /// assinatura ativa volte a valer.
  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
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
          await _verifyAndGrant(purchase);
          break;
      }

      // Obrigatório: sem isto o Play reentrega a compra indefinidamente e
      // acaba reembolsando o usuário.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndGrant(PurchaseDetails purchase) async {
    try {
      final profile = await _repository.verify(
        productId: purchase.productID,
        // No Android este campo é o purchaseToken que a Play Developer API
        // usa para confirmar a compra.
        purchaseToken: purchase.verificationData.serverVerificationData,
      );
      _outcomes.add(PurchaseGranted(profile));
    } on PurchaseVerificationFailure catch (e) {
      _outcomes.add(PurchaseFailed(e.message));
    } catch (e) {
      _outcomes.add(PurchaseFailed('Erro inesperado ao confirmar a compra: $e'));
    }
  }
}
