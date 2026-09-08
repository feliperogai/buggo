import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  DIFFICULTIES,
  isAnswerCorrect,
  publicChallenge,
  REWARD_COINS,
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
