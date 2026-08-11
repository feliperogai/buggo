import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ads/ads_service.dart';
import '../../core/audio/sound_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';

/// Shows the user's current lives plus the ways to recover them: a free
/// full refill every 24h, buying with coins, or subscribing to Buggo+
/// (real-money plan, available in the Market) for unlimited lives.
class LivesRecoveryCard extends ConsumerStatefulWidget {
  final UserProfile user;

  const LivesRecoveryCard({super.key, required this.user});

  @override
  ConsumerState<LivesRecoveryCard> createState() => _LivesRecoveryCardState();
}

class _LivesRecoveryCardState extends ConsumerState<LivesRecoveryCard> {
  Timer? _timer;
  bool _watchingAd = false;

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

  void _showSnack(String message, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.success : AppColors.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _buyLife() {
    final ok = ref.read(userProvider.notifier).buyLife();
    if (!mounted) return;
    if (ok) {
      SoundService.instance.playWithHaptic(Sfx.purchase, Haptic.light);
    } else {
      SoundService.instance.haptic(Haptic.heavy);
    }
    _showSnack(
      ok ? 'Vida recuperada!' : 'Moedas insuficientes ou vidas já estão cheias.',
      ok: ok,
    );
  }

  /// Exibe o anúncio premiado e, se o usuário assistir até o fim, devolve
  /// todas as vidas. Fechar o anúncio no meio não dá recompensa — quem
  /// decide isso é o SDK do AdMob, não o app.
  Future<void> _watchAd() async {
    if (_watchingAd) return;
    setState(() => _watchingAd = true);
    try {
      final earned = await AdsService.instance.showRewarded();
      if (!mounted) return;
      if (!earned) {
        SoundService.instance.haptic(Haptic.heavy);
        _showSnack(
          'Anúncio não concluído — as vidas não foram recuperadas.',
          ok: false,
        );
        return;
      }
      final refilled = ref.read(userProvider.notifier).refillLivesFromAd();
      if (!mounted) return;
      if (refilled) {
        SoundService.instance.playWithHaptic(Sfx.purchase, Haptic.light);
      }
      _showSnack(
        refilled ? 'Vidas recuperadas!' : 'Suas vidas já estavam cheias.',
        ok: refilled,
      );
    } finally {
      if (mounted) setState(() => _watchingAd = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final unlimited = user.hasUnlimitedLives;
    final full = user.lives >= UserProfile.maxLives;
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text('Vidas', style: AppTextStyles.headlineSmall),
              const Spacer(),
              if (unlimited)
                const Icon(Icons.all_inclusive_rounded,
                    color: AppColors.error, size: 22)
              else
                Row(
                  children: List.generate(UserProfile.maxLives, (i) {
                    final filled = i < user.lives;
                    return Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Icon(
                        filled
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(status, style: AppTextStyles.bodySmall),
          // Assinante do Buggo+ tem vidas ilimitadas, então o anúncio não
          // teria o que recuperar — o botão só existe para quem precisa.
          if (!unlimited && !full) ...[
            const SizedBox(height: 14),
            _WatchAdButton(loading: _watchingAd, onTap: _watchAd),
          ],
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ActionChip(
                    label: 'Comprar vida',
                    sublabel: '${UserNotifier.lifeCoinCost} moedas',
                    icon: Icons.monetization_on_rounded,
                    enabled: !unlimited &&
                        !full &&
                        user.coins >= UserNotifier.lifeCoinCost,
                    onTap: _buyLife,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionChip(
                    label: 'Buggo+',
                    sublabel: 'Ver no Market',
                    icon: Icons.workspace_premium_rounded,
                    enabled: !unlimited,
                    onTap: () => context.push(AppRouter.market),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão do anúncio premiado. Largura cheia e cor de destaque porque é a
/// única forma gratuita de recuperar vidas na hora — as outras custam
/// moedas ou dinheiro.
class _WatchAdButton extends StatelessWidget {
  final bool loading;
  final Future<void> Function() onTap;

  const _WatchAdButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : () => onTap(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35), width: 1.4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: loading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.success),
                    )
                  : const Icon(Icons.play_circle_fill_rounded,
                      color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loading ? 'Carregando anúncio...' : 'Assistir anúncio',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text('Grátis · recupera todas as vidas',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25), width: 1.3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.error, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(sublabel,
                  textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
