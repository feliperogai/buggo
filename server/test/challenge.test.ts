import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  CodeWriteChallenge,
  DIFFICULTIES,
  isAnswerCorrect,
  missingRequirements,
  publicChallenge,
  REWARD_COINS,
  submittedCode,
  validateChallenge,
} from '../lib/challenge';
import { parseJsonLoosely } from '../lib/ai/client';

const goodQuiz = {
  type: 'quiz',
  title: 'Somando em Python',
  description: 'Um desafio rápido sobre print',
  difficulty: 'facil',
  question: 'O que print(2 + 3) mostra?',
  hint: 'Some antes de imprimir.',
  options: ['5', '23', 'erro'],
  correctIndex: 0,
};

const goodCode = {
  type: 'codeChallenge',
  title: 'Complete o laço',
  description: 'Mostre 1, 2 e 3',
  difficulty: 'media',
  question: 'Complete o for.',
  hint: 'Precisa incluir o 3.',
  codeTemplate: 'for (int i = 1; i {0} 3; i{1}) {}',
  availableTokens: ['<=', '<', '++', '--'],
  correctTokens: ['<=', '++'],
};

test('quiz bem formado passa', () => {
  const result = validateChallenge(goodQuiz);
  assert.equal(result.ok, true);
});

test('quiz com correctIndex fora do intervalo é recusado', () => {
  const result = validateChallenge({ ...goodQuiz, correctIndex: 3 });
  assert.equal(result.ok, false);
  assert.match(result.ok === false ? result.problems.join() : '', /correctIndex/);
});

test('quiz com alternativa repetida é recusado', () => {
  const result = validateChallenge({ ...goodQuiz, options: ['5', '5', 'erro'] });
  assert.equal(result.ok, false);
});

test('quiz com menos de três alternativas é recusado', () => {
  const result = validateChallenge({ ...goodQuiz, options: ['5', '23'], correctIndex: 0 });
  assert.equal(result.ok, false);
});

test('dificuldade inventada é recusada', () => {
  const result = validateChallenge({ ...goodQuiz, difficulty: 'impossivel' });
  assert.equal(result.ok, false);
});

test('HTML no enunciado é recusado', () => {
  const result = validateChallenge({
    ...goodQuiz,
    question: 'Veja <script>alert(1)</script>',
  });
  assert.equal(result.ok, false);
});

test('desafio de código bem formado passa', () => {
  const result = validateChallenge(goodCode);
  assert.equal(result.ok, true);
});

test('lacuna sem peça correspondente é recusada', () => {
  const result = validateChallenge({
    ...goodCode,
    codeTemplate: 'for (int i = 1; i {0} 3; i{1}) { {2} }',
  });
  assert.equal(result.ok, false);
  assert.match(result.ok === false ? result.problems.join() : '', /lacunas/);
});

test('peça correta fora das opções é recusada', () => {
  const result = validateChallenge({
    ...goodCode,
    availableTokens: ['<', '++', '--', '>='],
  });
  assert.equal(result.ok, false);
});

test('desafio sem distrator é recusado', () => {
  const result = validateChallenge({
    ...goodCode,
    availableTokens: ['<=', '++'],
  });
  assert.equal(result.ok, false);
});

test('o gabarito não sai do servidor', () => {
  const quiz = validateChallenge(goodQuiz);
  const code = validateChallenge(goodCode);
  assert.equal(quiz.ok && code.ok, true);
  if (!quiz.ok || !code.ok) return;

  const quizPublic = publicChallenge(quiz.challenge) as Record<string, unknown>;
  const codePublic = publicChallenge(code.challenge) as Record<string, unknown>;

  assert.equal('correctIndex' in quizPublic, false);
  assert.equal('correctTokens' in codePublic, false);
  // O que o app precisa continua indo.
  assert.deepEqual(quizPublic.options, ['5', '23', 'erro']);
  assert.deepEqual(codePublic.availableTokens, ['<=', '<', '++', '--']);
});

test('resposta de quiz é conferida no servidor', () => {
  const result = validateChallenge(goodQuiz);
  assert.equal(result.ok, true);
  if (!result.ok) return;

  assert.equal(isAnswerCorrect(result.challenge, { optionIndex: 0 }), true);
  assert.equal(isAnswerCorrect(result.challenge, { optionIndex: 1 }), false);
  assert.equal(isAnswerCorrect(result.challenge, {}), false);
  assert.equal(isAnswerCorrect(result.challenge, null), false);
});

