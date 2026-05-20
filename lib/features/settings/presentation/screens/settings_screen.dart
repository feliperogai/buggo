import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../shared/constants/learning_languages.dart';
import '../../../../shared/providers/user_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

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
                _DangerZone(ref: ref),
                const SizedBox(height: 16),
              ],
            ),
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

class _DangerZone extends StatelessWidget {
  final WidgetRef ref;

  const _DangerZone({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Text('Zona de perigo',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ações irreversíveis que afetam seu progresso',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _confirm(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restart_alt, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text('Resetar progresso',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.error)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resetar tudo?',
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: AppColors.error)),
              const SizedBox(height: 8),
              Text(
                'Isso apagará todo o seu progresso.\nTem certeza?',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Cancelar',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await HiveStorage.user.clear();
                        await HiveStorage.progress.clear();
                        ref.invalidate(userProvider);
                        if (ctx.mounted) ctx.go(AppRouter.onboarding);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Resetar',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
