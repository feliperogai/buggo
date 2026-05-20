import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/levels/presentation/screens/level_map_screen.dart';
import '../../features/challenges/presentation/screens/challenge_screen.dart';
import '../../features/challenges/presentation/screens/success_screen.dart';
import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/market/presentation/screens/market_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/main_navigation_shell.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String levelMap = '/level-map';
  static const String challenge = '/challenge';
  static const String success = '/success';
  static const String profile = '/profile';
  static const String trophy = '/trophy';
  static const String market = '/market';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: onboarding,
        pageBuilder: (context, state) =>
            _slidePage(state, const OnboardingScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigationShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: home,
            pageBuilder: (context, state) =>
                _fadePage(state, const HomeScreen()),
          ),
          GoRoute(
            path: levelMap,
            pageBuilder: (context, state) {
              final levelId = state.extra as int? ?? 0;
              return _slidePage(state, LevelMapScreen(levelId: levelId));
            },
          ),
          GoRoute(
            path: challenge,
            pageBuilder: (context, state) {
              final args = state.extra as Map<String, dynamic>? ?? {};
              return _slidePage(
                state,
                ChallengeScreen(
                  levelIndex: args['levelIndex'] as int? ?? 0,
                  lessonIndex: args['lessonIndex'] as int? ?? 0,
                ),
              );
            },
          ),
          GoRoute(
            path: success,
            pageBuilder: (context, state) {
              final args = state.extra as Map<String, dynamic>? ?? {};
              return _slidePage(
                state,
                SuccessScreen(
                  xpEarned: args['xpEarned'] as int? ?? 10,
                  coinsEarned: args['coinsEarned'] as int? ?? 5,
                  nextRoute: args['nextRoute'] as String? ?? AppRouter.home,
                  nextArgs: args['nextArgs'],
                ),
              );
            },
          ),
          GoRoute(
            path: profile,
            pageBuilder: (context, state) =>
                _slidePage(state, const ProfileScreen()),
          ),
          GoRoute(
            path: trophy,
            pageBuilder: (context, state) =>
                _slidePage(state, const AchievementsScreen()),
          ),
          GoRoute(
            path: market,
            pageBuilder: (context, state) =>
                _slidePage(state, const MarketScreen()),
          ),
          GoRoute(
            path: settings,
            pageBuilder: (context, state) =>
                _slidePage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
  );

  static CustomTransitionPage<void> _fadePage(
      GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static CustomTransitionPage<void> _slidePage(
      GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