test('peças na ordem errada não valem', () => {
  const result = validateChallenge(goodCode);
  assert.equal(result.ok, true);
  if (!result.ok) return;

  assert.equal(isAnswerCorrect(result.challenge, { tokens: ['<=', '++'] }), true);
  assert.equal(isAnswerCorrect(result.challenge, { tokens: ['++', '<='] }), false);
  assert.equal(isAnswerCorrect(result.challenge, { tokens: ['<='] }), false);
  assert.equal(isAnswerCorrect(result.challenge, { tokens: [] }), false);
});

test('toda dificuldade tem prêmio, e o prêmio é só moeda', () => {
  for (const difficulty of DIFFICULTIES) {
    const coins = REWARD_COINS[difficulty];
    assert.equal(typeof coins, 'number');
    assert.equal(coins > 0, true);
  }
  // XP é dos módulos da trilha; o desafio do dia paga em moeda.
  assert.equal(Object.keys(REWARD_COINS).length, DIFFICULTIES.length);
});

test('JSON embrulhado em cerca de markdown ainda é lido', () => {
  const parsed = parseJsonLoosely('```json\n{"approved": true}\n```', 'teste');
  assert.deepEqual(parsed, { approved: true });
});

// ── Desafio de escrever o código à mão ─────────────────────────────────

const goodWrite = {
  type: 'codeWrite',
  title: 'Some a lista',
  description: 'Escreva o código',
  difficulty: 'media',
  question: 'Escreva um laço que soma os números de uma lista e imprime o total.',
  hint: 'Use uma variável acumuladora.',
  language: 'Python',
  starterCode: 'numeros = [1, 2, 3]\n',
  solution: 'numeros = [1, 2, 3]\ntotal = 0\nfor n in numeros:\n    total += n\nprint(total)',
  mustContain: ['for', 'print'],
};

function parseWrite(raw: unknown): CodeWriteChallenge {
  const result = validateChallenge(raw);
  if (!result.ok) throw new Error(result.problems.join('; '));
  return result.challenge as CodeWriteChallenge;
}

test('desafio de escrever código bem formado passa', () => {
  assert.equal(validateChallenge(goodWrite).ok, true);
});

test('desafio de escrever sem solução de referência é recusado', () => {
  assert.equal(validateChallenge({ ...goodWrite, solution: '' }).ok, false);
});

test('desafio de escrever sem exigência objetiva é recusado', () => {
  // Sem nada conferível no código, a correção viraria só opinião da IA.
  assert.equal(validateChallenge({ ...goodWrite, mustContain: [] }).ok, false);
});

test('exigência que a própria solução não cumpre é recusada', () => {
  // Reprovaria toda resposta certa, inclusive a de referência.
  const result = validateChallenge({
    ...goodWrite,
    mustContain: ['while'],
  });
  assert.equal(result.ok, false);
  assert.match(
    result.ok === false ? result.problems.join() : '',
    /solução de referência/,
  );
});

test('nem a solução nem as exigências saem do servidor', () => {
  const publicView = publicChallenge(parseWrite(goodWrite)) as
      Record<string, unknown>;

  assert.equal('solution' in publicView, false);
  assert.equal('mustContain' in publicView, false);
  // O que a tela precisa continua indo.
  assert.equal(publicView.language, 'Python');
  assert.equal(typeof publicView.starterCode, 'string');
});

test('código escrito não passa pela conferência síncrona', () => {
  // A correção é assíncrona, em ai/grade.ts. Se este atalho um dia devolver
  // true, o desafio seria creditado sem ninguém ler a resposta.
  assert.equal(isAnswerCorrect(parseWrite(goodWrite), { code: 'x' }), false);
});

test('código enviado é limpo e limitado', () => {
  assert.equal(submittedCode({ code: '  print(1)  ' }), 'print(1)');
  assert.equal(submittedCode({ code: '   ' }), null);
  assert.equal(submittedCode({ code: 'a'.repeat(4001) }), null);
  assert.equal(submittedCode({ code: 42 }), null);
  assert.equal(submittedCode({}), null);
  assert.equal(submittedCode(null), null);
});

test('exigências objetivas são conferidas sem diferenciar maiúsculas', () => {
  const challenge = parseWrite(goodWrite);

  assert.deepEqual(
    missingRequirements(challenge, 'FOR n in x: PRINT(n)'),
    [],
  );
  assert.deepEqual(
    missingRequirements(challenge, 'total = sum(numeros)'),
    ['for', 'print'],
  );
  assert.deepEqual(
    missingRequirements(challenge, 'for n in x: pass'),
    ['print'],
  );
});
