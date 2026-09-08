import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../data/content/achievements_catalog.dart';
import '../../../../data/content/curriculum.dart';
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

    final totalLessons = totalLessonCount;
    final completedLessons = user.completedLessons.length;
    final completedPercent =
        totalLessons == 0 ? 0 : (completedLessons / totalLessons * 100).round();
    const achievements = achievementCatalog;
    final unlockedFlags = {
      for (final a in achievements)
        a.id: a.isUnlocked(user, completedLessons, totalLessons),
    };
    final unlocked = unlockedFlags.values.where((v) => v).length;

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
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                                  'Conquistas',
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
                  final isUnlocked = unlockedFlags[achievement.id] ?? false;
                  return _AchievementCard(
                    achievement: achievement,
                    isUnlocked: isUnlocked,
                  )
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
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementCard({required this.achievement, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
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
