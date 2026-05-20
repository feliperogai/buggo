import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../data/content/python_curriculum.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/user_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRouter.onboarding);
      });
      return const SizedBox.shrink();
    }

    final totalLessons =
        pythonCurriculum.expand((level) => level.lessons).length;
    final completedLessons = user.completedLessons.length;
    final completedPercent =
        totalLessons == 0 ? 0 : (completedLessons / totalLessons * 100).round();
    final achievements = _buildAchievements(user, completedLessons);
    final unlocked = achievements.where((item) => item.isUnlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1.4,
                              ),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Troféus',
                                  style: AppTextStyles.headlineLarge
                                      .copyWith(color: Colors.white),
                                ),
                                Text(
                                  'Seu progresso em destaque',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.76),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderMetric(
                              icon: Icons.workspace_premium_rounded,
                              value: '$unlocked/${achievements.length}',
                              label: 'liberados',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HeaderMetric(
                              icon: Icons.check_circle_rounded,
                              value: '$completedPercent%',
                              label: 'concluído',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final achievement = achievements[index];
                  return _AchievementCard(achievement: achievement)
                      .animate(delay: (index * 70).ms)
                      .slideY(begin: 0.16)
                      .fade();
                },
                childCount: achievements.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_AchievementItem> _buildAchievements(
  UserProfile user,
  int completedLessons,
) {
  return [
    _AchievementItem(
      title: 'Primeiro passo',
      description: 'Complete uma lição',
      icon: Icons.flag_rounded,
      color: AppColors.success,
      isUnlocked: completedLessons >= 1,
    ),
    _AchievementItem(
      title: 'Ritmo forte',
      description: 'Complete 5 lições',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.streakColor,
      isUnlocked: completedLessons >= 5,
    ),
    _AchievementItem(
      title: 'Maratona',
      description: 'Complete 10 lições',
      icon: Icons.directions_run_rounded,
      color: AppColors.levelBlue,
      isUnlocked: completedLessons >= 10,
    ),
    _AchievementItem(
      title: 'Sequência',
      description: 'Estude 3 dias seguidos',
      icon: Icons.bolt_rounded,
      color: AppColors.xpColor,
      isUnlocked: user.streak >= 3,
    ),
    _AchievementItem(
      title: 'Colecionador',
      description: 'Guarde 50 moedas',
      icon: Icons.monetization_on_rounded,
      color: AppColors.coinColor,
      isUnlocked: user.coins >= 50,
    ),
    _AchievementItem(
      title: 'Nível 2',
      description: 'Suba seu nível',
      icon: Icons.trending_up_rounded,
      color: AppColors.levelPink,
      isUnlocked: user.currentLevel >= 2,
    ),
  ];
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style:
                    AppTextStyles.headlineSmall.copyWith(color: Colors.white),
              ),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final _AchievementItem achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final color = achievement.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isUnlocked ? color.withValues(alpha: 0.30) : AppColors.cardBorder,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? color.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isUnlocked ? achievement.icon : Icons.lock_rounded,
              color: isUnlocked ? color : AppColors.textMuted,
              size: 28,
            ),
          ),
          const Spacer(),
          Text(
            achievement.title,
            style: AppTextStyles.headlineSmall.copyWith(
              color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: isUnlocked ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  const _AchievementItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}
