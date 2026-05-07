import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../shared/providers/user_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                    const Spacer(),
                    Text('Configurações', style: AppTextStyles.headlineSmall),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _SectionLabel(label: 'Conta'),
                    _SettingsTile(
                      icon: Icons.person_rounded,
                      label: 'Nome',
                      value: user?.name ?? '',
                      iconColor: AppColors.primary,
                    ),
                    _SettingsTile(
                      icon: Icons.code_rounded,
                      label: 'Linguagem',
                      value: user?.language == 'python' ? 'Python 🐍' : 'Python 🐍',
                      iconColor: AppColors.neonGreen,
                    ),
                    _SettingsTile(
                      icon: Icons.access_time_rounded,
                      label: 'Meta diária',
                      value: '${user?.dailyGoalMinutes ?? 15} minutos',
                      iconColor: AppColors.neonBlue,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Sobre'),
                    _SettingsTile(
                      icon: Icons.info_rounded,
                      label: 'Versão',
                      value: '1.0.0',
                      iconColor: AppColors.textMuted,
                    ),
                    _SettingsTile(
                      icon: Icons.bug_report_rounded,
                      label: 'Mascote',
                      value: 'Buggo 🐛',
                      iconColor: AppColors.neonPink,
                    ),
                    const SizedBox(height: 32),
                    _DangerZone(ref: ref, context: context),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          letterSpacing: 1.5,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label, style: AppTextStyles.bodyLarge)),
            Text(value, style: AppTextStyles.bodyMedium),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  final WidgetRef ref;
  final BuildContext context;

  const _DangerZone({required this.ref, required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zona de Perigo',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _confirmReset(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restart_alt,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Text('Resetar progresso',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.error)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title:
            Text('Resetar tudo?', style: AppTextStyles.headlineSmall),
        content: Text(
          'Isso apagará todo o seu progresso. Tem certeza?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(_).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(_).pop();
              await HiveStorage.user.clear();
              await HiveStorage.progress.clear();
              ref.invalidate(userProvider);
              if (ctx.mounted) ctx.go(AppRouter.onboarding);
            },
            child: const Text('Resetar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
