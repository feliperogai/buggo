import 'package:buggo/features/daily_challenge/presentation/widgets/code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// O editor do desafio diário é o único lugar do app onde o aluno digita
/// código livre, então o que é testado aqui é o que quebraria a experiência:
/// numeração de linhas, destaque de sintaxe e a indentação automática.
void main() {
  Future<void> pumpEditor(
    WidgetTester tester,
    CodeEditingController controller, {
    int? errorLine,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CodeEditor(controller: controller, errorLine: errorLine),
        ),
      ),
    );
  }

  testWidgets('numera uma linha por quebra de linha', (tester) async {
    final controller = CodeEditingController(text: 'a = 1\nb = 2\nprint(a + b)');
    await pumpEditor(tester, controller);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('numeração acompanha o que é digitado', (tester) async {
    final controller = CodeEditingController(text: 'x = 1');
    await pumpEditor(tester, controller);
    expect(find.text('2'), findsNothing);

    controller.text = 'x = 1\ny = 2';
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('destaca palavra-chave, string, número e comentário',
      (tester) async {
    final controller = CodeEditingController(
      text: 'if x == 10:\n    print("oi")  # comenta',
    );
    await pumpEditor(tester, controller);

    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      withComposing: false,
    );

    final colored = <String, Color?>{};
    void walk(InlineSpan span) {
      if (span is TextSpan) {
        final text = span.text;
        if (text != null) colored[text] = span.style?.color;
        for (final child in span.children ?? const <InlineSpan>[]) {
          walk(child);
        }
      }
    }

    walk(span);

    // Não fixamos os valores exatos da paleta — o que importa é que cada
    // categoria receba uma cor distinta da do texto comum.
    final plain = colored['x'];
    expect(colored['if'], isNotNull);
    expect(colored['if'], isNot(plain));
    expect(colored['"oi"'], isNot(plain));
    expect(colored['10'], isNot(plain));
    expect(colored['# comenta'], isNot(plain));

    // Categorias diferentes não podem colidir entre si.
    expect(colored['if'], isNot(colored['"oi"']));
    expect(colored['"oi"'], isNot(colored['# comenta']));
  });

  testWidgets('marca em vermelho a linha apontada pela correção',
      (tester) async {
    final controller = CodeEditingController(text: 'a = 1\nb = 2\nc = 3');
    await pumpEditor(tester, controller, errorLine: 2);

    final gutterTexts = tester.widgetList<Text>(find.text('2'));
    expect(gutterTexts, isNotEmpty);
    expect(gutterTexts.first.style?.color, const Color(0xFFEF4444));

    // As outras linhas seguem neutras.
    final first = tester.widgetList<Text>(find.text('1')).first;
    expect(first.style?.color, isNot(const Color(0xFFEF4444)));
  });

  testWidgets('Enter mantém a indentação da linha anterior', (tester) async {
    final controller = CodeEditingController(text: '    x = 1');
    await pumpEditor(tester, controller);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    controller.selection =
        const TextSelection.collapsed(offset: 9); // fim da linha

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.text, '    x = 1\n    ');
  });

  testWidgets('Enter depois de ":" adiciona um nível de indentação',
      (tester) async {
    final controller = CodeEditingController(text: 'for i in range(3):');
    await pumpEditor(tester, controller);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.text, 'for i in range(3):\n    ');
  });
}
