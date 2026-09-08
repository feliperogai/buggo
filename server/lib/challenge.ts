/// Formato do desafio diário, validação determinística e tabela de prêmio.
///
/// Nada aqui chama IA. É de propósito: o que dá para conferir com um `for`
/// não pode depender de um modelo dizer que está tudo bem — revisor de IA
/// tende a concordar. O modelo revisor só entra depois, para o que exige
/// julgamento (a resposta marcada é mesmo a certa?), em `ai/review.ts`.

export type Difficulty = 'facil' | 'media' | 'dificil';

export const DIFFICULTIES: readonly Difficulty[] = ['facil', 'media', 'dificil'];

/// Moedas por dificuldade. **A IA não decide isto.** Ela classifica o
/// desafio; a tabela abaixo, que é código, vira moeda. Sem isso um modelo
/// alucinando "500 moedas" mexeria numa economia que tem preço em real na
/// Play Store.
///
/// XP não entra: XP é dos módulos da trilha, o desafio diário paga em moeda.
export const REWARD_COINS: Record<Difficulty, number> = {
  facil: 15,
  media: 25,
  dificil: 40,
};

export interface QuizChallenge {
  type: 'quiz';
  title: string;
  description: string;
  difficulty: Difficulty;
  question: string;
  hint: string | null;
  options: string[];
  correctIndex: number;
}

export interface CodeChallenge {
  type: 'codeChallenge';
  title: string;
  description: string;
  difficulty: Difficulty;
  question: string;
  hint: string | null;
  codeTemplate: string;
  availableTokens: string[];
  correctTokens: string[];
}

export type Challenge = QuizChallenge | CodeChallenge;

/// O que vai para o aparelho: tudo, menos o gabarito. A conferência é no
/// servidor, então mandar a resposta junto seria entregar as moedas.
export type PublicChallenge =
  | Omit<QuizChallenge, 'correctIndex'>
  | Omit<CodeChallenge, 'correctTokens'>;

export type ValidationResult =
  | { ok: true; challenge: Challenge }
  | { ok: false; problems: string[] };

const MAX_TITLE = 60;
const MAX_TEXT = 400;
const MAX_TOKENS = 8;

