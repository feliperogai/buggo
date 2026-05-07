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
import '../../../../shared/widgets/buggo_button.dart';
import '../../../../shared/widgets/mascot_widget.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  final int levelIndex;
  final int lessonIndex;

  const ChallengeScreen({
    super.key,
    required this.levelIndex,
    required this.lessonIndex,
  });

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  int? _selectedOption;
  bool _answered = false;
  bool _isCorrect = false;

  Lesson get lesson =>
      pythonCurriculum[widget.levelIndex].lessons[widget.lessonIndex];

  void _checkAnswer() {
    if (_selectedOption == null) return;
    final correct = lesson.options[_selectedOption!].isCorrect;
    setState(() {
      _answered = true;
      _isCorrect = correct;
    });
  }

  void _proceed() {
    if (_isCorrect || lesson.type == LessonType.explanation) {
      ref.read(userProvider.notifier).completeLesson(
            lesson.id,
            xp: lesson.xpReward,
            coins: lesson.coinReward,
          );
      final level = pythonCurriculum[widget.levelIndex];
      final isLastLesson = widget.lessonIndex == level.lessons.length - 1;

      context.pushReplacement(AppRouter.success, extra: {
        'xpEarned': lesson.xpReward,
        'coinsEarned': lesson.coinReward,
        'nextRoute': isLastLesson ? AppRouter.home : AppRouter.challenge,
        'nextArgs': isLastLesson
            ? null
            : {
                'levelIndex': widget.levelIndex,
                'lessonIndex': widget.lessonIndex + 1,
              },
      });
    } else {
      setState(() {
        _selectedOption = null;
        _answered = false;
        _isCorrect = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _ProgressHeader(
                levelIndex: widget.levelIndex,
                lessonIndex: widget.lessonIndex,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: lesson.type == LessonType.explanation
                      ? _ExplanationContent(lesson: lesson)
                      : _QuizContent(
                          lesson: lesson,
                          selectedOption: _selectedOption,
                          answered: _answered,
                          isCorrect: _isCorrect,
                          onSelect: _answered
                              ? null
                              : (i) =>
                                  setState(() => _selectedOption = i),
                        ),
                ),
              ),
              _BottomAction(
                lesson: lesson,
                answered: _answered,
                isCorrect: _isCorrect,
                selectedOption: _selectedOption,
                onCheck: _checkAnswer,
                onProceed: _proceed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int levelIndex;
  final int lessonIndex;

  const _ProgressHeader(
      {required this.levelIndex, required this.lessonIndex});

  @override
  Widget build(BuildContext context) {
    final level = pythonCurriculum[levelIndex];
    final total = level.lessons.length;
    final progress = (lessonIndex + 1) / total;

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
              child: const Icon(Icons.close,
                  color: AppColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.cardBorder,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.xpColor, size: 14),
                Text(
                  '+${pythonCurriculum[levelIndex].lessons[lessonIndex].xpReward}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.xpColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationContent extends StatelessWidget {
  final Lesson lesson;

  const _ExplanationContent({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MascotWidget(
          mood: MascotMood.happy,
          speechBubble: 'Vamos aprender algo novo!',
        ).animate().scale(begin: const Offset(0.8, 0.8)).fade(),
        const SizedBox(height: 24),
        Text(lesson.title, style: AppTextStyles.headlineLarge)
            .animate(delay: 200.ms)
            .slideY(begin: 0.3)
            .fade(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            lesson.explanation ?? '',
            style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
          ),
        ).animate(delay: 300.ms).slideY(begin: 0.3).fade(),
        if (lesson.codeSnippet != null) ...[
          const SizedBox(height: 16),
          _CodeBlock(code: lesson.codeSnippet!),
        ],
      ],
    );
  }
}

class _QuizContent extends StatelessWidget {
  final Lesson lesson;
  final int? selectedOption;
  final bool answered;
  final bool isCorrect;
  final ValueChanged<int>? onSelect;

  const _QuizContent({
    required this.lesson,
    required this.selectedOption,
    required this.answered,
    required this.isCorrect,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MascotWidget(
          mood: answered
              ? (isCorrect ? MascotMood.celebrating : MascotMood.thinking)
              : MascotMood.thinking,
          speechBubble: answered
              ? (isCorrect ? 'Arrasou! 🎉' : 'Quase lá! Tente de novo!')
              : 'Qual é a resposta certa?',
        ).animate().scale(begin: const Offset(0.8, 0.8)).fade(),
        const SizedBox(height: 24),
        Text(lesson.title, style: AppTextStyles.headlineMedium)
            .animate(delay: 100.ms)
            .fade(),
        const SizedBox(height: 8),
        if (lesson.codeSnippet != null) ...[
          _CodeBlock(code: lesson.codeSnippet!),
          const SizedBox(height: 16),
        ],
        Text(
          lesson.question ?? '',
          style: AppTextStyles.headlineSmall,
        ).animate(delay: 200.ms).slideY(begin: 0.2).fade(),
        const SizedBox(height: 20),
        ...lesson.options.asMap().entries.map((e) {
          final i = e.key;
          final opt = e.value;
          Color borderColor = AppColors.cardBorder;
          Color bgColor = AppColors.surface;

          if (answered && selectedOption == i) {
            borderColor = opt.isCorrect ? AppColors.neonGreen : AppColors.error;
            bgColor = opt.isCorrect
                ? AppColors.neonGreen.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1);
          } else if (answered && opt.isCorrect) {
            borderColor = AppColors.neonGreen;
            bgColor = AppColors.neonGreen.withOpacity(0.05);
          } else if (!answered && selectedOption == i) {
            borderColor = AppColors.primary;
            bgColor = AppColors.primary.withOpacity(0.1);
          }

          return GestureDetector(
            onTap: () => onSelect?.call(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: answered
                        ? Icon(
                            opt.isCorrect ? Icons.check : Icons.close,
                            size: 16,
                            color: opt.isCorrect
                                ? AppColors.neonGreen
                                : AppColors.error,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(opt.text, style: AppTextStyles.bodyLarge)),
                ],
              ),
            ),
          ).animate(delay: (i * 80).ms).slideX(begin: 0.2).fade();
        }),
        if (answered && !isCorrect && lesson.hint != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.neonYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.neonYellow.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(lesson.hint!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.neonYellow)),
                ),
              ],
            ),
          ).animate().shake().fade(),
        ],
      ],
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;

  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Text(
        code,
        style: AppTextStyles.code.copyWith(height: 1.6),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final Lesson lesson;
  final bool answered;
  final bool isCorrect;
  final int? selectedOption;
  final VoidCallback onCheck;
  final VoidCallback onProceed;

  const _BottomAction({
    required this.lesson,
    required this.answered,
    required this.isCorrect,
    required this.selectedOption,
    required this.onCheck,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    if (lesson.type == LessonType.explanation) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: BuggoButton(
          label: 'Entendi! Continuar',
          onPressed: onProceed,
          width: double.infinity,
          variant: BuggoButtonVariant.success,
        ),
      );
    }

    if (!answered) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: BuggoButton(
          label: 'Verificar',
          onPressed: selectedOption != null ? onCheck : null,
          width: double.infinity,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.neonGreen.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: isCorrect ? AppColors.neonGreen : AppColors.error,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(isCorrect ? '✅' : '❌',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                isCorrect ? 'Correto!' : 'Não foi dessa vez...',
                style: AppTextStyles.headlineSmall.copyWith(
                  color:
                      isCorrect ? AppColors.neonGreen : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BuggoButton(
            label: isCorrect ? 'Continuar' : 'Tentar novamente',
            onPressed: onProceed,
            width: double.infinity,
            variant: isCorrect
                ? BuggoButtonVariant.success
                : BuggoButtonVariant.danger,
          ),
        ],
      ),
    );
  }
}
