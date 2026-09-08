import { CURRICULUM_OUTLINE, OutlineLevel } from './curriculum-outline';

/// Onde a pessoa está numa trilha, do ponto de vista do servidor.
///
/// Nada disso vem do app: `completed_lessons` já está no banco e o esqueleto
/// das trilhas está em `curriculum-outline.ts`. Um APK modificado não
/// consegue se declarar mais avançado do que é para ganhar mais moedas.
export interface TrackPosition {
  languageId: string;
  /** Índice do nível em que ela está — quantos níveis já fechou por inteiro. */
  stage: number;
  /** Título do nível atual, para o prompt. */
  currentLevelTitle: string;
  /** Tudo que ela já viu até aqui, em ordem. Vira a lista de assuntos. */
  coveredTitles: string[];
  /** Quantas lições do nível atual já foram concluídas. */
  lessonsDoneInStage: number;
  totalLessonsInStage: number;
}

/// Nome da linguagem para o prompt. O esqueleto gerado só carrega ids.
/// `curriculum.test.ts` garante que nenhuma linguagem fica sem rótulo.
export const LANGUAGE_LABELS: Record<string, string> = {
  logic: 'lógica de programação (sem linguagem específica)',
  python: 'Python',
  javascript: 'JavaScript',
  typescript: 'TypeScript',
  java: 'Java',
  csharp: 'C#',
  cpp: 'C++',
  c: 'C',
  go: 'Go',
  kotlin: 'Kotlin',
  swift: 'Swift',
  php: 'PHP',
  ruby: 'Ruby',
  rust: 'Rust',
  dart: 'Dart',
  queries: 'SQL',
};

export function labelFor(languageId: string): string {
  return LANGUAGE_LABELS[languageId] ?? languageId;
}

export function levelsForLanguage(languageId: string): OutlineLevel[] {
  return CURRICULUM_OUTLINE.filter((level) => level.languageId === languageId)
    .sort((a, b) => a.index - b.index);
}

export function knownLanguageIds(): string[] {
  return [...new Set(CURRICULUM_OUTLINE.map((level) => level.languageId))];
}

/// Calcula em que ponto da trilha a pessoa está.
///
/// `stage` é o índice do primeiro nível que ainda não foi fechado por
/// inteiro. Quem terminou tudo fica no último nível — o desafio do dia
/// continua vindo, só não avança mais.
export function positionFor(
  languageId: string,
  completedLessons: readonly string[],
): TrackPosition | null {
  const levels = levelsForLanguage(languageId);
  if (levels.length === 0) return null;

  const done = new Set(completedLessons);
  const covered: string[] = [];
  let stage = levels.length - 1;

  for (let i = 0; i < levels.length; i++) {
    const level = levels[i];
    const finished = level.lessons.every((lesson) => done.has(lesson.id));
    if (!finished) {
      stage = i;
      break;
    }
    covered.push(...level.lessons.map((lesson) => lesson.title));
  }

  const current = levels[stage];
  const lessonsDoneInStage = current.lessons.filter((l) => done.has(l.id)).length;

  // O nível atual entra parcialmente: só o que já foi concluído nele.
  covered.push(
    ...current.lessons.filter((l) => done.has(l.id)).map((l) => l.title),
  );

  return {
    languageId,
    stage,
    currentLevelTitle: current.title,
    coveredTitles: [...new Set(covered)],
    lessonsDoneInStage,
    totalLessonsInStage: current.lessons.length,
  };
}