function text(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function looksLikeMarkup(value: string): boolean {
  return /<\s*(script|iframe|img|a)\b/i.test(value);
}

/// Confere o que é conferível sem opinião: formato, tamanho, gabarito dentro
/// do intervalo, lacunas batendo com as peças, peça correta presente entre as
/// opções. São as mesmas invariantes que `test/curriculum_test.dart` exige do
/// conteúdo escrito à mão.
export function validateChallenge(raw: unknown): ValidationResult {
  const problems: string[] = [];
  if (typeof raw !== 'object' || raw === null) {
    return { ok: false, problems: ['resposta não é um objeto'] };
  }
  const data = raw as Record<string, unknown>;

  const type = text(data.type);
  if (type !== 'quiz' && type !== 'codeChallenge') {
    return { ok: false, problems: [`type inválido: "${type}"`] };
  }

  const title = text(data.title);
  const description = text(data.description);
  const question = text(data.question);
  const hintRaw = text(data.hint);
  const difficulty = text(data.difficulty) as Difficulty;

  if (!title) problems.push('title vazio');
  if (title.length > MAX_TITLE) problems.push('title longo demais');
  if (!description) problems.push('description vazio');
  if (description.length > MAX_TEXT) problems.push('description longo demais');
  if (!question) problems.push('question vazio');
  if (question.length > MAX_TEXT) problems.push('question longo demais');
  if (!DIFFICULTIES.includes(difficulty)) {
    problems.push(`difficulty inválida: "${difficulty}"`);
  }
  for (const [field, value] of [
    ['title', title],
    ['description', description],
    ['question', question],
    ['hint', hintRaw],
  ] as const) {
    if (looksLikeMarkup(value)) problems.push(`${field} contém marcação HTML`);
  }

  const hint = hintRaw.length > 0 ? hintRaw : null;

  if (type === 'quiz') {
    const options = Array.isArray(data.options)
      ? data.options.map((o) => text(o))
      : [];
    const correctIndex = typeof data.correctIndex === 'number'
      ? data.correctIndex
      : -1;

    if (options.length < 3 || options.length > 4) {
      problems.push(`quiz precisa de 3 ou 4 alternativas, veio ${options.length}`);
    }
    if (options.some((o) => o.length === 0)) problems.push('alternativa vazia');
    if (options.some((o) => o.length > MAX_TEXT)) {
      problems.push('alternativa longa demais');
    }
    if (new Set(options).size !== options.length) {
      problems.push('alternativas repetidas');
    }
    if (!Number.isInteger(correctIndex) ||
        correctIndex < 0 ||
        correctIndex >= options.length) {
      problems.push(`correctIndex fora do intervalo: ${correctIndex}`);
    }
    if (options.some(looksLikeMarkup)) problems.push('alternativa com HTML');

    if (problems.length > 0) return { ok: false, problems };
    return {
      ok: true,
      challenge: {
        type: 'quiz',
        title,
        description,
        difficulty,
        question,
        hint,
        options,
        correctIndex,
      },
    };
  }

  const codeTemplate = typeof data.codeTemplate === 'string'
    ? data.codeTemplate
    : '';
  const availableTokens = Array.isArray(data.availableTokens)
    ? data.availableTokens.map((t) => text(t))
    : [];
  const correctTokens = Array.isArray(data.correctTokens)
    ? data.correctTokens.map((t) => text(t))
    : [];

  if (!codeTemplate.trim()) problems.push('codeTemplate vazio');
  if (codeTemplate.length > 600) problems.push('codeTemplate longo demais');
  if (correctTokens.length === 0) problems.push('sem peças corretas');
  if (correctTokens.some((t) => t.length === 0)) problems.push('peça vazia');
  if (availableTokens.length > MAX_TOKENS) {
    problems.push(`peças demais: ${availableTokens.length}`);
  }
  if (availableTokens.length <= correctTokens.length) {
    problems.push('faltam peças distratoras');
  }
  if (new Set(availableTokens).size !== availableTokens.length) {
    problems.push('peças repetidas');
  }
  for (const token of correctTokens) {
    if (!availableTokens.includes(token)) {
      problems.push(`peça correta "${token}" não está entre as opções`);
    }
  }

  // Uma lacuna pode se repetir no template; o que precisa bater é o conjunto
  // de índices usados.
  const placeholders = new Set(
    [...codeTemplate.matchAll(/\{(\d+)\}/g)].map((m) => Number(m[1])),
  );
  const expected = new Set(correctTokens.map((_, i) => i));
  const sameSize = placeholders.size === expected.size;
  const sameItems = [...expected].every((i) => placeholders.has(i));
  if (!sameSize || !sameItems) {
    problems.push(
      `lacunas {${[...placeholders].sort().join(',')}} não batem com ` +
      `${correctTokens.length} peça(s)`,
    );
  }

  if (problems.length > 0) return { ok: false, problems };
  return {
    ok: true,
    challenge: {
      type: 'codeChallenge',
      title,
      description,
      difficulty,
      question,
      hint,
      codeTemplate,
      availableTokens,
      correctTokens,
    },
  };
}

export function publicChallenge(challenge: Challenge): PublicChallenge {
  if (challenge.type === 'quiz') {
    const { correctIndex: _omit, ...rest } = challenge;
    return rest;
  }
  const { correctTokens: _omit, ...rest } = challenge;
  return rest;
}

/// Confere a resposta enviada pelo app. O gabarito nunca saiu do servidor.
export function isAnswerCorrect(challenge: Challenge, answer: unknown): boolean {
  if (typeof answer !== 'object' || answer === null) return false;
  const data = answer as Record<string, unknown>;

  if (challenge.type === 'quiz') {
    return data.optionIndex === challenge.correctIndex;
  }

  const tokens = Array.isArray(data.tokens) ? data.tokens : null;
  if (tokens === null || tokens.length !== challenge.correctTokens.length) {
    return false;
  }
  return challenge.correctTokens.every((token, i) => tokens[i] === token);
}
