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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(level: level),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: level.lessons.length,
                  itemBuilder: (context, lessonIndex) {
                    final lesson = level.lessons[lessonIndex];
                    final isCompleted =
                        user?.completedLessons.contains(lesson.id) ?? false;
                    final isUnlocked = lessonIndex == 0 ||
                        (user?.completedLessons
                                .contains(level.lessons[lessonIndex - 1].id) ??
                            false);

                    return _LessonNode(
                      lesson: lesson,
                      lessonIndex: lessonIndex,
                      levelIndex: levelId,
                      isCompleted: isCompleted,
                      isUnlocked: isUnlocked,
                      isLast: lessonIndex == level.lessons.length - 1,
                    )
                        .animate(delay: (lessonIndex * 80).ms)
                        .slideY(begin: 0.3)
                        .fade();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final CourseLevel level;

  const _AppBar({required this.level});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Text(level.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level.title, style: AppTextStyles.headlineSmall),
                Text(level.description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
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

  const _LessonNode({
    required this.lesson,
    required this.lessonIndex,
    required this.levelIndex,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isLast,
  });

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

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                              ? AppColors.primaryGradient
                              : const LinearGradient(colors: [
                                  AppColors.cardBorder,
                                  AppColors.surface
                                ]),
                      shape: BoxShape.circle,
                      boxShadow: isUnlocked && !isCompleted
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : isUnlocked
                              ? _typeIcon
                              : Icons.lock_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.neonGreen
                            : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: isUnlocked
                  ? () => context.push(AppRouter.challenge, extra: {
                        'levelIndex': levelIndex,
                        'lessonIndex': lessonIndex,
                      })
                  : null,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.neonGreen.withOpacity(0.5)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Opacity(
                    opacity: isUnlocked ? 1.0 : 0.5,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _typeLabel,
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primaryLight),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(lesson.title,
                                  style: AppTextStyles.bodyLarge),
                              Text(lesson.description,
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt,
                                    color: AppColors.xpColor, size: 14),
                                Text(
                                  '+${lesson.xpReward}',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.xpColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: AppColors.coinColor, size: 14),
                                Text(
                                  '+${lesson.coinReward}',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.coinColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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
