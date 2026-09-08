import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/lesson.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/buggo_button.dart';
import '../../data/daily_challenge.dart';
import '../../data/daily_challenge_repository.dart';
import '../../data/daily_providers.dart';

/// Tela do desafio do dia.
///
/// Diferente das lições da trilha, aqui **o app não sabe a resposta**. Ele
/// manda a alternativa escolhida e o servidor devolve se acertou e quantas
/// moedas caíram. É o que impede um APK modificado de se dar o prêmio.
class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  int? _selected;
  bool _sending = false;
  DailyChallengeResult? _result;
  String? _error;

  final _codeController = TextEditingController();
  bool _codeSeeded = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Preenche o editor com o começo que veio do servidor, uma vez só — se
  /// refizesse a cada build, apagaria o que a pessoa está digitando.
  void _seedCode(DailyChallenge challenge) {
    if (_codeSeeded) return;
    _codeSeeded = true;
    final starter = challenge.lesson.starterCode;
    if (starter != null && starter.isNotEmpty) _codeController.text = starter;
  }

  Future<void> _submit(DailyChallenge challenge) async {
    final isCode = challenge.lesson.type == LessonType.codeWrite;
    final code = _codeController.text.trim();
    if (_sending) return;
    if (isCode ? code.isEmpty : _selected == null) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final (result, profile) =
          await ref.read(dailyChallengeRepositoryProvider).submit(
                challengeId: challenge.id,
                optionIndex: isCode ? null : _selected,
                code: isCode ? code : null,
              );

      if (profile != null) {
        ref.read(userProvider.notifier).saveProfile(profile);
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _sending = false;
      });
      SoundService.instance.play(result.correct ? Sfx.correct : Sfx.wrong);
      SoundService.instance.haptic(
        result.correct ? Haptic.medium : Haptic.light,
      );
    } on DailyChallengeFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dailyChallengeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('Desafio do dia', style: AppTextStyles.headlineSmall),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _Empty(
          message: 'Não foi possível carregar o desafio de hoje.',
        ),
        data: (challenge) {
          if (challenge == null) {
            return const _Empty(
              message: 'Nenhum desafio hoje. Volte amanhã.',
            );
          }
          _seedCode(challenge);
          return _Body(
            challenge: challenge,
            codeController: _codeController,
            selected: _selected,
            sending: _sending,
            result: _result,
            error: _error,
            onSelect: (index) => setState(() => _selected = index),
            onSubmit: () => _submit(challenge),
            onClose: () => context.pop(),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DailyChallenge challenge;
  final TextEditingController codeController;
  final int? selected;
  final bool sending;
  final DailyChallengeResult? result;
  final String? error;
  final ValueChanged<int> onSelect;
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  const _Body({
    required this.challenge,
    required this.codeController,
    required this.selected,
    required this.sending,
    required this.result,
    required this.error,
    required this.onSelect,
    required this.onSubmit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final lesson = challenge.lesson;
    final answered = result != null;
    final isCode = lesson.type == LessonType.codeWrite;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _RewardBanner(
          coins: challenge.rewardCoins,
          alreadyClaimed: challenge.alreadyClaimed,
        ),
        const SizedBox(height: 20),
        Text(lesson.title, style: AppTextStyles.headlineMedium),
        if (lesson.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(lesson.description, style: AppTextStyles.bodyMedium),
        ],
        const SizedBox(height: 20),
        if (lesson.question != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Text(lesson.question!, style: AppTextStyles.bodyLarge),
          ),
        const SizedBox(height: 16),
        if (isCode)
          _CodeEditor(
            controller: codeController,
            language: lesson.codeLanguage ?? '',
            enabled: !answered && !sending,
          )
        else
          for (final entry in lesson.options.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                text: entry.value.text,
                isSelected: selected == entry.key,
                enabled: !answered && !sending,
                onTap: () => onSelect(entry.key),
              ),
            ),
        if (lesson.hint != null && !answered) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(lesson.hint!, style: AppTextStyles.bodySmall),
              ),
            ],
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
        ],
        const SizedBox(height: 20),
        if (answered)
          _ResultCard(result: result!, onClose: onClose)
        else
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: codeController,
            builder: (context, value, _) {
              final ready = isCode
                  ? value.text.trim().isNotEmpty
                  : selected != null;
              return BuggoButton(
                label: isCode ? 'Enviar código' : 'Responder',
                isLoading: sending,
                onPressed: ready ? onSubmit : null,
              );
            },
          ),
        if (isCode && sending) ...[
          const SizedBox(height: 10),
          Text(
            'Corrigindo seu código…',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _RewardBanner extends StatelessWidget {
  final int coins;
  final bool alreadyClaimed;

  const _RewardBanner({required this.coins, required this.alreadyClaimed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alreadyClaimed
                  ? 'Você já resgatou o prêmio de hoje'
                  : 'Acerte e ganhe $coins moedas',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor simples: fonte monoespaçada, fundo escuro, altura generosa.
/// Nada de destaque de sintaxe — seriam 16 gramáticas para manter, e o ganho
/// num campo de poucas linhas no celular é pequeno.
class _CodeEditor extends StatelessWidget {
  final TextEditingController controller;
  final String language;
  final bool enabled;

  const _CodeEditor({
    required this.controller,
    required this.language,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1720),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2434)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.code_rounded,
                    size: 15, color: Color(0xFF8A8398)),
                const SizedBox(width: 6),
                Text(
                  language.isEmpty ? 'Seu código' : language,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF8A8398)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLines: null,
              minLines: 6,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.5,
                color: Color(0xFFF5F3FA),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Escreva aqui…',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Color(0xFF6B6480),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(text, style: AppTextStyles.bodyLarge),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final DailyChallengeResult result;
  final VoidCallback onClose;

  const _ResultCard({required this.result, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final correct = result.correct;
    final color = correct ? AppColors.success : AppColors.error;

    // Nos desafios de escrever código a IA corretora manda uma frase dizendo
    // o que faltou; ela é mais útil que qualquer texto fixo.
    final String message;
    if (!correct) {
      message = result.feedback ?? 'Não foi dessa vez. Amanhã tem outro.';
    } else if (result.coinsGranted > 0) {
      message = 'Acertou! +${result.coinsGranted} moedas.';
    } else {
      message = 'Acertou! O prêmio de hoje já tinha sido resgatado.';
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: AppTextStyles.bodyLarge.copyWith(color: color)),
              ),
            ],
          ),
        ).animate().fade(duration: 200.ms).slideY(begin: 0.15),
        const SizedBox(height: 16),
        BuggoButton(label: 'Voltar', onPressed: onClose),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}
