import 'package:flutter_test/flutter_test.dart';
import 'package:buggo/core/utils/python_simulator.dart';
import 'package:buggo/data/content/curriculum.dart';
import 'package:buggo/data/content/python_curriculum.dart';
import 'package:buggo/shared/constants/learning_languages.dart';
import 'package:buggo/shared/models/lesson.dart';

void main() {
  test('all Python code challenges match expected output', () {
    final failures = <String>[];

    for (final level in pythonCurriculum) {
      for (final lesson in level.lessons) {
        if (lesson.type != LessonType.codeChallenge) continue;

        final template = lesson.codeTemplate;
        final tokens = lesson.correctTokens;
        final expected = lesson.expectedOutput;

        if (template == null || tokens == null || expected == null) {
          failures.add('${lesson.id}: missing challenge fields');
          continue;
        }

        var code = template;
        for (var i = 0; i < tokens.length; i++) {
          code = code.replaceAll('{$i}', tokens[i]);
        }

        try {
          final output = PythonSimulator().simulate(code).trim();
          if (output != expected.trim()) {
            failures.add(
              '${lesson.id}: expected "${expected.trim()}", got "$output"',
            );
          }
        } catch (error) {
          failures.add('${lesson.id}: simulator error $error');
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('nenhuma lição repete id entre as trilhas', () {
    final seen = <String>{};
    final duplicates = <String>[];

    for (final level in courseCurriculum) {
      for (final lesson in level.lessons) {
        if (!seen.add(lesson.id)) duplicates.add(lesson.id);
      }
    }

    // O progresso é gravado por id de lição, então um id repetido faria uma
    // linguagem marcar lição de outra como concluída.
    expect(duplicates, isEmpty, reason: duplicates.join(', '));
  });

  test('toda linguagem oferecida tem trilha de verdade', () {
    final missing = learningLanguageOptions
        .where((language) => language.isAvailable)
        .where((language) => !hasCurriculum(language.id))
        .map((language) => language.id)
        .toList();

    expect(missing, isEmpty,
        reason: 'sem níveis publicados: ${missing.join(', ')}');
  });

  test('todo nível aponta para uma linguagem que existe na lista', () {
    final known = learningLanguageOptions.map((l) => l.id).toSet();
    final unknown = courseCurriculum
        .map((level) => level.languageId)
        .where((id) => !known.contains(id))
        .toSet();

    expect(unknown, isEmpty, reason: unknown.join(', '));
  });

  test('nenhuma linguagem está trancada atrás de outra', () {
    // Regressão: antes era obrigatório concluir os dois níveis de lógica
    // para destravar qualquer linguagem.
    for (final language in learningLanguageOptions) {
      expect(isLearningLanguageUnlocked(language), isTrue,
          reason: '${language.id} deveria estar liberada');
      expect(learningLanguageStatusLabel(language), isNull,
          reason: '${language.id} não deveria ter etiqueta de bloqueio');
    }
  });

  test('cada trilha começa por um nível destravado', () {
    for (final language in learningLanguageOptions) {
      final levels = levelsForLanguage(language.id);
      expect(levels, isNotEmpty, reason: 'trilha vazia: ${language.id}');
      expect(levels.first.level.isLocked, isFalse,
          reason: 'primeiro nível de ${language.id} está trancado');
    }
  });

  test('desafios sem simulador têm lacunas e peças coerentes', () {
    final failures = <String>[];

    for (final level in courseCurriculum) {
      for (final lesson in level.lessons) {
        if (lesson.type != LessonType.codeChallenge) continue;
        if (lesson.expectedOutput != null) continue; // trilha de Python

        final template = lesson.codeTemplate;
        final correct = lesson.correctTokens;
        final available = lesson.availableTokens;

        if (template == null || correct == null || available == null) {
          failures.add('${lesson.id}: faltam campos do desafio');
          continue;
        }

        // Uma lacuna pode aparecer mais de uma vez no template; o que precisa
        // bater é o conjunto de índices usados.
        final placeholders = RegExp(r'\{(\d+)\}')
            .allMatches(template)
            .map((m) => int.parse(m.group(1)!))
            .toSet();
        final expected = {for (var i = 0; i < correct.length; i++) i};
        if (placeholders.length != correct.length ||
            !placeholders.containsAll(expected)) {
          failures.add(
            '${lesson.id}: lacunas $placeholders não batem com '
            '${correct.length} peça(s) correta(s)',
          );
        }

        for (final token in correct) {
          if (!available.contains(token)) {
            failures.add('${lesson.id}: peça "$token" não está entre as opções');
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('toda pergunta de quiz tem exatamente uma resposta certa', () {
    final failures = <String>[];

    for (final level in courseCurriculum) {
      for (final lesson in level.lessons) {
        if (lesson.type != LessonType.quiz) continue;
        final corrects = lesson.options.where((o) => o.isCorrect).length;
        if (corrects != 1) {
          failures.add('${lesson.id}: $corrects respostas corretas');
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
