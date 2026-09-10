import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/bootstrap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/settings_provider.dart';
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

    // Ler os providers pode falhar se o bootstrap tiver degradado (uma box do
    // Hive que não abriu, por exemplo). Isso não pode prender o usuário na
    // splash para sempre: na dúvida, segue para o onboarding.
    UserProfile? user;
    try {
      // Primeira leitura do provider: aplica no SoundService as preferências
      // de som/vibração salvas, antes de qualquer tela poder tocar algo.
      ref.read(settingsProvider);
      user = ref.read(userProvider);
      // Refaz o plano de lembretes com o estado de hoje: quem já estudou não
      // recebe cobrança, e quem sumiu por dias passa a receber o texto de
      // volta em vez do de rotina. Não é esperado — a splash não pode ficar
      // presa num agendamento lento.
      unawaited(ref.read(settingsProvider.notifier).syncReminders());
    } catch (e) {
      debugPrint('splash: não foi possível ler o perfil salvo: $e');
    }

    if (!mounted) return;
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
                SizedBox(
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

                const SizedBox(height: 12),

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
                    .animate(delay: 200.ms)
                    .slideY(begin: 0.4, duration: 500.ms, curve: Curves.easeOut)
                    .fade(),

                const SizedBox(height: 8),

                Text(
                  'Aprenda a programar brincando',
                  style: AppTextStyles.bodyMedium,
                ).animate(delay: 400.ms).fade(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
