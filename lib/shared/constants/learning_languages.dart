import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LearningLanguageOption {
  final String id;
  final String label;
  final String description;
  final String moduleId;
  final IconData icon;
  final Color color;

  /// Se a linguagem tem trilha publicada. Continua existindo para uma opção
  /// nova entrar na lista antes do conteúdo — `curriculum_test` garante que
  /// toda opção marcada como disponível tem níveis de verdade.
  final bool isAvailable;

  const LearningLanguageOption({
    required this.id,
    required this.label,
    required this.description,
    required this.moduleId,
    required this.icon,
    required this.color,
    required this.isAvailable,
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
    description: 'Jogos de lógica e raciocínio — opcional, bom para começar',
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
    description: 'Jogos, enigmas e padrões. Recomendado para quem nunca programou',
    moduleId: 'fundamentals',
    icon: Icons.psychology_rounded,
    color: AppColors.primary,
    isAvailable: true,
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
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'typescript',
    label: 'TypeScript',
    description: 'JavaScript com tipagem para projetos maiores',
    moduleId: 'frontend',
    icon: Icons.integration_instructions_rounded,
    color: AppColors.levelBlue,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'java',
    label: 'Java',
    description: 'Apps, backend e orientação a objetos',
    moduleId: 'backend',
    icon: Icons.coffee_rounded,
    color: AppColors.accent,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'csharp',
    label: 'C#',
    description: 'Games, apps e backend com .NET',
    moduleId: 'backend',
    icon: Icons.widgets_rounded,
    color: AppColors.primaryLight,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'cpp',
    label: 'C++',
    description: 'Performance, sistemas e jogos',
    moduleId: 'systems',
    icon: Icons.memory_rounded,
    color: AppColors.levelBlue,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'c',
    label: 'C',
    description: 'Base de sistemas, memória e baixo nível',
    moduleId: 'systems',
    icon: Icons.developer_board_rounded,
    color: AppColors.textSecondary,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'go',
    label: 'Go',
    description: 'APIs rápidas, cloud e serviços',
    moduleId: 'backend',
    icon: Icons.bolt_rounded,
    color: AppColors.success,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'kotlin',
    label: 'Kotlin',
    description: 'Android moderno e apps mobile',
    moduleId: 'mobile',
    icon: Icons.phone_android_rounded,
    color: AppColors.levelPink,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'swift',
    label: 'Swift',
    description: 'Apps para iPhone, iPad e Apple Watch',
    moduleId: 'mobile',
    icon: Icons.phone_iphone_rounded,
    color: AppColors.error,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'php',
    label: 'PHP',
    description: 'Sites, APIs e sistemas web',
    moduleId: 'backend',
    icon: Icons.public_rounded,
    color: AppColors.levelBlue,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'ruby',
    label: 'Ruby',
    description: 'Web produtiva e código elegante',
    moduleId: 'backend',
    icon: Icons.diamond_rounded,
    color: AppColors.error,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'rust',
    label: 'Rust',
    description: 'Performance com segurança de memória',
    moduleId: 'systems',
    icon: Icons.shield_rounded,
    color: AppColors.accent,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'dart',
    label: 'Dart',
    description: 'Flutter, apps mobile e interfaces',
    moduleId: 'mobile',
    icon: Icons.flutter_dash_rounded,
    color: AppColors.levelBlue,
    isAvailable: true,
  ),
  LearningLanguageOption(
    id: 'queries',
    label: 'Queries',
    description: 'SQL, filtros e consultas em bancos de dados',
    moduleId: 'database',
    icon: Icons.storage_rounded,
    color: AppColors.textPrimary,
    isAvailable: true,
  ),
];

LearningLanguageOption learningLanguageFor(String id) {
  return learningLanguageOptions.firstWhere(
    (language) => language.id == id,
    orElse: () => learningLanguageOptions.first,
  );
}

/// Toda linguagem com trilha publicada está liberada desde o primeiro dia.
///
/// Antes era preciso terminar os dois níveis de lógica para destravar
/// qualquer linguagem. Quem já programa não tinha por que passar por ali, e
/// quem queria começar por outra linguagem desistia na porta. Lógica virou
/// recomendação — continua sendo a primeira da lista —, não pedágio.
bool isLearningLanguageUnlocked(LearningLanguageOption language) =>
    language.isAvailable;

/// Etiqueta mostrada ao lado da linguagem na lista. `null` quando não há
/// nada a avisar.
String? learningLanguageStatusLabel(LearningLanguageOption language) =>
    language.isAvailable ? null : 'Em breve';

List<LearningLanguageOption> learningLanguagesForModule(String moduleId) {
  return learningLanguageOptions
      .where((language) => language.moduleId == moduleId)
      .toList(growable: false);
}
