import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/content/python_curriculum.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/buggo_button.dart';
import '../../../../shared/widgets/mascot_widget.dart';
import '../../data/daily_challenge_models.dart';
import '../../data/daily_challenge_repository.dart';
import '../widgets/code_editor.dart';

/// Desafio do dia: enunciado gerado pela IA a partir do que o aluno já
/// estudou, resolvido digitando código num editor, e corrigido pela IA.
///
/// Errar não custa vida — o aluno tenta até acertar, dentro do teto diário
/// que o servidor aplica.
class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  final _repository = DailyChallengeRepository();
  late final CodeEditingController _codeController = CodeEditingController();

  DailyChallenge? _challenge;
  ChallengeGrade? _grade;

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _outOfAttempts = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_clearErrorLineOnEdit);
    _load();
  }

  @override
  void dispose() {
    _codeController.removeListener(_clearErrorLineOnEdit);
    _codeController.dispose();
    super.dispose();
  }

  /// A linha marcada em vermelho vira ruído assim que o aluno mexe no código,
  /// porque a numeração já não corresponde ao que a IA leu.
  void _clearErrorLineOnEdit() {
    if (_grade?.errorLine != null) {
      setState(() => _grade = null);
    }
  }

  /// Títulos das lições já concluídas — é o contexto que faz o desafio ficar
  /// no nível do aluno em vez de genérico.
  List<String> _studiedTopics(UserProfile user) {
    final completed = user.completedLessons.toSet();
    final titles = <String>[];
    for (final level in pythonCurriculum) {
      for (final lesson in level.lessons) {
        if (completed.contains(lesson.id)) titles.add(lesson.title);
      }
    }
    return titles;
  }

  Future<void> _load() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final challenge =
          await _repository.fetchToday(topics: _studiedTopics(user));
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _outOfAttempts = challenge.attemptsLeft <= 0;
        _codeController.text = challenge.starterCode;
      });
    } on DailyChallengeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível conectar. Verifique sua internet.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final grade = await _repository.submit(_codeController.text);
      if (!mounted) return;

      // O servidor devolve o perfil já com XP e moedas somados quando o aluno
      // acerta; aplicar isso local evita uma segunda ida à rede.
      if (grade.passed && grade.profile != null) {
        ref.read(userProvider.notifier).saveProfile(
              UserProfile.fromMap(grade.profile!),
            );
      }
      SoundService.instance.playWithHaptic(
        grade.passed ? Sfx.lessonComplete : Sfx.wrong,
        grade.passed ? Haptic.medium : Haptic.heavy,
      );
      setState(() {
        _grade = grade;
        _outOfAttempts = grade.attemptsLeft <= 0 && !grade.passed;
      });
    } on DailyChallengeException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          if (e.outOfAttempts) _outOfAttempts = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível enviar. Verifique sua internet.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final solved = _grade?.passed == true || _challenge?.solved == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Desafio do dia', style: AppTextStyles.headlineSmall),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const _LoadingState()
            : _challenge == null
                ? _ErrorState(message: _error, onRetry: _load)
                : _buildChallenge(solved),
      ),
    );
  }

  Widget _buildChallenge(bool solved) {
    final challenge = _challenge!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(challenge: challenge, solved: solved),
                const SizedBox(height: 16),
                _StatementCard(statement: challenge.statement),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.code_rounded,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Seu código', style: AppTextStyles.headlineSmall),
                    const Spacer(),
                    Text(
                      challenge.language,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 240),
                  child: CodeEditor(
                    controller: _codeController,
                    readOnly: solved,
                    errorLine: _grade?.errorLine,
                  ),
                ),
                if (_grade != null) ...[
                  const SizedBox(height: 14),
                  _FeedbackCard(grade: _grade!),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        _BottomBar(
          solved: solved,
          submitting: _submitting,
          outOfAttempts: _outOfAttempts,
          attemptsLeft: _grade?.attemptsLeft ?? challenge.attemptsLeft,
          onSubmit: _submit,
          onFinish: () => context.pop(),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final DailyChallenge challenge;
  final bool solved;

  const _Header({required this.challenge, required this.solved});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                solved ? Icons.check_circle_rounded : Icons.bolt_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                solved ? 'Concluído hoje' : 'Novo desafio',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _Reward(icon: Icons.bolt_rounded, value: '+${challenge.xpReward}'),
              const SizedBox(width: 8),
              _Reward(
                icon: Icons.monetization_on_rounded,
                value: '+${challenge.coinReward}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.title,
            style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.06);
  }
}

class _Reward extends StatelessWidget {
  final IconData icon;
  final String value;

  const _Reward({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  final String statement;

  const _StatementCard({required this.statement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        statement,
        style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final ChallengeGrade grade;

  const _FeedbackCard({required this.grade});

  @override
  Widget build(BuildContext context) {
    final color = grade.passed ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                grade.passed
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                grade.passed ? 'Resolvido!' : 'Ainda não',
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (grade.errorLine != null) ...[
                const Spacer(),
                Text(
                  'linha ${grade.errorLine}',
                  style: AppTextStyles.bodySmall.copyWith(color: color),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(grade.feedback, style: AppTextStyles.bodyMedium),
          if (grade.passed && grade.xpEarned > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+${grade.xpEarned} XP · +${grade.coinsEarned} moedas',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    ).animate().fade().slideY(begin: 0.08);
  }
}

class _BottomBar extends StatelessWidget {
  final bool solved;
  final bool submitting;
  final bool outOfAttempts;
  final int attemptsLeft;
  final VoidCallback onSubmit;
  final VoidCallback onFinish;

  const _BottomBar({
    required this.solved,
    required this.submitting,
    required this.outOfAttempts,
    required this.attemptsLeft,
    required this.onSubmit,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!solved && !outOfAttempts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                submitting
                    ? 'A IA está lendo seu código...'
                    : '$attemptsLeft ${attemptsLeft == 1 ? 'tentativa restante' : 'tentativas restantes'} hoje · errar não custa vida',
                style: AppTextStyles.bodySmall,
              ),
            ),
          BuggoButton(
            label: solved
                ? 'Voltar'
                : outOfAttempts
                    ? 'Tentativas esgotadas'
                    : 'Enviar para correção',
            icon: solved ? Icons.check_rounded : Icons.send_rounded,
            onPressed: submitting
                ? null
                : solved
                    ? onFinish
                    : outOfAttempts
                        ? null
                        : onSubmit,
            isLoading: submitting,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MascotWidget(
            mood: MascotMood.thinking,
            speechBubble: 'Preparando seu desafio...',
            size: 120,
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'A IA está montando um desafio com base no que você já estudou. Isso leva alguns segundos.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MascotWidget(
              mood: MascotMood.sad,
              speechBubble: 'Deu ruim aqui...',
              size: 110,
            ),
            const SizedBox(height: 20),
            Text(
              message ?? 'Não foi possível carregar o desafio de hoje.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            BuggoButton(label: 'Tentar de novo', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
