import 'package:buggo/features/daily/presentation/widgets/code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O teclado do celular não tem Tab. Sem indentação automática, escrever o
/// corpo de uma função exige contar espaços na mão — é onde a maioria desiste.
void main() {
  group('indentação automática', () {
    test('primeira linha começa sem indentação', () {
      expect(indentForNewLine(''), '');
      expect(indentForNewLine('x = 1'), '');
    });

    test('repete a indentação da linha atual', () {
      expect(indentForNewLine('def f():\n    x = 1'), '    ');
      expect(indentForNewLine('a\n        y = 2'), '        ');
    });

    test('aprofunda um nível depois de dois-pontos', () {
      expect(indentForNewLine('def saudacao():'), '    ');
      expect(indentForNewLine('    if x > 1:'), '        ');
    });

    test('aprofunda depois de abrir chave, parêntese ou colchete', () {
      expect(indentForNewLine('function f() {'), '    ');
      expect(indentForNewLine('lista = ['), '    ');
      expect(indentForNewLine('soma('), '    ');
    });

    test('espaço em branco depois do abre-bloco não atrapalha', () {
      expect(indentForNewLine('def f():   '), '    ');
    });

    test('dois-pontos no meio da linha não abre bloco', () {
      // Dicionário em Python: a linha não termina em ':'.
      expect(indentForNewLine("d = {'a': 1}"), '');
    });

    test('sai do bloco quando a linha anterior não indentava', () {
      expect(indentForNewLine('def f():\n    return 1\nprint(f())'), '');
    });
  });

  group('formatador de indentação (teclado virtual)', () {
    TextEditingValue typed(String before, String after) => TextEditingValue(
          text: after,
          selection: TextSelection.collapsed(offset: after.length),
        );
    TextEditingValue at(String text) => TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );

    final f = AutoIndentFormatter();

    test('Enter depois de dois-pontos indenta a próxima linha', () {
      final out = f.formatEditUpdate(at('def f():'), typed('', 'def f():\n'));
      expect(out.text, 'def f():\n    ');
      expect(out.selection.baseOffset, out.text.length);
    });

    test('Enter no meio de bloco mantém a indentação', () {
      const before = 'if x:\n    a = 1';
      final out = f.formatEditUpdate(at(before), typed('', '$before\n'));
      expect(out.text, '$before\n    ');
    });

    test('Enter numa linha sem indentação não acrescenta nada', () {
      final out = f.formatEditUpdate(at('x = 1'), typed('', 'x = 1\n'));
      expect(out.text, 'x = 1\n');
    });

    test('digitar uma letra não é afetado', () {
      final out = f.formatEditUpdate(at('def f():'), typed('', 'def f():a'));
      expect(out.text, 'def f():a');
    });

    test('colar várias linhas não é mexido', () {
      final out = f.formatEditUpdate(at('x'), typed('', 'x\n  y\n  z'));
      expect(out.text, 'x\n  y\n  z');
    });
  });

  group('destaque de sintaxe', () {
    TextSpan spanOf(String code) {
      final c = CodeEditingController(text: code);
      return c.buildTextSpan(
        context: _FakeContext(),
        style: const TextStyle(),
        withComposing: false,
      );
    }

    test('o texto colorido é idêntico ao digitado', () {
      const code = 'def f():\n    print("oi")  # nota\n';
      expect(spanOf(code).toPlainText(), code);
    });

    test('campo vazio não quebra', () {
      expect(spanOf('').toPlainText(), '');
    });

    test('palavra-chave dentro de texto não é colorida como palavra-chave', () {
      // Sem isso, o "for" dentro da string apareceria roxo.
      final span = spanOf('x = "for"');
      final colors = <Color?>[];
      span.visitChildren((s) {
        if (s is TextSpan && s.text != null) colors.add(s.style?.color);
        return true;
      });
      // Um único trecho colorido: a string inteira.
      expect(colors.where((c) => c != null).length, 1);
    });
  });
}

class _FakeContext extends StatelessElement {
  _FakeContext() : super(const _FakeWidget());
}

class _FakeWidget extends StatelessWidget {
  const _FakeWidget();
  @override
  Widget build(BuildContext context) => const SizedBox();
}
