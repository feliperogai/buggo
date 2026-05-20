import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/user_provider.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRouter.onboarding);
      });
      return const SizedBox.shrink();
    }

    const offers = [
      _MarketOffer(
        title: 'Tema neon',
        description: 'Visual premium para estudar com foco',
        price: 80,
        icon: Icons.auto_awesome_rounded,
        color: AppColors.primary,
      ),
      _MarketOffer(
        title: 'Impulso XP',
        description: 'Um boost para a próxima lição',
        price: 120,
        icon: Icons.bolt_rounded,
        color: AppColors.xpColor,
      ),
      _MarketOffer(
        title: 'Avatar raro',
        description: 'Item cosmético para seu perfil',
        price: 150,
        icon: Icons.face_retouching_natural_rounded,
        color: AppColors.levelPink,
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
                                  'Use suas moedas com estilo',
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
          SliverList.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final canBuy = user.coins >= offer.price;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  index == 0 ? 22 : 0,
                  20,
                  index == offers.length - 1 ? 26 : 12,
                ),
                child: _MarketCard(
                  offer: offer,
                  canBuy: canBuy,
                ).animate(delay: (index * 90).ms).slideY(begin: 0.14).fade(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  final _MarketOffer offer;
  final bool canBuy;

  const _MarketCard({
    required this.offer,
    required this.canBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: offer.color.withValues(alpha: 0.22),
          width: 1.4,
        ),
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
          _PriceBadge(price: offer.price, enabled: canBuy),
        ],
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final int price;
  final bool enabled;

  const _PriceBadge({
    required this.price,
    required this.enabled,
  });

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

class _MarketOffer {
  final String title;
  final String description;
  final int price;
  final IconData icon;
  final Color color;

  const _MarketOffer({
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}
