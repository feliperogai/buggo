import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/constants/learning_languages.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header com gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRouter.profile),
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
                    Text('Configurações',
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: Colors.white)),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),
                _SectionLabel('Conta'),
                _SettingsTile(
                  icon: Icons.person_rounded,
                  label: 'Nome',
                  value: user?.name ?? '',
                  color: AppColors.primary,
                ),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  label: 'Linguagem',
                  value: learningLanguageFor(user?.language ?? 'logic').label,
                  color: AppColors.success,
                ),
                _SettingsTile(
                  icon: Icons.timer_rounded,
                  label: 'Meta diária',
                  value: '${user?.dailyGoalMinutes ?? 15} min',
                  color: AppColors.levelBlue,
                ),
                if (user?.email != null) ...[
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.email_rounded,
                    label: 'E-mail',
                    value: user!.email!,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 10),
                  _LogoutButton(ref: ref),
                ] else ...[
                  // Guest: the profile lives only on this device, so there is
                  // nothing to sign out of — what's missing is a way in.
                  const SizedBox(height: 10),
                  _SignInTile(),
                ],
                const SizedBox(height: 24),
                _SectionLabel('Som e vibração'),
                _SwitchTile(
                  icon: Icons.volume_up_rounded,
                  label: 'Efeitos sonoros',
                  description: 'Sons de acerto, erro e recompensa',
                  color: AppColors.accent,
                  value: settings.soundEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setSoundEnabled(v),
                ),
                _SwitchTile(
                  icon: Icons.vibration_rounded,
                  label: 'Vibração',
                  description: 'Retorno tátil ao responder e tocar botões',
                  color: AppColors.streakColor,
                  value: settings.hapticsEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setHapticsEnabled(v),
                ),
                const SizedBox(height: 24),
                _SectionLabel('Lembretes'),
                _SwitchTile(
                  icon: Icons.notifications_active_rounded,
                  label: 'Lembrete de estudo',
                  description: 'Um empurrãozinho por dia para não perder a '
                      'sequência',
                  color: AppColors.primary,
                  value: settings.remindersEnabled,
                  onChanged: (v) => _toggleReminders(context, ref, v),
                ),
                if (settings.remindersEnabled)
                  _ReminderHourPicker(
                    selected: settings.reminderHour,
                    onSelected: (h) =>
                        ref.read(settingsProvider.notifier).setReminderHour(h),
                  ),
                const SizedBox(height: 24),
                _SectionLabel('Sobre'),
                _SettingsTile(
                  icon: Icons.info_rounded,
                  label: 'Versão',
                  value: '1.0.0',
                  color: AppColors.textMuted,
                ),
                _SettingsTile(
                  icon: Icons.bug_report_rounded,
                  label: 'Mascote',
                  value: 'Buggo',
                  color: AppColors.levelPink,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liga os lembretes, pedindo a permissão do sistema antes.
///
/// Recusar a permissão deixa o interruptor apagado de propósito: um botão
/// aceso que não notifica nada é pior do que um apagado.
Future<void> _toggleReminders(
  BuildContext context, WidgetRef ref, bool value) async {
  final ok = await ref.read(settingsProvider.notifier)
      .setRemindersEnabled(value);
  if (ok || !value || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        'O Android bloqueou as notificações do Buggo. Libere em Ajustes > '
        'Apps > Buggo > Notificações.',
      ),
    ),
  );
}

/// Escolha da hora do lembrete diário. Poucas opções de propósito: um seletor
/// de relógio completo pediria mais atenção do que a decisão merece.
class _ReminderHourPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _ReminderHourPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Horário', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 2),
          Text(
            'O aviso de sequência em risco chega às 21h, se faltar estudar.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hour in AppSettings.reminderHourOptions)
                GestureDetector(
                  onTap: () => onSelected(hour),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: hour == selected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: hour == selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textMuted, letterSpacing: 0)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: color,
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final WidgetRef ref;

  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await ref.read(userProvider.notifier).logout();
        if (context.mounted) context.go(AppRouter.onboarding);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Sair da conta', style: AppTextStyles.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entry point into login/signup for a guest already using the app. Without
/// it, `/login` was reachable only from onboarding — so a guest could never
/// sign in to save progress or appear in the ranking.
class _SignInTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRouter.login, extra: AuthMode.login),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.login_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entrar ou criar conta',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Salve seu progresso e apareça no ranking',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
