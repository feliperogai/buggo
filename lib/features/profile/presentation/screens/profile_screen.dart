import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../data/content/python_curriculum.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/pixel_avatars.dart';
import '../../../../shared/widgets/xp_bar.dart';
import 'avatar_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final total = pythonCurriculum.expand((l) => l.lessons).length;
    final done = user.completedLessons.length;
    final pct = total > 0 ? (done / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Gradient header
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    children: [
                      // Nav row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.canPop()
                                ? context.pop()
                                : context.go(AppRouter.home),
                            child: Container(
                              width: 40,
                              height: 40,
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
                          const Spacer(),
                          Text('Perfil',
                              style: AppTextStyles.headlineSmall
                                  .copyWith(color: Colors.white)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push(AppRouter.settings),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.5),
                              ),
                              child: const Icon(Icons.settings_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Avatar
                      GestureDetector(
                        onTap: () => showAvatarPicker(context, ref),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: PixelAvatar(
                                avatarIndex: user.avatarIndex,
                                customPhotoPath: user.customPhotoPath,
                                size: 96,
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(begin: const Offset(0.7, 0.7)).fade(),

                      const SizedBox(height: 12),

                      Text(user.name,
                              style: AppTextStyles.headlineLarge
                                  .copyWith(color: Colors.white))
                          .animate(delay: 100.ms)
                          .fade(),

                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _levelLabel(user.level),
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white),
                        ),
                      ).animate(delay: 150.ms).fade(),

                      const SizedBox(height: 4),
                      Text(
                        'Toque no avatar para trocar',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.6)),
                      ).animate(delay: 200.ms).fade(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  XpBar(
                    xp: user.xp,
                    progress: user.xpProgress,
                    level: user.currentLevel,
                  ).animate(delay: 250.ms).slideY(begin: 0.2).fade(),

                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                            icon: Icons.local_fire_department_rounded,
                            value: '${user.streak}',
                            label: 'Streak',
                            color: AppColors.streakColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                            icon: Icons.monetization_on_rounded,
                            value: '${user.coins}',
                            label: 'Moedas',
                            color: AppColors.coinColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                            icon: Icons.check_circle_rounded,
                            value: '$pct%',
                            label: 'Completo',
                            color: AppColors.success),
                      ),
                    ],
                  ).animate(delay: 300.ms).slideY(begin: 0.3).fade(),

                  const SizedBox(height: 20),

                  _ProgressCard(completed: done, total: total)
                      .animate(delay: 400.ms)
                      .slideY(begin: 0.3)
                      .fade(),

                  const SizedBox(height: 20),

                  _AchievementsSection(user: user)
                      .animate(delay: 500.ms)
                      .slideY(begin: 0.3)
                      .fade(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'beginner':
        return 'Iniciante';
      case 'some':
        return 'Intermediário';
      case 'intermediate':
        return 'Avançado';
      default:
        return 'Jogador';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.headlineMedium.copyWith(color: color)),
          Text(label,
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int completed;
  final int total;

  const _ProgressCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progresso geral', style: AppTextStyles.bodyLarge),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$completed/$total',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              children: [
                Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(100),
                    )),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('lições concluídas de $total no total',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _Achievement {
  final String id;
  final String label;
  final IconData icon;
  const _Achievement(this.id, this.label, this.icon);
}

class _AchievementsSection extends StatelessWidget {
  final dynamic user;
  const _AchievementsSection({required this.user});

  static const _achievements = [
    _Achievement('first_lesson', 'Primeira\nLição', Icons.star_rounded),
    _Achievement('five_lessons', '5\nLições', Icons.military_tech_rounded),
    _Achievement(
        'streak_3', '3 Dias\nSeguidos', Icons.local_fire_department_rounded),
    _Achievement('python_start', 'Pythonista', Icons.terminal_rounded),
  ];

  bool _unlocked(_Achievement a) {
    switch (a.id) {
      case 'first_lesson':
        return (user.completedLessons as List).isNotEmpty;
      case 'five_lessons':
        return (user.completedLessons as List).length >= 5;
      case 'streak_3':
        return (user.streak as int) >= 3;
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
          itemBuilder: (_, i) {
            final a = _achievements[i];
            final on = _unlocked(a);
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: on ? AppColors.accentGradient : null,
                    color: on ? null : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: on
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    a.icon,
                    color: on ? Colors.white : AppColors.textMuted,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: on ? AppColors.textPrimary : AppColors.textMuted,
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
