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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header card com gradiente
          SliverToBoxAdapter(
            child: _HeaderCard(user: user),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.streak > 0) ...[
                    _StreakBanner(streak: user.streak)
                        .animate()
                        .slideX(begin: -0.1)
                        .fade(),
                    const SizedBox(height: 20),
                  ],
                  Text('Trilha de aprendizado',
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Continue de onde parou',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final level = pythonCurriculum[index];
                final completed = level.lessons
                    .where((l) => user.completedLessons.contains(l.id))
                    .length;
                final isUnlocked = index == 0 ||
                    pythonCurriculum[index - 1].lessons.every(
                        (l) => user.completedLessons.contains(l.id));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: _LevelCard(
                    levelIndex: index,
                    title: level.title,
                    description: level.description,
                    emoji: level.emoji,
                    totalLessons: level.lessons.length,
                    completedLessons: completed,
                    isUnlocked: isUnlocked,
                    onTap: isUnlocked
                        ? () => context.push(AppRouter.levelMap, extra: index)
                        : null,
                  )
                      .animate(delay: (index * 80).ms)
                      .slideY(begin: 0.2)
                      .fade(),
                );
              },
              childCount: pythonCurriculum.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: const _BottomNav(current: 0),
    );
  }
}

// ── Header Card ────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final dynamic user;
  const _HeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + avatar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${user.name}!',
                          style: AppTextStyles.headlineMedium
                              .copyWith(color: Colors.white),
                        ),
                        Text(
                          'Pronto para codar hoje?',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.profile),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: PixelAvatar(
                        avatarIndex: user.avatarIndex,
                        customPhotoPath: user.customPhotoPath,
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats chips
              Row(
                children: [
                  _StatPill(
                      iconData: Icons.local_fire_department_rounded,
                      value: '${user.streak}',
                      label: 'dias',
                      color: Colors.white),
                  const SizedBox(width: 8),
                  _StatPill(
                      iconData: Icons.monetization_on_rounded,
                      value: '${user.coins}',
                      label: 'moedas',
                      color: Colors.white),
                  const SizedBox(width: 8),
                  _StatPill(
                      iconData: Icons.bolt_rounded,
                      value: '${user.xp}',
                      label: 'XP',
                      color: Colors.white),
                ],
              ),

              const SizedBox(height: 20),

              // XP bar adaptada para tema escuro
              _WhiteXpBar(
                  xp: user.xp,
                  progress: user.xpProgress,
                  level: user.currentLevel),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData iconData;
  final String value;
  final String label;
  final Color color;

  const _StatPill(
      {required this.iconData,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _WhiteXpBar extends StatelessWidget {
  final int xp;
  final double progress;
  final int level;

  const _WhiteXpBar(
      {required this.xp, required this.progress, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Center(
            child: Text('$level',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nível $level',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  Text('$xp XP',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Stack(
                  children: [
                    Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(100),
                        )),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Streak Banner ──────────────────────────────────────────────
class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.streakColor.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.streakColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.streakColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_fire_department_rounded,
                color: AppColors.streakColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak dias seguidos!',
                  style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.streakColor),
                ),
                Text('Continue assim!',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Level Card ─────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final int levelIndex;
  final String title;
  final String description;
  final String emoji;
  final int totalLessons;
  final int completedLessons;
  final bool isUnlocked;
  final VoidCallback? onTap;

  static const _levelColors = [
    AppColors.levelBlue,
    AppColors.levelGreen,
    AppColors.levelPink,
  ];

  static const _levelIcons = [
    Icons.lightbulb_rounded,
    Icons.terminal_rounded,
    Icons.rocket_launch_rounded,
  ];

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
    final isCompleted = completedLessons == totalLessons && totalLessons > 0;
    final levelColor = _levelColors[levelIndex % _levelColors.length];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.4)
                  : isUnlocked
                      ? levelColor.withValues(alpha: 0.25)
                      : AppColors.cardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : isUnlocked
                        ? levelColor.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Level icon badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? levelColor.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    isUnlocked
                        ? _levelIcons[levelIndex % _levelIcons.length]
                        : Icons.lock_rounded,
                    color: isUnlocked ? levelColor : AppColors.textMuted,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headlineSmall),
                    Text(description, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.cardBorder,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.success
                                    : levelColor,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ],
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                )
              else if (isUnlocked)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: levelColor, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  const _BottomNav({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ),
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textMuted,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
