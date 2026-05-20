import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
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
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.07),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.success,
                AppColors.accent,
                AppColors.levelPink,
                AppColors.primaryLight,
              ],
              numberOfParticles: 50,
              minimumSize: const Size(6, 6),
              maximumSize: const Size(16, 16),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return const Icon(
                          Icons.star_rounded,
                          color: AppColors.accent,
                          size: 32,
                        )
                            .animate(delay: (200 + i * 120).ms)
                            .scale(
                              begin: const Offset(0, 0),
                              curve: Curves.elasticOut,
                              duration: 600.ms,
                            )
                            .fade();
                      }),
                    ),

                    const SizedBox(height: 20),

                    const MascotWidget(
                      mood: MascotMood.celebrating,
                      size: 130,
                      speechBubble: 'Arrasou demais!',
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.3, 0.3),
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                        )
                        .fade(),

                    const SizedBox(height: 28),

                    // "Lição concluída" com gradiente
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.successGradient.createShader(bounds),
                      child: Text(
                        'Lição\nConcluída!',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate(delay: 300.ms).slideY(begin: 0.3).fade(),

                    const SizedBox(height: 8),

                    Text(
                      'Continue assim e você vai dominar a programação!',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ).animate(delay: 400.ms).fade(),

                    const SizedBox(height: 32),

                    // Reward cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RewardCard(
                          label: '+${widget.xpEarned} XP',
                          icon: Icons.bolt_rounded,
                          color: AppColors.xpColor,
                        ).animate(delay: 500.ms).slideX(begin: -0.4).fade(),
                        const SizedBox(width: 16),
                        _RewardCard(
                          label: '+${widget.coinsEarned}',
                          icon: Icons.monetization_on_rounded,
                          color: AppColors.coinColor,
                        ).animate(delay: 620.ms).slideX(begin: 0.4).fade(),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Próxima lição
                    GestureDetector(
                      onTap: () => widget.nextArgs != null
                          ? context.go(widget.nextRoute, extra: widget.nextArgs)
                          : context.go(widget.nextRoute),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text('Próxima lição',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ).animate(delay: 700.ms).slideY(begin: 0.3).fade(),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () => context.go('/home'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: AppColors.cardBorder, width: 1.5),
                        ),
                        child: Text(
                          'Voltar ao início',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ).animate(delay: 800.ms).fade(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _RewardCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
