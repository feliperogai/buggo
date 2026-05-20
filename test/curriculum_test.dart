import 'package:flutter_test/flutter_test.dart';
import 'package:buggo/core/utils/python_simulator.dart';
import 'package:buggo/data/content/python_curriculum.dart';
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
}
