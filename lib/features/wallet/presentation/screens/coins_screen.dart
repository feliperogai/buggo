import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/user_provider.dart';

class _CoinPackage {
  final int amount;
  final String price;

  const _CoinPackage({required this.amount, required this.price});
}

class CoinsScreen extends ConsumerWidget {
  const CoinsScreen({super.key});

  static const _packages = [
    _CoinPackage(amount: 200, price: 'R\$ 6,90'),
    _CoinPackage(amount: 450, price: 'R\$ 12,90'),
    _CoinPackage(amount: 950, price: 'R\$ 24,90'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.monetization_on_rounded,
                          color: AppColors.coinColor, size: 20),
                      const SizedBox(width: 6),
                      Text('${user.coins}', style: AppTextStyles.headlineSmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Moedas', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 6),
              Text(
                'Ganhe moedas completando lições, ou compre um pacote para acelerar.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _packages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pkg = _packages[index];
                    return _CoinPackageCard(package: pkg)
                        .animate(delay: (index * 90).ms)
                        .slideY(begin: 0.12)
                        .fade();
                  },
                ),
              ),
              Text(
                'Compra de moedas em breve — esta loja ainda não processa pagamentos.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinPackageCard extends StatelessWidget {
  final _CoinPackage package;

  const _CoinPackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.coinColor.withValues(alpha: 0.22), width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.coinColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.monetization_on_rounded,
                  color: AppColors.coinColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${package.amount} moedas',
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 2),
                  Text('Em breve', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                package.price,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
