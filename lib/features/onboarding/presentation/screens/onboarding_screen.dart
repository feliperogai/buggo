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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _name = '';
  String _language = 'python';
  String _userLevel = 'adult';
  int _dailyGoal = 15;

  final _nameController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu nome para continuar!')),
      );
      return;
    }
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    final profile = UserProfile(
      name: _name,
      language: _language,
      level: _userLevel,
      dailyGoalMinutes: _dailyGoal,
    );
    ref.read(userProvider.notifier).saveProfile(profile);
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _NamePage(
                      controller: _nameController,
                      onChanged: (v) => setState(() => _name = v),
                    ),
                    _LanguagePage(
                      selected: _language,
                      onSelect: (v) => setState(() => _language = v),
                    ),
                    _LevelPage(
                      selected: _userLevel,
                      onSelect: (v) => setState(() => _userLevel = v),
                    ),
                    _GoalPage(
                      selected: _dailyGoal,
                      onSelect: (v) => setState(() => _dailyGoal = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: BuggoButton(
                  label: _currentPage == 3 ? 'Começar!' : 'Próximo',
                  onPressed: _nextPage,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NamePage({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MascotWidget(
            mood: MascotMood.happy,
            speechBubble: 'Olá! Eu sou o Buggo! 👋',
          ),
          const SizedBox(height: 32),
          Text('Como posso te chamar?', style: AppTextStyles.headlineLarge)
              .animate()
              .slideY(begin: 0.3, duration: 400.ms)
              .fade(),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Seu nome aqui...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    final options = [
      {'id': 'python', 'label': 'Python', 'emoji': '🐍', 'available': true},
      {
        'id': 'javascript',
        'label': 'JavaScript',
        'emoji': '⚡',
        'available': false
      },
      {'id': 'java', 'label': 'Java', 'emoji': '☕', 'available': false},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Qual linguagem\ndeseja aprender?',
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center)
              .animate()
              .slideY(begin: 0.3, duration: 400.ms)
              .fade(),
          const SizedBox(height: 32),
          ...options.asMap().entries.map((e) {
            final opt = e.value;
            final isSelected = selected == opt['id'];
            final available = opt['available'] as bool;
            return _OptionCard(
              emoji: opt['emoji'] as String,
              label: opt['label'] as String,
              isSelected: isSelected,
              isDisabled: !available,
              badge: !available ? 'Em breve' : null,
              onTap: available ? () => onSelect(opt['id'] as String) : null,
            ).animate(delay: (e.key * 100).ms).slideX(begin: 0.3).fade();
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
    final options = [
      {'id': 'beginner', 'label': 'Nunca programei', 'emoji': '🌱'},
      {'id': 'some', 'label': 'Sei um pouco', 'emoji': '📚'},
      {'id': 'intermediate', 'label': 'Já programo', 'emoji': '💻'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Qual seu nível\natual?',
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center)
              .animate()
              .slideY(begin: 0.3, duration: 400.ms)
              .fade(),
          const SizedBox(height: 32),
          ...options.asMap().entries.map((e) {
            final opt = e.value;
            return _OptionCard(
              emoji: opt['emoji']!,
              label: opt['label']!,
              isSelected: selected == opt['id'],
              onTap: () => onSelect(opt['id']!),
            ).animate(delay: (e.key * 100).ms).slideX(begin: 0.3).fade();
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
    final options = [
      {'minutes': 5, 'label': '5 minutos', 'emoji': '⚡', 'sub': 'Casual'},
      {'minutes': 15, 'label': '15 minutos', 'emoji': '🎯', 'sub': 'Regular'},
      {'minutes': 30, 'label': '30 minutos', 'emoji': '🔥', 'sub': 'Intenso'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Quanto tempo\npor dia?',
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center)
              .animate()
              .slideY(begin: 0.3, duration: 400.ms)
              .fade(),
          const SizedBox(height: 32),
          ...options.asMap().entries.map((e) {
            final opt = e.value;
            return _OptionCard(
              emoji: opt['emoji'] as String,
              label: opt['label'] as String,
              subtitle: opt['sub'] as String,
              isSelected: selected == opt['minutes'],
              onTap: () => onSelect(opt['minutes'] as int),
            ).animate(delay: (e.key * 100).ms).slideX(begin: 0.3).fade();
          }),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String? subtitle;
  final String? badge;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.emoji,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge!, style: AppTextStyles.bodySmall),
                ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
