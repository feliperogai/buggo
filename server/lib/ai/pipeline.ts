import { labelFor, TrackPosition } from '../curriculum';
import {
  AiError,
  chatJson,
  generatorProvider,
} from './client';
import { Challenge, DIFFICULTIES, validateChallenge } from '../challenge';

/// Tipos que a tela do desafio diário sabe desenhar.
///
/// `codeChallenge` (montar com peças prontas) fica de fora de propósito: no
/// desafio do dia a pessoa escreve o código, e as peças prontas já são o
/// formato das lições da trilha.
const ALLOWED_TYPES: readonly Challenge['type'][] = ['quiz', 'codeWrite'];

/// Esteira do desafio do dia: gera e confere o formato no código.
///
/// O gerador publica sozinho. Não há aprovação prévia de outra IA: a revisão
/// prévia reprovava quase tudo — inclusive soluções que ela própria admitia
/// estarem certas, por detalhe de espaçamento — e o app ficava sem desafio
/// nenhum. A segunda IA continua no circuito, mas no outro extremo: ela
/// corrige a resposta que a pessoa enviou (`lib/ai/grade.ts`).
///
/// O que sobrou aqui é determinístico e barato: validação de formato e de
/// tipo suportado. Nada que dependa de julgamento.

export interface GeneratedChallenge {
  challenge: Challenge;
  generatorModel: string;
  reviewerModel: string | null;
  reviewNotes: string | null;
}

export interface PipelineFailure {
  stage: 'config' | 'generate' | 'validate';
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

/// Uma tentativa completa: gerar e validar.
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

  // A dificuldade agora é a que o gerador declarou. Ela só é aceita se for um
  // dos valores conhecidos — o prêmio sai de REWARD_COINS a partir dela, e um
  // valor inventado pelo modelo não pode virar moeda.
  const difficulty =
    (DIFFICULTIES as readonly string[]).includes(challenge.difficulty)
      ? challenge.difficulty
      : 'facil';

  return {
    challenge: { ...challenge, difficulty },
    generatorModel: `${generator.name}:${generator.model}`,
    // Preenchidos por quem corrige a resposta, não mais na geração.
    reviewerModel: null,
    reviewNotes: null,
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
