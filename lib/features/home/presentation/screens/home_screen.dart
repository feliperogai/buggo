import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../data/content/python_curriculum.dart';
import '../../../../shared/constants/learning_languages.dart';
import '../../../../shared/models/lesson.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/pixel_avatars.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRouter.onboarding);
      });
      return const SizedBox.shrink();
    }

    final hasCompletedFoundations =
        hasCompletedLogicFoundations(user.completedLessons);
    final selectedLanguage = hasCompletedFoundations ? user.language : 'logic';
    final currentLanguage = learningLanguageFor(selectedLanguage);
    final visibleLevels = _levelsForLanguage(currentLanguage.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header card com gradiente
          SliverToBoxAdapter(
            child: _HeaderCard(user: user),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trilha de aprendizado',
                                style: AppTextStyles.headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              '${currentLanguage.label} - continue de onde parou',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _LanguageSwitchButton(
                        language: currentLanguage,
                        onTap: () => _showLanguagePicker(
                          context,
                          ref,
                          selectedLanguage,
                          hasCompletedFoundations: hasCompletedFoundations,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = visibleLevels[index];
                final levelIndex = entry.index;
                final level = entry.level;
                final completed = level.lessons
                    .where((l) => user.completedLessons.contains(l.id))
                    .length;
                final isUnlocked = index == 0
                    ? currentLanguage.id == 'logic' || hasCompletedFoundations
                    : visibleLevels[index - 1].level.lessons.every(
                          (l) => user.completedLessons.contains(l.id),
                        );

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: _LevelCard(
                    levelIndex: levelIndex,
                    title: level.title,
                    description: level.description,
                    emoji: level.emoji,
                    totalLessons: level.lessons.length,
                    completedLessons: completed,
                    isUnlocked: isUnlocked,
                    onTap: isUnlocked
                        ? () =>
                            context.push(AppRouter.levelMap, extra: levelIndex)
                        : null,
                  ).animate(delay: (index * 80).ms).slideY(begin: 0.2).fade(),
                );
              },
              childCount: visibleLevels.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Header Card ────────────────────────────────────────────────
List<_LearningLevelEntry> _levelsForLanguage(String languageId) {
  return pythonCurriculum.asMap().entries.where((entry) {
    if (languageId == 'logic') {
      return entry.key < logicFoundationLevelCount;
    }

    if (languageId == 'python') {
      return entry.key >= logicFoundationLevelCount;
    }

    return false;
  }).map((entry) {
    return _LearningLevelEntry(index: entry.key, level: entry.value);
  }).toList(growable: false);
}

class _LearningLevelEntry {
  final int index;
  final CourseLevel level;

  const _LearningLevelEntry({
    required this.index,
    required this.level,
  });
}

void _showLanguagePicker(
  BuildContext context,
  WidgetRef ref,
  String selectedLanguage, {
  required bool hasCompletedFoundations,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _LanguagePickerSheet(
        selectedLanguage: selectedLanguage,
        hasCompletedFoundations: hasCompletedFoundations,
        onSelect: (language) {
          final statusLabel = learningLanguageStatusLabel(
            language,
            hasCompletedFoundations: hasCompletedFoundations,
          );

          if (statusLabel != null) {
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.textPrimary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: Text(
                  statusLabel == 'Bloqueado'
                      ? 'Conclua Fundamentos de Lógica para liberar ${language.label}.'
                      : '${language.label} chega em breve.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            );
            return;
          }

          ref.read(userProvider.notifier).updateLanguage(language.id);
          Navigator.of(sheetContext).pop();
        },
      );
    },
  );
}

class _LanguageSwitchButton extends StatelessWidget {
  final LearningLanguageOption language;
  final VoidCallback onTap;

  const _LanguageSwitchButton({
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Trocar linguagem',
      child: Semantics(
        button: true,
        label: 'Trocar linguagem',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: language.color.withValues(alpha: 0.24),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: language.color.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(language.icon, color: language.color, size: 20),
                const SizedBox(width: 7),
                Text(
                  language.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  final String selectedLanguage;
  final bool hasCompletedFoundations;
  final ValueChanged<LearningLanguageOption> onSelect;

  const _LanguagePickerSheet({
    required this.selectedLanguage,
    required this.hasCompletedFoundations,
    required this.onSelect,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String? _openModuleId = 'fundamentals';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Linguagem', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Escolha a trilha que você quer estudar.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 18),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final module in learningModules) ...[
                    _LanguageModuleHeader(
                      module: module,
                      isOpen: _openModuleId == module.id,
                      count: learningLanguagesForModule(module.id).length,
                      onTap: () {
                        setState(() {
                          _openModuleId =
                              _openModuleId == module.id ? null : module.id;
                        });
                      },
                    ),
                    _LanguageModuleOptions(
                      moduleId: module.id,
                      isOpen: _openModuleId == module.id,
                      selectedLanguage: widget.selectedLanguage,
                      hasCompletedFoundations: widget.hasCompletedFoundations,
                      onSelect: widget.onSelect,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageModuleHeader extends StatelessWidget {
  final LearningModule module;
  final bool isOpen;
  final int count;
  final VoidCallback onTap;

  const _LanguageModuleHeader({
    required this.module,
    required this.isOpen,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOpen
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOpen
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.cardBorder,
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(module.icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(module.label, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(module.description, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageModuleOptions extends StatelessWidget {
  final String moduleId;
  final bool isOpen;
  final String selectedLanguage;
  final bool hasCompletedFoundations;
  final ValueChanged<LearningLanguageOption> onSelect;

  const _LanguageModuleOptions({
    required this.moduleId,
    required this.isOpen,
    required this.selectedLanguage,
    required this.hasCompletedFoundations,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final languages = learningLanguagesForModule(moduleId);

    return AnimatedCrossFade(
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeOutCubic,
      sizeCurve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      crossFadeState:
          isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Column(
        children: [
          for (final entry in languages.asMap().entries) ...[
            Builder(
              builder: (context) {
                final statusLabel = learningLanguageStatusLabel(
                  entry.value,
                  hasCompletedFoundations: hasCompletedFoundations,
                );

                return _LanguageOptionTile(
                  language: entry.value,
                  isSelected: entry.value.id == selectedLanguage,
                  isUnlocked: statusLabel == null,
                  statusLabel: statusLabel,
                  onTap: () => onSelect(entry.value),
                )
                    .animate(delay: (entry.key * 35).ms)
                    .fade(duration: 180.ms, curve: Curves.easeOutCubic)
                    .slideY(
                      begin: -0.06,
                      end: 0,
                      duration: 200.ms,
                      curve: Curves.easeOutCubic,
                    );
              },
            ),
          ],
        ],
      ),
      secondChild: const SizedBox(width: double.infinity),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final LearningLanguageOption language;
  final bool isSelected;
  final bool isUnlocked;
  final String? statusLabel;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.language,
    required this.isSelected,
    required this.isUnlocked,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = language.color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.44)
                : AppColors.cardBorder,
            width: 1.4,
          ),
        ),
        child: Opacity(
          opacity: isUnlocked ? 1 : 0.58,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(language.icon, color: color, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.label, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      language.description,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (statusLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (statusLabel == 'Bloqueado'
                            ? AppColors.textMuted
                            : AppColors.accent)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusLabel == 'Bloqueado'
                          ? AppColors.textMuted
                          : AppColors.accent,
                    ),
                  ),
                )
              else if (isSelected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final dynamic user;
  const _HeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + avatar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${user.name}!',
                          style: AppTextStyles.headlineMedium
                              .copyWith(color: Colors.white),
                        ),
                        Text(
                          'Pronto para codar hoje?',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.profile),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: PixelAvatar(
                        avatarIndex: user.avatarIndex,
                        customPhotoPath: user.customPhotoPath,
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats chips
              Row(
                children: [
                  _StatPill(
                      iconData: Icons.local_fire_department_rounded,
                      value: '${user.streak}',
                      label: 'dias',
                      color: Colors.white),
                  const SizedBox(width: 8),
                  _StatPill(
                      iconData: Icons.monetization_on_rounded,
                      value: '${user.coins}',
                      label: 'moedas',
                      color: Colors.white),
                  const SizedBox(width: 8),
                  _StatPill(
                      iconData: Icons.bolt_rounded,
                      value: '${user.xp}',
                      label: 'XP',
                      color: Colors.white),
                ],
              ),

              const SizedBox(height: 20),

              // XP bar adaptada para tema escuro
              _WhiteXpBar(
                  xp: user.xp,
                  progress: user.xpProgress,
                  level: user.currentLevel),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData iconData;
  final String value;
  final String label;
  final Color color;

  const _StatPill(
      {required this.iconData,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _WhiteXpBar extends StatelessWidget {
  final int xp;
  final double progress;
  final int level;

  const _WhiteXpBar(
      {required this.xp, required this.progress, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Center(
            child: Text('$level',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nível $level',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8))),
                  Text('$xp XP',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Stack(
                  children: [
                    Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(100),
                        )),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Level Card ─────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final int levelIndex;
  final String title;
  final String description;
  final String emoji;
  final int totalLessons;
  final int completedLessons;
  final bool isUnlocked;
  final VoidCallback? onTap;

  static const _levelColors = [
    AppColors.levelBlue,
    AppColors.levelGreen,
    AppColors.levelPink,
  ];

  static const _levelIcons = [
    Icons.lightbulb_rounded,
    Icons.terminal_rounded,
    Icons.rocket_launch_rounded,
  ];

  const _LevelCard({
    required this.levelIndex,
    required this.title,
    required this.description,
    required this.emoji,
    required this.totalLessons,
    required this.completedLessons,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;
    final isCompleted = completedLessons == totalLessons && totalLessons > 0;
    final levelColor = _levelColors[levelIndex % _levelColors.length];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.4)
                  : isUnlocked
                      ? levelColor.withValues(alpha: 0.25)
                      : AppColors.cardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : isUnlocked
                        ? levelColor.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Level icon badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? levelColor.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    isUnlocked
                        ? _levelIcons[levelIndex % _levelIcons.length]
                        : Icons.lock_rounded,
                    color: isUnlocked ? levelColor : AppColors.textMuted,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headlineSmall),
                    Text(description, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.cardBorder,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.success
                                    : levelColor,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedLessons/$totalLessons lições',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCompleted)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                )
              else if (isUnlocked)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: levelColor, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
