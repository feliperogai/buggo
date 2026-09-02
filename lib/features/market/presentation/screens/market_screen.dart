import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../purchases/data/purchase_providers.dart';
import '../../../purchases/data/purchase_service.dart';
import '../../../purchases/data/store_products.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  StreamSubscription<PurchaseOutcome>? _outcomes;
  String? _pendingProductId;

  @override
  void initState() {
    super.initState();
    // Ouve o resultado das compras, inclusive as reentregues pelo Play de
    // sessões anteriores.
    _outcomes =
        ref.read(purchaseServiceProvider).outcomes.listen(_onPurchaseOutcome);
  }

  @override
  void dispose() {
    _outcomes?.cancel();
    super.dispose();
  }

  void _onPurchaseOutcome(PurchaseOutcome outcome) {
    if (!mounted) return;
    setState(() => _pendingProductId = null);
    switch (outcome) {
      case PurchaseGranted(:final profile):
        // O servidor é a fonte da verdade do saldo depois de uma compra.
        ref.read(userProvider.notifier).saveProfile(profile);
        _showResult(context, true, 'Compra confirmada!', '');
      case PurchaseCanceled():
        break;
      case PurchaseFailed(:final message):
        _showResult(context, false, '', message);
    }
  }

  Future<void> _startPurchase(String productId) async {
    setState(() => _pendingProductId = productId);
    await ref.read(purchaseServiceProvider).buy(productId);
  }

  static const _cosmeticOffers = [
    _CoinOffer(
      title: 'Impulso XP',
      description: 'Um boost para a próxima lição',
      price: 120,
      icon: Icons.bolt_rounded,
      color: AppColors.xpColor,
    ),
  ];

  /// Ordem em que os pacotes aparecem. Título, descrição e **preço** vêm do
  /// Google Play (já localizados), não daqui.
  static const _coinPackageIds = [
    StoreProducts.coins200,
    StoreProducts.coins450,
    StoreProducts.coins950,
  ];

  void _showResult(
    BuildContext context,
    bool ok,
    String successMsg,
    String failureMsg,
  ) {
    if (ok) {
      SoundService.instance.playWithHaptic(Sfx.purchase, Haptic.light);
    } else {
      SoundService.instance.haptic(Haptic.heavy);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.success : AppColors.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          ok ? successMsg : failureMsg,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRouter.onboarding);
      });
      return const SizedBox.shrink();
    }

    // Estado da loja do Google: enquanto o Play não responde, a seção mostra
    // um loader; se falhar, mostra o motivo em vez de botões que não compram.
    final storeInit = ref.watch(purchaseInitProvider);
    final service = ref.watch(purchaseServiceProvider);
    final products = service.products;
    final storeReady = storeInit.hasValue && service.isStoreAvailable;
    final String? storeError = storeInit.hasError
        ? 'Erro ao conectar na loja: ${storeInit.error}'
        : (storeInit.hasValue && !service.isStoreAvailable
            ? 'O Google Play não está disponível neste aparelho.'
            : null);

    final unlimited = user.hasUnlimitedLives;
    final full = user.lives >= UserProfile.maxLives;
    final missing = UserProfile.maxLives - user.lives;
    final notifier = ref.read(userProvider.notifier);

    // ── "Moedas do jogo" section items ──────────────────────────────────
    final coinShopItems = <_CoinShopItem>[
      _CoinShopItem(
        title: '+1 vida',
        description: 'Recupere uma vida agora',
        icon: Icons.favorite_rounded,
        color: AppColors.error,
        price: UserNotifier.lifeCoinCost,
        available: !unlimited && !full,
        unavailableLabel: unlimited ? 'Vidas ilimitadas ativas' : 'Vidas cheias',
        onTap: () {
          final ok = notifier.buyLife();
          _showResult(context, ok, 'Vida recuperada!', 'Moedas insuficientes.');
        },
      ),
      _CoinShopItem(
        title: '+3 vidas',
        description: 'Recupere três vidas de uma vez',
        icon: Icons.favorite_rounded,
        color: AppColors.error,
        price: 3 * UserNotifier.lifeCoinCost,
        available: !unlimited && !full,
        unavailableLabel: unlimited ? 'Vidas ilimitadas ativas' : 'Vidas cheias',
        onTap: () {
          final ok = notifier.buyLives(3);
          _showResult(context, ok, 'Vidas recuperadas!', 'Moedas insuficientes.');
        },
      ),
      _CoinShopItem(
        title: 'Recarregar vidas',
        description: 'Preenche todas as vidas que faltam',
        icon: Icons.favorite_rounded,
        color: AppColors.error,
        price: missing * UserNotifier.lifeCoinCost,
        available: !unlimited && !full,
        unavailableLabel: unlimited ? 'Vidas ilimitadas ativas' : 'Vidas cheias',
        onTap: () {
          final ok = notifier.refillAllLives();
          _showResult(context, ok, 'Vidas recarregadas!', 'Moedas insuficientes.');
        },
      ),
      _CoinShopItem(
        title: 'Congelamento de sequência',
        description: 'Protege 1 dia sem perder a sequência',
        icon: Icons.ac_unit_rounded,
        color: AppColors.streakColor,
        price: UserNotifier.streakFreezeCoinCost,
        available: user.streakFreezes < UserProfile.maxStreakFreezes,
        unavailableLabel: 'Congelamentos no máximo',
        onTap: () {
          final ok = notifier.buyStreakFreeze();
          _showResult(
              context, ok, 'Congelamento comprado!', 'Moedas insuficientes.');
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1.4,
                              ),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Market',
                                  style: AppTextStyles.headlineLarge
                                      .copyWith(color: Colors.white),
                                ),
                                Text(
                                  'Moedas do jogo ou dinheiro real',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.76),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.monetization_on_rounded,
                                color: AppColors.coinColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.coins} moedas',
                                  style: AppTextStyles.headlineSmall
                                      .copyWith(color: Colors.white),
                                ),
                                Text(
                                  'saldo disponivel',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Seção: moedas do jogo ────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.coinColor,
              title: 'Moedas do jogo',
              subtitle: 'Use moedas ganhas jogando',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList.builder(
              itemCount: coinShopItems.length,
              itemBuilder: (context, index) {
                final item = coinShopItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CoinShopCard(item: item, coins: user.coins)
                      .animate(delay: (index * 70).ms)
                      .slideY(begin: 0.14)
                      .fade(),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverList.builder(
              itemCount: _cosmeticOffers.length,
              itemBuilder: (context, index) {
                final offer = _cosmeticOffers[index];
                final canBuy = user.coins >= offer.price;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CosmeticCard(offer: offer, canBuy: canBuy)
                      .animate(delay: ((coinShopItems.length + index) * 70).ms)
                      .slideY(begin: 0.14)
                      .fade(),
                );
              },
            ),
          ),

          // ── Seção: dinheiro real (Google Play) ───────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.credit_card_rounded,
              iconColor: AppColors.primary,
              title: 'Dinheiro real',
              subtitle: storeReady
                  ? 'Pagamento pelo Google Play'
                  : 'Conectando à loja do Google...',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (storeError != null)
                  _StoreUnavailable(message: storeError)
                else if (!storeReady)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _PlayProductCard(
                    product: products[StoreProducts.buggoPlusMonthly],
                    fallbackTitle: 'Buggo+ · Ilimitado',
                    description: unlimited
                        ? 'Sua assinatura está ativa'
                        : 'Vidas ilimitadas enquanto a assinatura durar',
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.accent,
                    isBusy: _pendingProductId == StoreProducts.buggoPlusMonthly,
                    onTap: unlimited
                        ? null
                        : () => _startPurchase(StoreProducts.buggoPlusMonthly),
                  ).animate(delay: 0.ms).slideY(begin: 0.14).fade(),
                  const SizedBox(height: 12),
                  ..._coinPackageIds.asMap().entries.map((entry) {
                    final id = entry.value;
                    final coins = StoreProducts.coinAmounts[id];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlayProductCard(
                        product: products[id],
                        fallbackTitle: '$coins moedas',
                        description: 'Crédito direto na sua conta',
                        icon: Icons.monetization_on_rounded,
                        color: AppColors.coinColor,
                        isBusy: _pendingProductId == id,
                        onTap: () => _startPurchase(id),
                      )
                          .animate(delay: ((entry.key + 1) * 70).ms)
                          .slideY(begin: 0.14)
                          .fade(),
                    );
                  }),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          ref.read(purchaseServiceProvider).restore(),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Restaurar compras'),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineSmall),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coin-priced shop item (lives, streak freeze) ────────────────
