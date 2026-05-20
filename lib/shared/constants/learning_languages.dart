import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LearningLanguageOption {
  final String id;
  final String label;
  final String description;
  final String moduleId;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final bool requiresFoundations;

  const LearningLanguageOption({
    required this.id,
    required this.label,
    required this.description,
    required this.moduleId,
    required this.icon,
    required this.color,
    required this.isAvailable,
    this.requiresFoundations = true,
  });
}

class LearningModule {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const LearningModule({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const learningModules = [
  LearningModule(
    id: 'fundamentals',
    label: 'Fundamentos',
    description: 'Comece por jogos de lógica e raciocínio',
    icon: Icons.school_rounded,
  ),
  LearningModule(
    id: 'frontend',
    label: 'Frontend',
    description: 'Interfaces, web e experiência do usuário',
    icon: Icons.web_rounded,
  ),
  LearningModule(
    id: 'backend',
    label: 'Backend',
    description: 'APIs, servidores e regras de negócio',
    icon: Icons.dns_rounded,
  ),
  LearningModule(
    id: 'mobile',
    label: 'Mobile',
    description: 'Apps para Android, iOS e multiplataforma',
    icon: Icons.smartphone_rounded,
  ),
  LearningModule(
    id: 'database',
    label: 'Banco de dados',
    description: 'Consultas, filtros e dados persistentes',
    icon: Icons.storage_rounded,
  ),
  LearningModule(
    id: 'systems',
    label: 'Sistemas',
    description: 'Performance, memória e baixo nível',
    icon: Icons.memory_rounded,
  ),
];

const learningLanguageOptions = [
  LearningLanguageOption(
    id: 'logic',
    label: 'Lógica',
    description: 'Jogos, enigmas, padrões e estratégia',
    moduleId: 'fundamentals',
    icon: Icons.psychology_rounded,
    color: AppColors.primary,
    isAvailable: true,
    requiresFoundations: false,
  ),
  LearningLanguageOption(
    id: 'python',
    label: 'Python',
    description: 'Sintaxe, funções, automações e backend',
    moduleId: 'backend',
    icon: Icons.terminal_rounded,
    color: AppColors.primary,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'javascript',
    label: 'JavaScript',
    description: 'Web, interfaces e interatividade',
    moduleId: 'frontend',
    icon: Icons.code_rounded,
    color: AppColors.levelBlue,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'typescript',
    label: 'TypeScript',
    description: 'JavaScript com tipagem para projetos maiores',
    moduleId: 'frontend',
    icon: Icons.integration_instructions_rounded,
    color: AppColors.levelBlue,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'java',
    label: 'Java',
    description: 'Apps, backend e orientação a objetos',
    moduleId: 'backend',
    icon: Icons.coffee_rounded,
    color: AppColors.accent,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'csharp',
    label: 'C#',
    description: 'Games, apps e backend com .NET',
    moduleId: 'backend',
    icon: Icons.widgets_rounded,
    color: AppColors.primaryLight,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'cpp',
    label: 'C++',
    description: 'Performance, sistemas e jogos',
    moduleId: 'systems',
    icon: Icons.memory_rounded,
    color: AppColors.levelBlue,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'c',
    label: 'C',
    description: 'Base de sistemas, memória e baixo nível',
    moduleId: 'systems',
    icon: Icons.developer_board_rounded,
    color: AppColors.textSecondary,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'go',
    label: 'Go',
    description: 'APIs rápidas, cloud e serviços',
    moduleId: 'backend',
    icon: Icons.bolt_rounded,
    color: AppColors.success,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'kotlin',
    label: 'Kotlin',
    description: 'Android moderno e apps mobile',
    moduleId: 'mobile',
    icon: Icons.phone_android_rounded,
    color: AppColors.levelPink,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'swift',
    label: 'Swift',
    description: 'Apps para iPhone, iPad e Apple Watch',
    moduleId: 'mobile',
    icon: Icons.phone_iphone_rounded,
    color: AppColors.error,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'php',
    label: 'PHP',
    description: 'Sites, APIs e sistemas web',
    moduleId: 'backend',
    icon: Icons.public_rounded,
    color: AppColors.levelBlue,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'ruby',
    label: 'Ruby',
    description: 'Web produtiva e código elegante',
    moduleId: 'backend',
    icon: Icons.diamond_rounded,
    color: AppColors.error,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'rust',
    label: 'Rust',
    description: 'Performance com segurança de memória',
    moduleId: 'systems',
    icon: Icons.shield_rounded,
    color: AppColors.accent,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'dart',
    label: 'Dart',
    description: 'Flutter, apps mobile e interfaces',
    moduleId: 'mobile',
    icon: Icons.flutter_dash_rounded,
    color: AppColors.levelBlue,
    isAvailable: false,
  ),
  LearningLanguageOption(
    id: 'queries',
    label: 'Queries',
    description: 'SQL, filtros e consultas em bancos de dados',
    moduleId: 'database',
    icon: Icons.storage_rounded,
    color: AppColors.textPrimary,
    isAvailable: false,
  ),
];

LearningLanguageOption learningLanguageFor(String id) {
  return learningLanguageOptions.firstWhere(
    (language) => language.id == id,
    orElse: () => learningLanguageOptions.first,
  );
}

bool isLearningLanguageUnlocked(
  LearningLanguageOption language, {
  required bool hasCompletedFoundations,
}) {
  if (!language.isAvailable) return false;
  if (!language.requiresFoundations) return true;
  return hasCompletedFoundations;
}

String? learningLanguageStatusLabel(
  LearningLanguageOption language, {
  required bool hasCompletedFoundations,
}) {
  if (!language.isAvailable) return 'Em breve';
  if (language.requiresFoundations && !hasCompletedFoundations) {
    return 'Bloqueado';
  }
  return null;
}

List<LearningLanguageOption> learningLanguagesForModule(String moduleId) {
  return learningLanguageOptions
      .where((language) => language.moduleId == moduleId)
      .toList(growable: false);
}
