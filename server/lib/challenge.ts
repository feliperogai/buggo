// Regras do desafio diário que valem para geração e correção.

/**
 * Teto de envios por dia, por aluno.
 *
 * O desafio não custa vidas e o aluno pode tentar à vontade, mas cada envio
 * é uma chamada paga à DeepSeek. Sem teto, um script apontado para a rota
 * esvaziaria o crédito da conta. Vinte é folgado para uso humano: quem não
 * resolveu em vinte tentativas precisa de dica, não de mais uma chamada.
 */
export const MAX_ATTEMPTS_PER_DAY = 20;

/**
 * A "data de hoje" é sempre a de São Paulo, não a UTC da função serverless.
 * Sem isso o desafio virava às 21h no horário de Brasília.
 */
export function todayInSaoPaulo(): string {
  return new Date().toLocaleDateString('en-CA', {
    timeZone: 'America/Sao_Paulo',
  });
}

/**
 * Aluno que ainda está em Fundamentos não viu sintaxe nenhuma, então o
 * desafio digitado sai em Python — a linguagem mais legível para quem nunca
 * programou — com o enunciado ensinando o mínimo necessário.
 */
export function languageForChallenge(userLanguage: string): string {
  if (!userLanguage || userLanguage === 'logic') return 'python';
  return userLanguage;
}

function difficultyFor(completedCount: number): string {
  if (completedCount < 8) {
    return (
      'INICIANTE: o aluno mal começou. Use apenas variáveis, input/print, ' +
      'if/else e operadores. Nada de laços aninhados, funções complexas, ' +
      'listas de listas ou bibliotecas.'
    );
  }
  if (completedCount < 25) {
    return (
      'INTERMEDIÁRIO: pode usar laços (for/while), listas, strings e uma ' +
      'função definida pelo aluno. Nada de classes, recursão ou bibliotecas ' +
      'externas.'
    );
  }
  return (
    'AVANÇADO: pode exigir combinação de estruturas de dados, funções ' +
    'auxiliares, dicionários e tratamento de casos de borda. Ainda sem ' +
    'bibliotecas externas.'
  );
}

export const GENERATION_SYSTEM = `Você cria desafios de programação para o Buggo, um app brasileiro que ensina programação para iniciantes.

Regras absolutas:
- Responda SEMPRE em português do Brasil.
- Responda SEMPRE um único objeto JSON válido, sem markdown e sem cercas de código.
- O desafio deve ser resolvido digitando código do zero, nunca escolhendo alternativas.
- O desafio deve ser um degrau ACIMA do que o aluno já domina: exige pensar, mas é resolvível em 10 a 20 minutos por quem estudou os tópicos listados.
- O enunciado precisa ser autocontido: quem ler entende o que fazer sem consultar nada.
- Se o desafio usar algo que o aluno provavelmente ainda não viu, explique no próprio enunciado.

Formato do JSON:
{
  "title": "título curto, até 40 caracteres",
  "statement": "enunciado em português, com o que fazer, o formato da entrada e o da saída, e um exemplo concreto de entrada e saída esperada",
  "starterCode": "código inicial com comentários guiando, e o ponto onde o aluno escreve. Nunca inclua a solução.",
  "expectedBehavior": "descrição objetiva e completa do que o código correto precisa fazer, incluindo casos de borda. Este texto será usado depois para corrigir, e o aluno NUNCA o vê."
}`;

export function buildGenerationPrompt(params: {
  language: string;
  level: string;
  completedCount: number;
  topics: string[];
}): string {
  const topicList =
    params.topics.length > 0
      ? params.topics.slice(-25).map((t) => `- ${t}`).join('\n')
      : '- (ainda não concluiu nenhuma lição)';

  return `Linguagem do desafio: ${params.language}
Nível declarado pelo aluno: ${params.level}
Lições já concluídas: ${params.completedCount}

Dificuldade alvo: ${difficultyFor(params.completedCount)}

Tópicos que o aluno já estudou:
${topicList}

Gere o desafio de hoje.`;
}

export const GRADING_SYSTEM = `Você corrige exercícios de programação de alunos iniciantes brasileiros, no app Buggo.

Regras absolutas:
- Responda SEMPRE em português do Brasil.
- Responda SEMPRE um único objeto JSON válido, sem markdown e sem cercas de código.
- Julgue apenas se o código cumpre o comportamento esperado. Estilo, nomes de variáveis e formatação não reprovam.
- Aprove soluções corretas mesmo que diferentes da que você imaginaria.
- Reprove se o código não roda (erro de sintaxe), se não faz o que foi pedido, ou se falha em um caso de borda descrito no comportamento esperado.
- NUNCA entregue o código pronto no feedback. Aponte o problema e dê a pista do próximo passo — o aluno precisa chegar sozinho.
- Se reprovar, seja específico: diga o que acontece de errado e com qual entrada.
- Seja encorajador. O aluno está aprendendo.

Formato do JSON:
{
  "passed": true ou false,
  "feedback": "2 a 4 frases em português. Se reprovou, o que está errado e a pista. Se aprovou, o que ficou bom.",
  "errorLine": número da linha do problema principal, ou null se não se aplica
}`;

export function buildGradingPrompt(params: {
  language: string;
  statement: string;
  expectedBehavior: string;
  code: string;
}): string {
  return `Linguagem: ${params.language}

Enunciado mostrado ao aluno:
${params.statement}

Comportamento esperado (gabarito interno, o aluno não viu isto):
${params.expectedBehavior}

Código enviado pelo aluno:
\`\`\`
${params.code}
\`\`\`

Corrija.`;
}
