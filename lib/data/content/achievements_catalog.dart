import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user_profile.dart';
import 'python_curriculum.dart';

typedef AchievementCheck = bool Function(
  UserProfile user,
  int completedLessons,
  int totalLessons,
);

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementCheck isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}

bool _firstLesson(UserProfile u, int completed, int total) => completed >= 1;
bool _fiveLessons(UserProfile u, int completed, int total) => completed >= 5;
bool _tenLessons(UserProfile u, int completed, int total) => completed >= 10;
bool _twentyFiveLessons(UserProfile u, int completed, int total) =>
    completed >= 25;
bool _allLessons(UserProfile u, int completed, int total) =>
    total > 0 && completed >= total;
bool _logicFoundations(UserProfile u, int completed, int total) =>
    hasCompletedLogicFoundations(u.completedLessons);
bool _pythonEssentials(UserProfile u, int completed, int total) =>
    pythonCurriculum[logicFoundationLevelCount]
        .lessons
        .every((l) => u.completedLessons.contains(l.id));
bool _streak3(UserProfile u, int completed, int total) => u.streak >= 3;
bool _streak7(UserProfile u, int completed, int total) => u.streak >= 7;
bool _streakFreeze(UserProfile u, int completed, int total) =>
    u.streakFreezes >= 1;
bool _coins50(UserProfile u, int completed, int total) => u.coins >= 50;
bool _coins200(UserProfile u, int completed, int total) => u.coins >= 200;
bool _level2(UserProfile u, int completed, int total) => u.currentLevel >= 2;
bool _level5(UserProfile u, int completed, int total) => u.currentLevel >= 5;
bool _customAvatar(UserProfile u, int completed, int total) =>
    u.avatarIndex != 0 || u.customPhotoPath != null;
bool _buggoPlus(UserProfile u, int completed, int total) =>
    u.hasUnlimitedLives;

/// All achievements in the game, in display order. Unlock state is computed
/// live from the user's profile (nothing is persisted per-achievement).
const achievementCatalog = <Achievement>[
  Achievement(
    id: 'first_lesson',
    title: 'Primeiro passo',
    description: 'Complete uma lição',
    icon: Icons.flag_rounded,
    color: AppColors.success,
    isUnlocked: _firstLesson,
  ),
  Achievement(
    id: 'five_lessons',
    title: 'Ritmo forte',
    description: 'Complete 5 lições',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.streakColor,
    isUnlocked: _fiveLessons,
  ),
  Achievement(
    id: 'ten_lessons',
    title: 'Maratona',
    description: 'Complete 10 lições',
    icon: Icons.directions_run_rounded,
    color: AppColors.levelBlue,
    isUnlocked: _tenLessons,
  ),
  Achievement(
    id: 'twenty_five_lessons',
    title: 'Imparável',
    description: 'Complete 25 lições',
    icon: Icons.rocket_launch_rounded,
    color: AppColors.levelPink,
    isUnlocked: _twentyFiveLessons,
  ),
  Achievement(
    id: 'all_lessons',
    title: 'Mestre do código',
    description: 'Complete todas as lições',
    icon: Icons.workspace_premium_rounded,
    color: AppColors.accent,
    isUnlocked: _allLessons,
  ),
  Achievement(
    id: 'logic_foundations',
    title: 'Lógica dominada',
    description: 'Conclua Fundamentos de Lógica',
    icon: Icons.psychology_rounded,
    color: AppColors.primary,
    isUnlocked: _logicFoundations,
  ),
  Achievement(
    id: 'python_essentials',
    title: 'Pythonista',
    description: 'Conclua o Python Essencial',
    icon: Icons.terminal_rounded,
    color: AppColors.primary,
    isUnlocked: _pythonEssentials,
  ),
  Achievement(
    id: 'streak_3',
    title: 'Consistente',
    description: 'Estude 3 dias seguidos',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.streakColor,
    isUnlocked: _streak3,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Semana cheia',
    description: 'Estude 7 dias seguidos',
    icon: Icons.whatshot_rounded,
    color: AppColors.error,
    isUnlocked: _streak7,
  ),
  Achievement(
    id: 'streak_freeze',
    title: 'Escudo ativado',
    description: 'Compre um congelamento de sequência',
    icon: Icons.ac_unit_rounded,
    color: AppColors.levelBlue,
    isUnlocked: _streakFreeze,
  ),
  Achievement(
    id: 'coins_50',
    title: 'Colecionador',
    description: 'Guarde 50 moedas',
    icon: Icons.monetization_on_rounded,
    color: AppColors.coinColor,
    isUnlocked: _coins50,
  ),
  Achievement(
    id: 'coins_200',
    title: 'Cofre cheio',
    description: 'Guarde 200 moedas',
    icon: Icons.savings_rounded,
    color: AppColors.coinColor,
    isUnlocked: _coins200,
  ),
  Achievement(
    id: 'level_2',
    title: 'Subindo de nível',
    description: 'Alcance o nível 2',
    icon: Icons.trending_up_rounded,
    color: AppColors.levelPink,
    isUnlocked: _level2,
  ),
  Achievement(
    id: 'level_5',
    title: 'Lenda em ascensão',
    description: 'Alcance o nível 5',
    icon: Icons.military_tech_rounded,
    color: AppColors.accent,
    isUnlocked: _level5,
  ),
  Achievement(
    id: 'custom_avatar',
    title: 'Visual novo',
    description: 'Personalize seu avatar',
    icon: Icons.face_retouching_natural_rounded,
    color: AppColors.levelPink,
    isUnlocked: _customAvatar,
  ),
  Achievement(
    id: 'buggo_plus',
    title: 'Vidas eternas',
    description: 'Ative o Buggo+',
    icon: Icons.all_inclusive_rounded,
    color: AppColors.error,
    isUnlocked: _buggoPlus,
  ),
];
