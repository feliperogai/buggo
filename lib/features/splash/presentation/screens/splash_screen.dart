import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/mascot_widget.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final user = ref.read(userProvider);
    context.go(user != null ? AppRouter.home : AppRouter.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Círculos decorativos no fundo
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.07),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MascotWidget(mood: MascotMood.happy, size: 140)
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    )
                    .fade(duration: 400.ms),

                const SizedBox(height: 36),

                // Logo BUGGO com gradiente
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    'Buggo',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                )
                    .animate(delay: 350.ms)
                    .slideY(begin: 0.4, duration: 500.ms, curve: Curves.easeOut)
                    .fade(),

                const SizedBox(height: 8),

                Text(
                  'Aprenda a programar brincando',
                  style: AppTextStyles.bodyMedium,
                ).animate(delay: 550.ms).fade(duration: 400.ms),

                const SizedBox(height: 60),

                _SmoothDotLoader().animate(delay: 900.ms).fade(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothDotLoader extends StatefulWidget {
  @override
  State<_SmoothDotLoader> createState() => _SmoothDotLoaderState();
}

class _SmoothDotLoaderState extends State<_SmoothDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final step = (_ctrl.value * 3).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final active = i == step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 24 : 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                gradient: active ? AppColors.primaryGradient : null,
                color: active ? null : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        );
      },
    );
  }
}
