import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/content/python_curriculum.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/xp_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final totalLessons = pythonCurriculum
        .expand((l) => l.lessons)
        .length;
    final completedCount = user.completedLessons.length;
    final completionPct =
        totalLessons > 0 ? (completedCount / totalLessons * 100).round() : 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: AppColors.textPrimary, size: 18),
                            ),
                          ),
                          const Spacer(),
                          Text('Perfil', style: AppTextStyles.headlineSmall),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.displayMedium,
                          ),
                        ),
                      ).animate().scale(begin: const Offset(0.8, 0.8)).fade(),
                      const SizedBox(height: 12),
                      Text(user.name, style: AppTextStyles.headlineLarge)
                          .animate(delay: 100.ms)
                          .fade(),
                      Text(
                        _levelLabel(user.level),
                        style: AppTextStyles.bodyMedium,
                      ).animate(delay: 150.ms).fade(),
                      const SizedBox(height: 24),
                      XpBar(
                        xp: user.xp,
                        progress: user.xpProgress,
                        level: user.currentLevel,
                      ).animate(delay: 200.ms).slideY(begin: 0.2).fade(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              icon: '🔥',
                              value: '${user.streak}',
                              label: 'Dias seguidos',
                              color: AppColors.streakColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              icon: '🪙',
                              value: '${user.coins}',
                              label: 'Moedas',
                              color: AppColors.coinColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              icon: '✅',
                              value: '$completionPct%',
                              label: 'Completo',
                              color: AppColors.neonGreen,
                            ),
                          ),
                        ],
                      ).animate(delay: 300.ms).slideY(begin: 0.3).fade(),
                      const SizedBox(height: 24),
                      _ProgressCard(
                        completedLessons: completedCount,
                        totalLessons: totalLessons,
                      ).animate(delay: 400.ms).slideY(begin: 0.3).fade(),
                      const SizedBox(height: 24),
                      _AchievementsSection(user: user)
                          .animate(delay: 500.ms)
                          .slideY(begin: 0.3)
                          .fade(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'child':
        return 'Criança';
      case 'teen':
        return 'Adolescente';
      default:
        return 'Adulto';
    }
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.headlineMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int completedLessons;
  final int totalLessons;

  const _ProgressCard({
    required this.completedLessons,
    required this.totalLessons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progresso Geral', style: AppTextStyles.headlineSmall),
              Text(
                '$completedLessons/$totalLessons',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalLessons > 0 ? completedLessons / totalLessons : 0,
              backgroundColor: AppColors.cardBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'lições concluídas de $totalLessons no total',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final dynamic user;

  const _AchievementsSection({required this.user});

  static const _achievements = [
    {'id': 'first_lesson', 'label': 'Primeira Lição', 'emoji': '🌟'},
    {'id': 'five_lessons', 'label': '5 Lições', 'emoji': '🏅'},
    {'id': 'streak_3', 'label': '3 Dias Seguidos', 'emoji': '🔥'},
    {'id': 'python_start', 'label': 'Pythonista', 'emoji': '🐍'},
  ];

  bool _isUnlocked(Map<String, String> a, dynamic user) {
    switch (a['id']) {
      case 'first_lesson':
        return user.completedLessons.isNotEmpty;
      case 'five_lessons':
        return user.completedLessons.length >= 5;
      case 'streak_3':
        return user.streak >= 3;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Conquistas', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _achievements.length,
          itemBuilder: (context, i) {
            final a = _achievements[i];
            final unlocked = _isUnlocked(a, user);
            return Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.cardBorder,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: unlocked
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      a['emoji']!,
                      style: TextStyle(
                          fontSize: 24,
                          color: unlocked ? null : Colors.transparent),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a['label']!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: unlocked
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
