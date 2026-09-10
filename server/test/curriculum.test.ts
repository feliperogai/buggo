import assert from 'node:assert/strict';
import { test } from 'node:test';

import { CURRICULUM_OUTLINE } from '../lib/curriculum-outline';
import {
  knownLanguageIds,
  LANGUAGE_LABELS,
  levelsForLanguage,
  positionFor,
} from '../lib/curriculum';

// Os números são exatos de propósito: é o que faz este teste falhar quando
// alguém mexe nas trilhas em Dart e esquece de rodar
// `tool/build_curriculum_outline.py`. Ao adicionar conteúdo, rode o script e
// atualize os dois valores aqui.
test('o esqueleto cobre todas as linguagens do app', () => {
  const languages = knownLanguageIds();
  assert.equal(languages.length, 16);
  assert.equal(CURRICULUM_OUTLINE.length, 50);

  const lessons = CURRICULUM_OUTLINE.flatMap((level) => level.lessons);
  assert.equal(lessons.length, 310);
  assert.equal(new Set(lessons.map((l) => l.id)).size, lessons.length);
});

test('nenhuma linguagem fica sem rótulo para o prompt', () => {
  const missing = knownLanguageIds().filter((id) => !LANGUAGE_LABELS[id]);
  assert.deepEqual(missing, []);
});

test('os níveis de cada trilha vêm em ordem, a partir do zero', () => {
  for (const languageId of knownLanguageIds()) {
    const levels = levelsForLanguage(languageId);
    assert.equal(levels.length > 0, true, languageId);
    levels.forEach((level, i) => assert.equal(level.index, i, languageId));
  }
});

test('quem não concluiu nada está no primeiro nível', () => {
  const position = positionFor('rust', []);
  assert.notEqual(position, null);
  assert.equal(position!.stage, 0);
  assert.deepEqual(position!.coveredTitles, []);
  assert.equal(position!.lessonsDoneInStage, 0);
});

test('fechar o primeiro nível avança o estágio e acumula o que foi visto', () => {
  const [first] = levelsForLanguage('rust');
  const done = first.lessons.map((l) => l.id);

  const position = positionFor('rust', done)!;
  assert.equal(position.stage, 1);
  assert.equal(position.lessonsDoneInStage, 0);
  // O prompt só pode citar assunto que a pessoa já viu.
  assert.deepEqual(position.coveredTitles, first.lessons.map((l) => l.title));
});

test('lição solta do nível atual entra no que já foi visto', () => {
  const levels = levelsForLanguage('go');
  const done = [...levels[0].lessons.map((l) => l.id), levels[1].lessons[0].id];

  const position = positionFor('go', done)!;
  assert.equal(position.stage, 1);
  assert.equal(position.lessonsDoneInStage, 1);
  assert.equal(position.coveredTitles.includes(levels[1].lessons[0].title), true);
  assert.equal(position.coveredTitles.includes(levels[1].lessons[1].title), false);
});

test('quem terminou a trilha inteira para no último nível', () => {
  const levels = levelsForLanguage('python');
  const done = levels.flatMap((level) => level.lessons.map((l) => l.id));

  const position = positionFor('python', done)!;
  assert.equal(position.stage, levels.length - 1);
});

test('linguagem sem trilha não tem posição', () => {
  assert.equal(positionFor('cobol', []), null);
});

test('progresso de outra linguagem não adianta a trilha atual', () => {
  const python = levelsForLanguage('python')
    .flatMap((level) => level.lessons.map((l) => l.id));

  const position = positionFor('swift', python)!;
  assert.equal(position.stage, 0);
  assert.deepEqual(position.coveredTitles, []);
});
