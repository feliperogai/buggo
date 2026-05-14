import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../data/content/python_curriculum.dart';
import '../../../../shared/models/lesson.dart';
import '../../../../shared/providers/user_provider.dart';

class LevelMapScreen extends ConsumerWidget {
  final int levelId;

  const LevelMapScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final level = pythonCurriculum[levelId];

    const levelColors = [
      AppColors.levelBlue,
      AppColors.levelGreen,
      AppColors.levelPink,
    ];
    final accent = levelColors[levelId % levelColors.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AppBar(level: level, accent: accent),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: level.lessons.length,
              itemBuilder: (context, idx) {
                final lesson = level.lessons[idx];
                final done = user?.completedLessons.contains(lesson.id) ?? false;
                final unlocked = idx == 0 ||
                    (user?.completedLessons
                            .contains(level.lessons[idx - 1].id) ??
                        false);
                return _LessonNode(
                  lesson: lesson,
                  lessonIndex: idx,
                  levelIndex: levelId,
                  isCompleted: done,
                  isUnlocked: unlocked,
                  isLast: idx == level.lessons.length - 1,
                  accent: accent,
                )
                    .animate(delay: (idx * 70).ms)
                    .slideY(begin: 0.25)
                    .fade();
              },
            ),
          ),
        ],
      ),
    );
  }
}

IconData _levelIcon(int id) {
  const icons = [
    Icons.lightbulb_rounded,
    Icons.terminal_rounded,
    Icons.rocket_launch_rounded,
  ];
  return icons[id % icons.length];
}

class _AppBar extends StatelessWidget {
  final CourseLevel level;
  final Color accent;

  const _AppBar({required this.level, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    _levelIcon(level.id),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(level.title,
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: Colors.white)),
                    Text(level.description,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  final Lesson lesson;
  final int lessonIndex;
  final int levelIndex;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isLast;
  final Color accent;

  const _LessonNode({
    required this.lesson,
    required this.lessonIndex,
    required this.levelIndex,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isLast,
    required this.accent,
  });

  String get _typeLabel {
    switch (lesson.type) {
      case LessonType.explanation:
        return 'Lição';
      case LessonType.quiz:
        return 'Quiz';
      case LessonType.codeChallenge:
        return 'Código';
      default:
        return 'Desafio';
    }
  }

  IconData get _typeIcon {
    switch (lesson.type) {
      case LessonType.explanation:
        return Icons.menu_book_rounded;
      case LessonType.quiz:
        return Icons.quiz_rounded;
      case LessonType.codeChallenge:
        return Icons.code_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodeColor = isCompleted
        ? AppColors.success
        : isUnlocked
            ? accent
            : AppColors.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: node + connector
          SizedBox(
            width: 60,
            child: Column(
              children: [
                GestureDetector(
                  onTap: isUnlocked
                      ? () => context.push(AppRouter.challenge, extra: {
                            'levelIndex': levelIndex,
                            'lessonIndex': lessonIndex,
                          })
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isCompleted
                          ? AppColors.successGradient
                          : isUnlocked
                              ? LinearGradient(
                                  colors: [accent, accent.withValues(alpha: 0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                      color: isUnlocked ? null : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: nodeColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : isUnlocked
                                ? _typeIcon
                                : Icons.lock_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  AppColors.success,
                                  AppColors.success.withValues(alpha: 0.2)
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isCompleted ? null : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right: card
          Expanded(
            child: GestureDetector(
              onTap: isUnlocked
                  ? () => context.push(AppRouter.challenge, extra: {
                        'levelIndex': levelIndex,
                        'lessonIndex': lessonIndex,
                      })
                  : null,
              child: AnimatedOpacity(
                opacity: isUnlocked ? 1.0 : 0.45,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.success.withValues(alpha: 0.4)
                          : isUnlocked
                              ? accent.withValues(alpha: 0.25)
                              : AppColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUnlocked
                            ? nodeColor.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: nodeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _typeLabel,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: nodeColor),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(lesson.title, style: AppTextStyles.bodyLarge),
                            Text(lesson.description,
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RewardBadge(
                              icon: Icons.bolt_rounded,
                              value: '+${lesson.xpReward}',
                              color: AppColors.xpColor),
                          const SizedBox(height: 4),
                          _RewardBadge(
                              icon: Icons.monetization_on_rounded,
                              value: '+${lesson.coinReward}',
                              color: AppColors.coinColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _RewardBadge(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(value,
              style: AppTextStyles.bodySmall
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
