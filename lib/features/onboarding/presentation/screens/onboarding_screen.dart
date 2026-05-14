import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/buggo_button.dart';
import '../../../../shared/widgets/mascot_widget.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  String _name = '';
  String _language = 'python';
  String _userLevel = 'beginner';
  int _dailyGoal = 15;

  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0 && _name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Digite seu nome!',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          ]),
        ),
      );
      return;
    }
    if (_page < 3) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(userProvider.notifier).saveProfile(
          UserProfile(
            name: _name.trim(),
            language: _language,
            level: _userLevel,
            dailyGoalMinutes: _dailyGoal,
          ),
        );
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar moderna
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(4, (i) {
                  final active = i <= _page;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.primaryGradient : null,
                        color: active ? null : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _NamePage(ctrl: _nameCtrl, onChanged: (v) => setState(() => _name = v)),
                  _LanguagePage(selected: _language, onSelect: (v) => setState(() => _language = v)),
                  _LevelPage(selected: _userLevel, onSelect: (v) => setState(() => _userLevel = v)),
                  _GoalPage(selected: _dailyGoal, onSelect: (v) => setState(() => _dailyGoal = v)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: BuggoButton(
                label: _page == 3 ? 'Começar!' : 'Próximo',
                icon: _page == 3 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                onPressed: _next,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pages ──────────────────────────────────────────────────────
class _NamePage extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  const _NamePage({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const MascotWidget(
            mood: MascotMood.happy,
            speechBubble: 'Olá! Eu sou o Buggo!',
          ).animate().scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.elasticOut).fade(),
          const SizedBox(height: 32),
          Text(
            'Como posso\nte chamar?',
            style: AppTextStyles.headlineLarge,
            textAlign: TextAlign.center,
          ).animate().slideY(begin: 0.3, duration: 400.ms).fade(),
          const SizedBox(height: 8),
          Text(
            'Vou usar seu nome para personalizar sua experiência',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ).animate(delay: 100.ms).fade(),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Seu nome aqui...',
                hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ).animate(delay: 200.ms).slideY(begin: 0.3, duration: 400.ms).fade(),
        ],
      ),
    );
  }
}

class _LanguagePage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _LanguagePage({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = [
      {'id': 'python',     'label': 'Python',     'icon': Icons.terminal_rounded,    'sub': 'Iniciante friendly', 'ok': true},
      {'id': 'javascript', 'label': 'JavaScript', 'icon': Icons.code_rounded,         'sub': 'Web & apps',         'ok': false},
      {'id': 'java',       'label': 'Java',       'icon': Icons.coffee_rounded,       'sub': 'Robusto e escalável','ok': false},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text('Qual linguagem\ndeseja aprender?',
              style: AppTextStyles.headlineLarge, textAlign: TextAlign.center)
              .animate().slideY(begin: 0.3, duration: 400.ms).fade(),
          const SizedBox(height: 8),
          Text('Você pode mudar isso depois', style: AppTextStyles.bodyMedium)
              .animate(delay: 100.ms).fade(),
          const SizedBox(height: 32),
          ...opts.asMap().entries.map((e) {
            final opt = e.value;
            final ok = opt['ok'] as bool;
            return _OptionCard(
              icon: opt['icon'] as IconData,
              label: opt['label'] as String,
              subtitle: opt['sub'] as String,
              badge: ok ? null : 'Em breve',
              isSelected: selected == opt['id'],
              isDisabled: !ok,
              onTap: ok ? () => onSelect(opt['id'] as String) : null,
            ).animate(delay: (e.key * 80).ms).slideX(begin: 0.3).fade();
          }),
        ],
      ),
    );
  }
}

class _LevelPage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _LevelPage({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = [
      {'id': 'beginner',     'label': 'Nunca programei', 'icon': Icons.eco_rounded,      'sub': 'Do zero ao básico'},
      {'id': 'some',         'label': 'Sei um pouco',    'icon': Icons.auto_stories_rounded, 'sub': 'Reforçar o básico'},
      {'id': 'intermediate', 'label': 'Já programo',     'icon': Icons.laptop_rounded,   'sub': 'Ir além'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text('Qual seu\nnível atual?',
              style: AppTextStyles.headlineLarge, textAlign: TextAlign.center)
              .animate().slideY(begin: 0.3, duration: 400.ms).fade(),
          const SizedBox(height: 8),
          Text('Personalizamos seu caminho de aprendizado', style: AppTextStyles.bodyMedium)
              .animate(delay: 100.ms).fade(),
          const SizedBox(height: 32),
          ...opts.asMap().entries.map((e) {
            final opt = e.value;
            return _OptionCard(
              icon: opt['icon'] as IconData,
              label: opt['label'] as String,
              subtitle: opt['sub'] as String,
              isSelected: selected == opt['id'],
              onTap: () => onSelect(opt['id'] as String),
            ).animate(delay: (e.key * 80).ms).slideX(begin: 0.3).fade();
          }),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _GoalPage({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = [
      {'min': 5,  'label': '5 minutos',  'icon': Icons.bolt_rounded,                   'sub': 'Ritmo casual'},
      {'min': 15, 'label': '15 minutos', 'icon': Icons.track_changes_rounded,           'sub': 'Ritmo regular'},
      {'min': 30, 'label': '30 minutos', 'icon': Icons.local_fire_department_rounded,   'sub': 'Ritmo intenso'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text('Quanto tempo\npor dia?',
              style: AppTextStyles.headlineLarge, textAlign: TextAlign.center)
              .animate().slideY(begin: 0.3, duration: 400.ms).fade(),
          const SizedBox(height: 8),
          Text('Consistência é mais importante que tempo', style: AppTextStyles.bodyMedium)
              .animate(delay: 100.ms).fade(),
          const SizedBox(height: 32),
          ...opts.asMap().entries.map((e) {
            final opt = e.value;
            return _OptionCard(
              icon: opt['icon'] as IconData,
              label: opt['label'] as String,
              subtitle: opt['sub'] as String,
              isSelected: selected == opt['min'],
              onTap: () => onSelect(opt['min'] as int),
            ).animate(delay: (e.key * 80).ms).slideX(begin: 0.3).fade();
          }),
        ],
      ),
    );
  }
}

// ── Option Card ────────────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.45 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodyLarge),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge!,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent)),
                ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
