import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/user_provider.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final canBuyFreeze = user.streakFreezes < UserProfile.maxStreakFreezes &&
        user.coins >= UserNotifier.streakFreezeCoinCost;
    final isMaxed = user.streakFreezes >= UserProfile.maxStreakFreezes;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
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
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.streakColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_fire_department_rounded,
                    color: AppColors.streakColor, size: 56),
              ).animate().scale(begin: const Offset(0.85, 0.85)).fade(),
              const SizedBox(height: 16),
              Text('${user.streak} dias', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 6),
              Text(
                user.streak > 0
                    ? 'Continue estudando todos os dias para manter sua sequência!'
                    : 'Complete uma lição hoje para começar sua sequência.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.streakColor.withValues(alpha: 0.2),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.streakColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.ac_unit_rounded,
                            color: AppColors.streakColor, size: 20),
                        const SizedBox(width: 8),
                        Text('Congelamentos de sequência',
                            style: AppTextStyles.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Se você faltar um dia, um congelamento é usado automaticamente para proteger sua sequência.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(UserProfile.maxStreakFreezes,
                          (i) {
                        final filled = i < user.streakFreezes;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.ac_unit_rounded,
                            color: filled
                                ? AppColors.streakColor
                                : AppColors.cardBorder,
                            size: 28,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: canBuyFreeze
                          ? () {
                              final ok = ref
                                  .read(userProvider.notifier)
                                  .buyStreakFreeze();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: ok
                                      ? AppColors.success
                                      : AppColors.error,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  content: Text(
                                    ok
                                        ? 'Congelamento comprado!'
                                        : 'Moedas insuficientes.',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: AnimatedOpacity(
                        opacity: canBuyFreeze || isMaxed ? 1 : 0.5,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: isMaxed ? null : AppColors.accentGradient,
                            color: isMaxed ? AppColors.surfaceVariant : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.monetization_on_rounded,
                                  color: isMaxed
                                      ? AppColors.textMuted
                                      : Colors.white,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                isMaxed
                                    ? 'Congelamentos no máximo'
                                    : 'Comprar por ${UserNotifier.streakFreezeCoinCost} moedas',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: isMaxed
                                      ? AppColors.textMuted
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 150.ms).slideY(begin: 0.1).fade(),
            ],
          ),
        ),
      ),
    );
  }
}
