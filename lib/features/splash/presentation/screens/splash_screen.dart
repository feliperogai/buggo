import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final hasProfile = HiveStorage.user.get('profile') != null;
    context.go(hasProfile ? AppRouter.home : AppRouter.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.6),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🐛', style: TextStyle(fontSize: 72)),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fade(duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                'Buggo',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 52,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.neonBlue],
                    ).createShader(
                      const Rect.fromLTWH(0, 0, 200, 60),
                    ),
                ),
              )
                  .animate(delay: 300.ms)
                  .slideY(begin: 0.5, end: 0, duration: 500.ms)
                  .fade(duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                'Aprenda a programar brincando!',
                style: AppTextStyles.bodyMedium,
              )
                  .animate(delay: 600.ms)
                  .slideY(begin: 0.3, end: 0, duration: 400.ms)
                  .fade(duration: 400.ms),
              const SizedBox(height: 60),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withOpacity(0.6),
                  ),
                ),
              ).animate(delay: 900.ms).fade(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
