import { labelFor, TrackPosition } from '../curriculum';
import {
  AiError,
  chatJson,
  generatorProvider,
  reviewerProvider,
} from './client';
import { Challenge, DIFFICULTIES, validateChallenge } from '../challenge';

/// Tipos que a tela do desafio diário sabe desenhar.
///
/// `codeChallenge` (montar com peças prontas) fica de fora de propósito: no
/// desafio do dia a pessoa escreve o código, e as peças prontas já são o
/// formato das lições da trilha.
const ALLOWED_TYPES: readonly Challenge['type'][] = ['quiz', 'codeWrite'];

/// Esteira do desafio do dia: gera, confere no código, revisa com a outra IA.
///
/// A ordem importa. O validador determinístico roda **antes** do revisor:
/// formato quebrado é barato de pegar com um `for` e não vale uma chamada
/// paga. O revisor só recebe desafio bem formado, e responde a única pergunta
/// que código não responde — a resposta marcada é mesmo a certa?

export interface GeneratedChallenge {
  challenge: Challenge;
  generatorModel: string;
  reviewerModel: string | null;
  reviewNotes: string | null;
}

export interface PipelineFailure {
  stage: 'config' | 'generate' | 'validate' | 'review';
  detail: string;
}

export class PipelineError extends Error {
  readonly failure: PipelineFailure;
  constructor(failure: PipelineFailure) {
    super(`${failure.stage}: ${failure.detail}`);
    this.failure = failure;
  }
}

const GENERATOR_SYSTEM = [
  'Você escreve exercícios curtos para o Buggo, um app brasileiro que ensina',
  'programação para iniciantes, muitos deles adolescentes.',
  '',
  'Regras absolutas:',
  '- Responda SOMENTE com um objeto JSON, sem texto em volta.',
  '- Escreva tudo em português do Brasil.',
  '- O exercício tem que ter uma única resposta certa, e as alternativas',
  '  erradas têm que estar de fato erradas — nada de duas defensáveis.',
  '- Use apenas assunto que a pessoa já estudou, listado no pedido.',
  '- Nada de conteúdo adulto, violento, político ou ofensivo.',
  '- Sem HTML e sem links.',
].join('\n');

const REVIEWER_SYSTEM = [
  'Você revisa exercícios de programação de um app para iniciantes',
  'brasileiros, muitos adolescentes. Seu trabalho é reprovar o que está',
  'errado, não elogiar.',
  '',
  'Responda SOMENTE com JSON: {"approved": boolean, "reason": string,',
  '"difficulty": "facil"|"media"|"dificil"}.',
  '',
  'Reprove se qualquer uma for verdadeira:',
  '- A resposta marcada como correta não é a correta.',
  '- Alguma alternativa errada também poderia ser aceita como certa.',
  '- Num desafio de escrever código: a "solution" não resolve o enunciado, ou',
  '  algum item de "mustContain" pode faltar numa resposta correta.',
  '- O código tem erro de sintaxe na linguagem indicada.',
  '- O enunciado depende de assunto fora da lista do que já foi estudado.',
  '- Não está em português do Brasil.',
  '- Tem conteúdo inadequado para adolescente.',
  '',
  'Em "reason", escreva uma frase curta dizendo o motivo. Aprovar por',
  'educação é o pior resultado possível: prefira reprovar na dúvida.',
].join('\n');

function generatorPrompt(position: TrackPosition): string {
  const label = labelFor(position.languageId);
  // Lógica não tem linguagem para escrever código; ali só cabe múltipla
  // escolha.
  const codeAllowed = position.languageId !== 'logic' &&
    ALLOWED_TYPES.includes('codeWrite');
  const covered = position.coveredTitles.length > 0
    ? position.coveredTitles.map((t) => `- ${t}`).join('\n')
    : '- (ainda não concluiu nenhuma lição; use só o básico do assunto)';

  return [
    `Linguagem: ${label}.`,
    `Nível atual da pessoa: "${position.currentLevelTitle}" `
    + `(${position.lessonsDoneInStage} de ${position.totalLessonsInStage} `
    + 'lições concluídas neste nível).',
    '',
    'Assuntos que ela JÁ estudou e pode usar:',
    covered,
    '',
    'Escreva UM desafio do dia sobre esses assuntos. Escolha um dos dois',
    'formatos e responda exatamente nele.',
    '',
    codeAllowed
      ? 'Prefira o formato "codeWrite": a pessoa escrever o código rende '
        + 'mais que escolher alternativa. Use "quiz" quando o assunto for '
        + 'conceito, não escrita de código.'
      : 'Use o formato "quiz".',
    '',
    'A) Múltipla escolha:',
    '{"type":"quiz","title":"...","description":"...",',
    ' "difficulty":"facil|media|dificil","question":"...","hint":"...",',
    ' "options":["...","...","..."],"correctIndex":0}',
    '',
    '- 3 ou 4 alternativas, todas diferentes.',
    '- "correctIndex" é a posição da alternativa certa, começando em 0.',
    ...(codeAllowed ? [
      '',
      'B) Escrever código à mão:',
      '{"type":"codeWrite","title":"...","description":"...",',
      ' "difficulty":"facil|media|dificil","question":"...","hint":"...",',
      ` "language":"${label}","starterCode":"","solution":"...",`,
      ' "mustContain":["for","print"]}',
      '',
      '- "question" descreve em português o que a pessoa tem que escrever.',
      '- "solution" é uma resposta correta completa. Ela não é mostrada;',
      '  serve para corrigir o que a pessoa escrever.',
      '- "mustContain" são de 1 a 3 trechos que QUALQUER resposta correta',
      '  precisa conter (uma palavra-chave, um nome de função). Eles são',
      '  conferidos no texto, então evite algo que possa ser escrito de',
      '  outra forma. A sua própria "solution" tem que conter todos.',
      '- "starterCode" pode ser "" ou um começo curto para a pessoa',
      '  continuar. Não coloque a resposta nele.',
      '- Peça algo que caiba em poucas linhas: a pessoa vai digitar no',
      '  celular.',
    ] : []),
    '',
    'Em qualquer formato:',
    '- title com até 60 caracteres.',
    '- "difficulty" é a sua avaliação do esforço; o prêmio em moedas é',
    '  decidido pelo servidor, não por você.',
  ].join('\n');
}

