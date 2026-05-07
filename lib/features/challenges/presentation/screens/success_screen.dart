import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/buggo_button.dart';
import '../../../../shared/widgets/mascot_widget.dart';

class SuccessScreen extends StatefulWidget {
  final int xpEarned;
  final int coinsEarned;
  final String nextRoute;
  final dynamic nextArgs;

  const SuccessScreen({
    super.key,
    required this.xpEarned,
    required this.coinsEarned,
    required this.nextRoute,
    this.nextArgs,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.primary,
                  AppColors.neonBlue,
                  AppColors.neonGreen,
                  AppColors.neonYellow,
                  AppColors.neonPink,
                ],
                numberOfParticles: 30,
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MascotWidget(
                        mood: MascotMood.celebrating,
                        size: 140,
                        speechBubble: 'Arrasou demais! 🎊',
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          )
                          .fade(),
                      const SizedBox(height: 32),
                      Text(
                        'Lição Concluída!',
                        style: AppTextStyles.displayMedium,
                        textAlign: TextAlign.center,
                      )
                          .animate(delay: 300.ms)
                          .slideY(begin: 0.3)
                          .fade(),
                      const SizedBox(height: 8),
                      Text(
                        'Continue assim e você vai dominar a programação!',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      )
                          .animate(delay: 400.ms)
                          .slideY(begin: 0.3)
                          .fade(),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RewardChip(
                            emoji: '⚡',
                            value: '+${widget.xpEarned} XP',
                            color: AppColors.xpColor,
                          )
                              .animate(delay: 500.ms)
                              .slideX(begin: -0.3)
                              .fade(),
                          const SizedBox(width: 16),
                          _RewardChip(
                            emoji: '🪙',
                            value: '+${widget.coinsEarned}',
                            color: AppColors.coinColor,
                          )
                              .animate(delay: 600.ms)
                              .slideX(begin: 0.3)
                              .fade(),
                        ],
                      ),
                      const SizedBox(height: 48),
                      BuggoButton(
                        label: 'Próxima lição',
                        onPressed: () {
                          if (widget.nextArgs != null) {
                            context.go(widget.nextRoute,
                                extra: widget.nextArgs);
                          } else {
                            context.go(widget.nextRoute);
                          }
                        },
                        width: double.infinity,
                        variant: BuggoButtonVariant.success,
                      ).animate(delay: 700.ms).slideY(begin: 0.3).fade(),
                      const SizedBox(height: 12),
                      BuggoButton(
                        label: 'Voltar ao Início',
                        onPressed: () => context.go('/home'),
                        width: double.infinity,
                        variant: BuggoButtonVariant.ghost,
                      ).animate(delay: 800.ms).fade(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;

  const _RewardChip({
    required this.emoji,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
