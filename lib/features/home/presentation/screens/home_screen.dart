import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../data/content/python_curriculum.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/mascot_widget.dart';
import '../../../../shared/widgets/xp_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRouter.onboarding);
      });
      return const SizedBox.shrink();
    }

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(user: user),
                      const SizedBox(height: 20),
                      XpBar(
                        xp: user.xp,
                        progress: user.xpProgress,
                        level: user.currentLevel,
                      ),
                      const SizedBox(height: 16),
                      _StatsRow(user: user),
                      const SizedBox(height: 28),
                      _StreakBanner(streak: user.streak),
                      const SizedBox(height: 28),
                      Text('Trilha de Aprendizado',
                          style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final level = pythonCurriculum[index];
                    final completedInLevel = level.lessons
                        .where((l) => user.completedLessons.contains(l.id))
                        .length;
                    final isUnlocked = index == 0 ||
                        pythonCurriculum[index - 1].lessons.every(
                            (l) => user.completedLessons.contains(l.id));

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: _LevelCard(
                        levelIndex: index,
                        title: level.title,
                        description: level.description,
                        emoji: level.emoji,
                        totalLessons: level.lessons.length,
                        completedLessons: completedInLevel,
                        isUnlocked: isUnlocked,
                        onTap: isUnlocked
                            ? () => context.push(
                                  AppRouter.levelMap,
                                  extra: index,
                                )
                            : null,
                      )
                          .animate(delay: (index * 80).ms)
                          .slideX(begin: 0.2)
                          .fade(),
                    );
                  },
                  childCount: pythonCurriculum.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(current: 0),
    );
  }
}

class _Header extends StatelessWidget {
  final dynamic user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, ${user.name}! 👋',
                  style: AppTextStyles.headlineMedium),
              Text('Pronto para aprender hoje?',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push(AppRouter.profile),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: AppTextStyles.headlineSmall,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatChip(
          icon: Icons.local_fire_department,
          value: '${user.streak} dias',
          color: AppColors.streakColor,
        ),
        const SizedBox(width: 8),
        StatChip(
          icon: Icons.monetization_on,
          value: '${user.coins}',
          color: AppColors.coinColor,
        ),
        const SizedBox(width: 8),
        StatChip(
          icon: Icons.star,
          value: '${user.xp} XP',
          color: AppColors.xpColor,
        ),
      ],
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFFE600)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak dias seguidos!',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: Colors.white),
                ),
                Text(
                  'Incrível! Continue assim!',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int levelIndex;
  final String title;
  final String description;
  final String emoji;
  final int totalLessons;
  final int completedLessons;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.levelIndex,
    required this.title,
    required this.description,
    required this.emoji,
    required this.totalLessons,
    required this.completedLessons,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;
    final isCompleted = completedLessons == totalLessons;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? AppColors.neonGreen
                : isUnlocked
                    ? AppColors.cardBorder
                    : AppColors.cardBorder.withOpacity(0.4),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.5,
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? AppColors.primaryGradient
                      : const LinearGradient(
                          colors: [AppColors.cardBorder, AppColors.surface]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? emoji : '🔒',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headlineSmall),
                    Text(description, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.cardBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? AppColors.neonGreen : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedLessons/$totalLessons lições',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCompleted)
                const Icon(Icons.check_circle,
                    color: AppColors.neonGreen, size: 28)
              else if (isUnlocked)
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  const _BottomNav({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
              icon: Icons.home_rounded,
              label: 'Início',
              isActive: current == 0,
              onTap: () => context.go(AppRouter.home)),
          _NavItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              isActive: current == 1,
              onTap: () => context.push(AppRouter.profile)),
          _NavItem(
              icon: Icons.settings_rounded,
              label: 'Config',
              isActive: current == 2,
              onTap: () => context.push(AppRouter.settings)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.textMuted,
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