function reviewerPrompt(challenge: Challenge, position: TrackPosition): string {
  return [
    `Linguagem: ${labelFor(position.languageId)}.`,
    `Nível: "${position.currentLevelTitle}".`,
    '',
    'Assuntos que a pessoa já estudou:',
    position.coveredTitles.map((t) => `- ${t}`).join('\n') || '- (nenhum)',
    '',
    'Exercício a revisar, com gabarito:',
    JSON.stringify(challenge, null, 2),
  ].join('\n');
}

interface Review {
  approved: boolean;
  reason: string;
  difficulty?: string;
}

function parseReview(raw: unknown): Review {
  if (typeof raw !== 'object' || raw === null) {
    return { approved: false, reason: 'revisor não devolveu objeto' };
  }
  const data = raw as Record<string, unknown>;
  // Só `true` explícito aprova: qualquer resposta estranha é reprovação.
  const approved = data.approved === true;
  const reason = typeof data.reason === 'string' ? data.reason.slice(0, 400) : '';
  const difficulty = typeof data.difficulty === 'string'
    ? data.difficulty
    : undefined;
  return { approved, reason, difficulty };
}

/// Uma tentativa completa: gerar, validar, revisar.
async function attempt(position: TrackPosition): Promise<GeneratedChallenge> {
  const generator = generatorProvider();
  if (!generator) {
    throw new PipelineError({
      stage: 'config',
      detail: 'DEEPSEEK_API_KEY não está definida',
    });
  }

  let raw: unknown;
  try {
    raw = await chatJson(generator, {
      system: GENERATOR_SYSTEM,
      user: generatorPrompt(position),
      timeoutMs: 25000,
    });
  } catch (error) {
    throw new PipelineError({
      stage: 'generate',
      detail: error instanceof AiError ? error.message : String(error),
    });
  }

  const validation = validateChallenge(raw);
  if (!validation.ok) {
    throw new PipelineError({
      stage: 'validate',
      detail: validation.problems.join('; '),
    });
  }
  const challenge = validation.challenge;

  if (!ALLOWED_TYPES.includes(challenge.type)) {
    throw new PipelineError({
      stage: 'validate',
      detail: `tipo "${challenge.type}" ainda não é exibido pelo app`,
    });
  }

  const reviewer = reviewerProvider();
  if (!reviewer) {
    // Sem revisor configurado o desafio não vai ao ar. Publicar direto o que
    // um modelo escreveu, com moeda no fim, é o cenário que a revisão existe
    // para evitar.
    throw new PipelineError({
      stage: 'config',
      detail: 'OPENAI_API_KEY não está definida (revisor obrigatório)',
    });
  }

  let review: Review;
  try {
    review = parseReview(
      await chatJson(reviewer, {
        system: REVIEWER_SYSTEM,
        user: reviewerPrompt(challenge, position),
        timeoutMs: 20000,
        maxTokens: 300,
      }),
    );
  } catch (error) {
    throw new PipelineError({
      stage: 'review',
      detail: error instanceof AiError ? error.message : String(error),
    });
  }

  if (!review.approved) {
    throw new PipelineError({
      stage: 'review',
      detail: review.reason || 'reprovado sem motivo declarado',
    });
  }

  // O revisor pode corrigir a dificuldade — ele viu o gabarito. É só isso que
  // ele pode mexer: o prêmio continua saindo da tabela em código.
  const difficulty = review.difficulty &&
      (DIFFICULTIES as readonly string[]).includes(review.difficulty)
    ? (review.difficulty as Challenge['difficulty'])
    : challenge.difficulty;

  return {
    challenge: { ...challenge, difficulty },
    generatorModel: `${generator.name}:${generator.model}`,
    reviewerModel: `${reviewer.name}:${reviewer.model}`,
    reviewNotes: review.reason || null,
  };
}

/// Gera o desafio, com uma segunda chance.
///
/// Uma repetição cobre o caso comum (modelo escorregou no formato ou o
/// revisor pegou um detalhe). Insistir mais que isso gasta tempo de função e
/// dinheiro sem melhorar — se falhou duas vezes, é melhor o app não mostrar o
/// desafio hoje do que mostrar algo que ninguém conferiu.
export async function generateDailyChallenge(
  position: TrackPosition,
): Promise<GeneratedChallenge> {
  try {
    return await attempt(position);
  } catch (first) {
    if (first instanceof PipelineError && first.failure.stage === 'config') {
      throw first;
    }
    return attempt(position);
  }
}
