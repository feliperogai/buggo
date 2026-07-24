import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/bootstrap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/user_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  late final Future<void> _bootstrapFuture;
  bool _navigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    // Kicked off now (after the first frame) so it runs alongside the
    // splash animation instead of delaying it.
    _bootstrapFuture = bootstrapApp();
    _lottieController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _navigate();
      });
    // Safety net in case the animation asset fails to load for any reason.
    _fallbackTimer = Timer(const Duration(seconds: 6), _navigate);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted || _navigated) return;
    _navigated = true;
    await _bootstrapFuture;
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
            child: SizedBox(
              width: 280,
              height: 280,
              child: Lottie.asset(
                'assets/animations/splash_loading.json',
                controller: _lottieController,
                repeat: false,
                onLoaded: (composition) {
                  _lottieController.duration = composition.duration;
                  _lottieController.forward();
                },
              ),
            ).animate().fade(duration: 300.ms),
          ),
        ],
      ),
    );
  }
}
