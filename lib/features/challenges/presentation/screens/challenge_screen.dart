import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/python_simulator.dart';
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
  // Quiz state
  int? _selectedOption;
  bool _answered = false;
  bool _isCorrect = false;

  // Code-fill state
  List<String?> _filledTokens = [];
  int? _selectedBlank;
  bool _hasRun = false;
  bool _runCorrect = false;
  String _terminalOutput = '';

  @override
  void initState() {
    super.initState();
    _initCodeState();
  }

  void _initCodeState() {
    final l = lesson;
    if (l.type == LessonType.codeChallenge && l.correctTokens != null) {
      _filledTokens = List.filled(l.correctTokens!.length, null);
      _selectedBlank = 0;
    }
  }

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

  void _selectBlank(int index) => setState(() => _selectedBlank = index);

  void _fillToken(String token) {
    if (_selectedBlank == null) {
      for (int i = 0; i < _filledTokens.length; i++) {
        if (_filledTokens[i] == null) {
          setState(() {
            _selectedBlank = i;
            _filledTokens[i] = token;
            _hasRun = false;
            _terminalOutput = '';
            _advanceBlank();
          });
          return;
        }
      }
      return;
    }
    setState(() {
      _filledTokens[_selectedBlank!] = token;
      _hasRun = false;
      _terminalOutput = '';
      _advanceBlank();
    });
  }

  void _clearBlank(int index) {
    setState(() {
      _filledTokens[index] = null;
      _selectedBlank = index;
      _hasRun = false;
      _terminalOutput = '';
    });
  }

  void _advanceBlank() {
    for (int i = 0; i < _filledTokens.length; i++) {
      if (_filledTokens[i] == null) {
        _selectedBlank = i;
        return;
      }
    }
    _selectedBlank = null;
  }

  void _runCode() {
    HapticFeedback.mediumImpact();
    final l = lesson;
    if (l.codeTemplate == null || l.correctTokens == null) return;

    if (_filledTokens.any((t) => t == null)) {
      setState(() {
        _hasRun = true;
        _runCorrect = false;
        _terminalOutput =
            'SyntaxError: invalid syntax\n\nPreencha todos os espaços!';
      });
      return;
    }

    String code = l.codeTemplate!;
    for (int i = 0; i < _filledTokens.length; i++) {
      code = code.replaceAll('{$i}', _filledTokens[i]!);
    }

    try {
      final output = PythonSimulator().simulate(code);
      final expected = (l.expectedOutput ?? '').trim();
      final correct = output.trim() == expected;

      setState(() {
        _hasRun = true;
        _runCorrect = correct;
        _terminalOutput = correct
            ? output
            : '$output${output.isNotEmpty ? '\n\n' : ''}Resultado incorreto!'
                '${l.hint != null ? '\n  ${l.hint}' : ''}';
      });
    } on SimulatorError catch (e) {
      setState(() {
        _hasRun = true;
        _runCorrect = false;
        _terminalOutput = e.message;
      });
    } catch (e) {
      setState(() {
        _hasRun = true;
        _runCorrect = false;
        _terminalOutput = 'RuntimeError: $e';
      });
    }
  }

  void _resetCode() {
    setState(() {
      _filledTokens = List.filled(lesson.correctTokens!.length, null);
      _selectedBlank = 0;
      _hasRun = false;
      _terminalOutput = '';
    });
  }

  void _proceed() {
    final done = _isCorrect || lesson.type == LessonType.explanation || _runCorrect;

    if (done) {
      ref.read(userProvider.notifier).completeLesson(
            lesson.id,
            xp: lesson.xpReward,
            coins: lesson.coinReward,
          );
      final level = pythonCurriculum[widget.levelIndex];
      final isLast = widget.lessonIndex == level.lessons.length - 1;
      context.pushReplacement(AppRouter.success, extra: {
        'xpEarned': lesson.xpReward,
        'coinsEarned': lesson.coinReward,
        'nextRoute': isLast ? AppRouter.home : AppRouter.challenge,
        'nextArgs': isLast
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(
              levelIndex: widget.levelIndex,
              lessonIndex: widget.lessonIndex,
            ),
            Expanded(
              child: lesson.type == LessonType.codeChallenge
                  ? _buildCodeChallenge()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: lesson.type == LessonType.explanation
                          ? _ExplanationContent(lesson: lesson)
                          : _QuizContent(
                              lesson: lesson,
                              selectedOption: _selectedOption,
                              answered: _answered,
                              isCorrect: _isCorrect,
                              onSelect: _answered
                                  ? null
                                  : (i) => setState(() => _selectedOption = i),
                            ),
                    ),
            ),
            if (lesson.type != LessonType.codeChallenge)
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
    );
  }

  Widget _buildCodeChallenge() {
    final l = lesson;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.title, style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      l.question ?? 'Complete o código:',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MascotWidget(
                mood: _hasRun
                    ? (_runCorrect ? MascotMood.celebrating : MascotMood.sad)
                    : MascotMood.thinking,
                size: 72,
              ),
            ],
          ).animate().fade(duration: 300.ms),

          const SizedBox(height: 16),

          // Code editor panel
          _ModernPanel(
            borderColor: AppColors.primary.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EditorBar(onReset: _resetCode),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: _CodeTemplateDisplay(
                    template: l.codeTemplate!,
                    filledTokens: _filledTokens,
                    selectedBlank: _selectedBlank,
                    onSelectBlank: _selectBlank,
                    onClearBlank: _clearBlank,
                  ),
                ),
              ],
            ),
          ).animate(delay: 150.ms).slideY(begin: 0.1).fade(),

          const SizedBox(height: 16),

          // Token bank
          Text('Tokens disponíveis',
              style: AppTextStyles.labelSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: l.availableTokens!.map((token) {
              final inUse = _filledTokens.contains(token);
              return GestureDetector(
                onTap: () => _fillToken(token),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: inUse ? 0.3 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      token,
                      style: AppTextStyles.code
                          .copyWith(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ),
              );
            }).toList(),
          ).animate(delay: 250.ms).fade(),

          const SizedBox(height: 20),

          // RUN button
          GestureDetector(
            onTap: _runCode,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text('Executar',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white)),
                ],
              ),
            ),
          ).animate(delay: 300.ms).slideY(begin: 0.1).fade(),

          if (_hasRun) ...[
            const SizedBox(height: 16),
            _TerminalPanel(output: _terminalOutput, isSuccess: _runCorrect)
                .animate()
                .slideY(begin: 0.15)
                .fade(),
            const SizedBox(height: 16),
            _runCorrect
                ? GestureDetector(
                    onTap: _proceed,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text('Continuar',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ).animate().scale(begin: const Offset(0.94, 0.94)).fade()
                : GestureDetector(
                    onTap: _resetCode,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: AppColors.error, size: 22),
                          const SizedBox(width: 8),
                          Text('Tentar novamente',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ).animate().shake(hz: 3, offset: const Offset(4, 0)),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Modern Panel ───────────────────────────────────────────────
class _ModernPanel extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _ModernPanel({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Editor Bar ─────────────────────────────────────────────────
class _EditorBar extends StatelessWidget {
  final VoidCallback onReset;
  const _EditorBar({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.code_rounded, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text('main.py',
              style: AppTextStyles.code
                  .copyWith(color: AppColors.primary, fontSize: 12)),
          const Spacer(),
          GestureDetector(
            onTap: onReset,
            child: Text('Limpar',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ── Code Template Display ──────────────────────────────────────
class _CodeTemplateDisplay extends StatelessWidget {
  final String template;
  final List<String?> filledTokens;
  final int? selectedBlank;
  final Function(int) onSelectBlank;
  final Function(int) onClearBlank;

  const _CodeTemplateDisplay({
    required this.template,
    required this.filledTokens,
    required this.selectedBlank,
    required this.onSelectBlank,
    required this.onClearBlank,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: template.split('\n').map((line) => _buildLine(line)).toList(),
    );
  }

  Widget _buildLine(String line) {
    final regex = RegExp(r'\{(\d+)\}');
    final matches = regex.allMatches(line).toList();

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(line,
            style: AppTextStyles.code
                .copyWith(fontSize: 13, height: 1.8, color: AppColors.textPrimary)),
      );
    }

    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(
          text: line.substring(cursor, m.start),
          style: AppTextStyles.code
              .copyWith(fontSize: 13, height: 1.8, color: AppColors.textPrimary),
        ));
      }

      final idx = int.parse(m.group(1)!);
      final filled = idx < filledTokens.length ? filledTokens[idx] : null;
      final isSelected = selectedBlank == idx;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () {
            if (filled != null) {
              onClearBlank(idx);
            } else {
              onSelectBlank(idx);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: filled != null
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : isSelected
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border(
                bottom: BorderSide(
                  color: filled != null
                      ? AppColors.primary
                      : isSelected
                          ? AppColors.accent
                          : AppColors.cardBorder,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              filled ?? (isSelected ? '  ···  ' : '  ___  '),
              style: AppTextStyles.code.copyWith(
                fontSize: 13,
                color: filled != null
                    ? AppColors.primary
                    : isSelected
                        ? AppColors.accent
                        : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ));

      cursor = m.end;
    }

    if (cursor < line.length) {
      spans.add(TextSpan(
        text: line.substring(cursor),
        style: AppTextStyles.code
            .copyWith(fontSize: 13, height: 1.8, color: AppColors.textPrimary),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(TextSpan(children: spans)),
    );
  }
}

// ── Terminal Panel ─────────────────────────────────────────────
class _TerminalPanel extends StatelessWidget {
  final String output;
  final bool isSuccess;

  const _TerminalPanel({required this.output, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  isSuccess ? '  Sucesso' : '  Erro',
                  style: AppTextStyles.labelSmall.copyWith(color: color),
                ),
                const Spacer(),
                Text('Terminal',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$ python main.py',
                  style: AppTextStyles.code.copyWith(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  output,
                  style: AppTextStyles.code.copyWith(
                    color: isSuccess
                        ? AppColors.success
                        : AppColors.error.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Header ────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  final int levelIndex;
  final int lessonIndex;

  const _ProgressHeader({required this.levelIndex, required this.lessonIndex});

  @override
  Widget build(BuildContext context) {
    final level = pythonCurriculum[levelIndex];
    final total = level.lessons.length;
    final progress = (lessonIndex + 1) / total;
    final xpReward = level.lessons[lessonIndex].xpReward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Stack(
                children: [
                  Container(height: 10, color: AppColors.cardBorder),
                  FractionallySizedBox(
                    widthFactor: progress,
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
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.xpColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.xpColor, size: 14),
                Text(
                  '+$xpReward',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.xpColor, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Explanation Content ────────────────────────────────────────
class _ExplanationContent extends StatelessWidget {
  final Lesson lesson;
  const _ExplanationContent({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MascotWidget(
          mood: MascotMood.happy,
          speechBubble: 'Vamos aprender algo novo',
        ).animate().scale(begin: const Offset(0.85, 0.85)).fade(),
        const SizedBox(height: 24),
        Text(lesson.title, style: AppTextStyles.headlineLarge)
            .animate(delay: 150.ms).slideY(begin: 0.3).fade(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            lesson.explanation ?? '',
            style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
          ),
        ).animate(delay: 250.ms).slideY(begin: 0.3).fade(),
        if (lesson.codeSnippet != null) ...[
          const SizedBox(height: 16),
          _CodeBlock(code: lesson.codeSnippet!),
        ],
      ],
    );
  }
}

// ── Quiz Content ───────────────────────────────────────────────
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
              ? (isCorrect ? 'Arrasou!' : 'Quase lá, tente de novo!')
              : 'Qual é a resposta certa?',
        ).animate().scale(begin: const Offset(0.85, 0.85)).fade(),
        const SizedBox(height: 20),
        Text(lesson.title, style: AppTextStyles.headlineMedium)
            .animate(delay: 100.ms).fade(),
        const SizedBox(height: 8),
        if (lesson.codeSnippet != null) ...[
          _CodeBlock(code: lesson.codeSnippet!),
          const SizedBox(height: 14),
        ],
        Text(lesson.question ?? '', style: AppTextStyles.headlineSmall)
            .animate(delay: 180.ms).slideY(begin: 0.2).fade(),
        const SizedBox(height: 18),
        ...lesson.options.asMap().entries.map((e) {
          final i = e.key;
          final opt = e.value;
          Color border = AppColors.cardBorder;
          Color bg = AppColors.surface;

          if (answered && selectedOption == i) {
            border = opt.isCorrect ? AppColors.success : AppColors.error;
            bg = opt.isCorrect
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.error.withValues(alpha: 0.08);
          } else if (answered && opt.isCorrect) {
            border = AppColors.success;
            bg = AppColors.success.withValues(alpha: 0.05);
          } else if (!answered && selectedOption == i) {
            border = AppColors.primary;
            bg = AppColors.primary.withValues(alpha: 0.07);
          }

          return GestureDetector(
            onTap: () => onSelect?.call(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: border.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: border.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: border, width: 1.5),
                    ),
                    child: answered
                        ? Icon(
                            opt.isCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            size: 14,
                            color: opt.isCorrect
                                ? AppColors.success
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
          ).animate(delay: (i * 70).ms).slideX(begin: 0.2).fade();
        }),
        if (answered && !isCorrect && lesson.hint != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(lesson.hint!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.accent)),
                ),
              ],
            ),
          ).animate().shake().fade(),
        ],
      ],
    );
  }
}

// ── Code Block ─────────────────────────────────────────────────
class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Text(code,
          style: AppTextStyles.code.copyWith(
              height: 1.65, fontSize: 13, color: AppColors.primaryLight)),
    );
  }
}

// ── Bottom Action ──────────────────────────────────────────────
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
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: AppColors.surface,
        child: BuggoButton(
          label: 'Entendi! Continuar',
          onPressed: onProceed,
          width: double.infinity,
          variant: BuggoButtonVariant.success,
        ),
      );
    }

    if (!answered) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: AppColors.surface,
        child: BuggoButton(
          label: 'Verificar',
          onPressed: selectedOption != null ? onCheck : null,
          width: double.infinity,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.error.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(
            color: isCorrect
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.error.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                isCorrect ? 'Correto!' : 'Não foi dessa vez...',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isCorrect ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
