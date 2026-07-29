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

class HeartsScreen extends ConsumerStatefulWidget {
  const HeartsScreen({super.key});

  @override
  ConsumerState<HeartsScreen> createState() => _HeartsScreenState();
}

class _HeartsScreenState extends ConsumerState<HeartsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ref.read(userProvider.notifier).refreshLives();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(userProvider.notifier).refreshLives();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  void _showResult(bool ok, String successMsg, String failureMsg) {
    if (!mounted) return;
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
    if (user == null) return const SizedBox.shrink();

    final unlimited = user.hasUnlimitedLives;
    final full = user.lives >= UserProfile.maxLives;
    final missing = UserProfile.maxLives - user.lives;
    final wait = user.timeUntilNextLife;

    String status;
    if (unlimited) {
      final daysLeft =
          user.unlimitedLivesUntil!.difference(DateTime.now()).inDays + 1;
      status = 'Buggo+ ativo · vidas ilimitadas por mais $daysLeft dia(s)';
    } else if (full) {
      status = 'Vidas cheias';
    } else if (wait != null && wait > Duration.zero) {
      status = 'Todas as vidas se recuperam em ${_formatCountdown(wait)}';
    } else {
      status = 'Responda com atenção para não perder vidas';
    }

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
                  Text('Vidas', style: AppTextStyles.headlineMedium),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: unlimited
                    ? Icon(Icons.all_inclusive_rounded,
                        color: AppColors.error, size: 44)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(UserProfile.maxLives, (i) {
                          final filled = i < user.lives;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              filled
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: AppColors.error,
                              size: 34,
                            ),
                          );
                        }),
                      ),
              ).animate().scale(begin: const Offset(0.85, 0.85)).fade(),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textMuted, letterSpacing: 0.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              _HeartTile(
                icon: Icons.workspace_premium_rounded,
                iconColor: AppColors.accent,
                title: 'Buggo+ · Ilimitado',
                subtitle:
                    unlimited ? 'Assinatura ativa' : 'Disponível no Market',
                enabled: true,
                highlighted: true,
                onTap: unlimited
                    ? null
                    : () => context.go(AppRouter.market),
              ).animate(delay: 80.ms).slideY(begin: 0.1).fade(),
              const SizedBox(height: 12),

              _HeartTile(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.error,
                title: 'Recarregar tudo',
                subtitle: unlimited || full
                    ? 'Vidas cheias'
                    : '${missing * UserNotifier.lifeCoinCost} moedas',
                enabled: !unlimited &&
                    !full &&
                    user.coins >= missing * UserNotifier.lifeCoinCost,
                onTap: (unlimited || full)
                    ? null
                    : () {
                        final ok =
                            ref.read(userProvider.notifier).refillAllLives();
                        _showResult(ok, 'Vidas recarregadas!',
                            'Moedas insuficientes.');
                      },
              ).animate(delay: 140.ms).slideY(begin: 0.1).fade(),
              const SizedBox(height: 12),

              _HeartTile(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.error,
                title: '+3 vidas',
                subtitle: unlimited || full
                    ? 'Vidas cheias'
                    : '${3 * UserNotifier.lifeCoinCost} moedas',
                enabled: !unlimited &&
                    !full &&
                    user.coins >= 3 * UserNotifier.lifeCoinCost,
                onTap: (unlimited || full)
                    ? null
                    : () {
                        final ok =
                            ref.read(userProvider.notifier).buyLives(3);
                        _showResult(ok, 'Vidas recuperadas!',
                            'Moedas insuficientes.');
                      },
              ).animate(delay: 200.ms).slideY(begin: 0.1).fade(),
              const SizedBox(height: 12),

              _HeartTile(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.error,
                title: '+1 vida',
                subtitle: unlimited || full
                    ? 'Vidas cheias'
                    : '${UserNotifier.lifeCoinCost} moedas',
                enabled: !unlimited &&
                    !full &&
                    user.coins >= UserNotifier.lifeCoinCost,
                onTap: (unlimited || full)
                    ? null
                    : () {
                        final ok = ref.read(userProvider.notifier).buyLife();
                        _showResult(
                            ok, 'Vida recuperada!', 'Moedas insuficientes.');
                      },
              ).animate(delay: 260.ms).slideY(begin: 0.1).fade(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool highlighted;
  final VoidCallback? onTap;

  const _HeartTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? AppColors.accent.withValues(alpha: 0.5)
        : AppColors.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.55 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            gradient: highlighted
                ? LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