class _CoinShopItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int price;
  final bool available;
  final String unavailableLabel;
  final VoidCallback onTap;

  const _CoinShopItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.price,
    required this.available,
    required this.unavailableLabel,
    required this.onTap,
  });
}

class _CoinShopCard extends StatelessWidget {
  final _CoinShopItem item;
  final int coins;

  const _CoinShopCard({required this.item, required this.coins});

  @override
  Widget build(BuildContext context) {
    final canBuy = item.available && coins >= item.price;

    return GestureDetector(
      onTap: canBuy ? item.onTap : null,
      child: AnimatedOpacity(
        opacity: item.available ? 1 : 0.55,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: item.color.withValues(alpha: 0.22), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color, size: 29),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      item.available ? item.description : item.unavailableLabel,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CoinPriceBadge(price: item.price, enabled: canBuy),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinPriceBadge extends StatelessWidget {
  final int price;
  final bool enabled;

  const _CoinPriceBadge({required this.price, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.coinColor.withValues(alpha: 0.10)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? AppColors.coinColor.withValues(alpha: 0.28)
              : AppColors.cardBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            color: enabled ? AppColors.coinColor : AppColors.textMuted,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$price',
            style: AppTextStyles.labelSmall.copyWith(
              color: enabled ? AppColors.coinColor : AppColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cosmetic offers (coins, decorative — no purchase logic yet) ─
class _CoinOffer {
  final String title;
  final String description;
  final int price;
  final IconData icon;
  final Color color;

  const _CoinOffer({
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}

class _CosmeticCard extends StatelessWidget {
  final _CoinOffer offer;
  final bool canBuy;

  const _CosmeticCard({required this.offer, required this.canBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: offer.color.withValues(alpha: 0.22), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: offer.color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: offer.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(offer.icon, color: offer.color, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.title, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text(offer.description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CoinPriceBadge(price: offer.price, enabled: canBuy),
        ],
      ),
    );
  }
}

// ── Real-money offers (mock — disabled until payments are wired) ─
class _PlayProductCard extends StatelessWidget {
  /// Vem do Google Play. Nulo enquanto a consulta não voltou ou quando o id
  /// não existe no Play Console — daí o card aparece desabilitado.
  final ProductDetails? product;
  final String fallbackTitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool isBusy;
  final VoidCallback? onTap;

  const _PlayProductCard({
    required this.product,
    required this.fallbackTitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final missing = product == null;
    final enabled = !missing && !isBusy && onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: color.withValues(alpha: enabled ? 0.5 : 0.22),
                width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product?.title ?? fallbackTitle,
                        style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      missing ? 'Indisponível na loja agora' : description,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: enabled ? color.withValues(alpha: 0.12)
                                   : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // Preço formatado pelo próprio Play: moeda e localização
                  // corretas para cada país, sem conversão no app.
                  child: Text(
                    product?.price ?? '—',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: enabled ? color : AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mostrado quando a loja do Google não respondeu — melhor dizer o motivo do
/// que exibir botões de compra que não funcionam.
class _StoreUnavailable extends StatelessWidget {
  final String message;
  const _StoreUnavailable({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.4),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded,
              color: AppColors.textMuted, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
