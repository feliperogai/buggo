import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta do editor. Escura de propósito: o resto do app é claro, mas código
/// em tema escuro é o que o aluno vai encontrar em qualquer IDE de verdade.
class _EditorColors {
  static const background = Color(0xFF1B1630);
  static const gutter = Color(0xFF151129);
  static const gutterText = Color(0xFF5C5580);
  static const errorLine = Color(0x33EF4444);

  static const plain = Color(0xFFE6E1FF);
  static const keyword = Color(0xFFC792EA);
  static const string = Color(0xFF9ECE6A);
  static const number = Color(0xFFFF9E64);
  static const comment = Color(0xFF6B6489);
  static const function = Color(0xFF7AA2F7);
}

const _fontSize = 14.0;
const _lineHeight = 1.45;

// A família muda por plataforma; "monospace" resolve no Android, e o
// fallback cobre desktop. Fonte do google_fonts foi evitada aqui de
// propósito: ela baixa em runtime, e o editor precisa funcionar offline.
const _monoFamily = 'monospace';
const _monoFallback = ['Roboto Mono', 'Consolas', 'Menlo', 'Courier New'];

/// Palavras-chave de Python e das linguagens em C-like que o app ensina.
/// Uma lista só: destacar `function` num arquivo Python não atrapalha, e
/// evita manter um dicionário por linguagem.
const _keywords = {
  'and', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch', 'class',
  'const', 'continue', 'def', 'del', 'do', 'elif', 'else', 'except', 'False',
  'final', 'finally', 'float', 'for', 'from', 'function', 'global', 'if',
  'import', 'in', 'int', 'is', 'lambda', 'let', 'new', 'None', 'nonlocal',
  'not', 'null', 'or', 'pass', 'print', 'raise', 'return', 'self', 'static',
  'str', 'switch', 'this', 'True', 'try', 'var', 'void', 'while', 'with',
  'yield',
};

/// Controller que pinta a sintaxe enquanto o aluno digita.
///
/// O destaque é por regex e deliberadamente simples — ele existe para o
/// código ficar legível, não para ser um parser correto. Um erro de
/// coloração nunca deve impedir alguém de escrever.
class CodeEditingController extends TextEditingController {
  CodeEditingController({super.text});

  static final _pattern = RegExp(
    // Comentário (# ou //) | string com aspas simples/duplas | número | palavra
    r'(#[^\n]*|//[^\n]*)|("(?:[^"\\\n]|\\.)*"|' r"'(?:[^'\\\n]|\\.)*')"
    r'|(\b\d+(?:\.\d+)?\b)|(\b[A-Za-z_]\w*\b)',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = (style ?? const TextStyle()).copyWith(
      color: _EditorColors.plain,
    );
    final spans = <TextSpan>[];
    var index = 0;

    for (final match in _pattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start), style: base));
      }

      final value = match[0]!;
      Color? color;
      if (match[1] != null) {
        color = _EditorColors.comment;
      } else if (match[2] != null) {
        color = _EditorColors.string;
      } else if (match[3] != null) {
        color = _EditorColors.number;
      } else if (_keywords.contains(value)) {
        color = _EditorColors.keyword;
      } else {
        // Nome seguido de "(" é chamada de função — pinta diferente sem
        // precisar entender o código.
        final after = match.end < text.length ? text[match.end] : '';
        if (after == '(') color = _EditorColors.function;
      }

      spans.add(TextSpan(
        text: value,
        style: color == null ? base : base.copyWith(color: color),
      ));
      index = match.end;
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index), style: base));
    }
    return TextSpan(style: base, children: spans);
  }
}

/// Editor de código com numeração de linhas, destaque de sintaxe e marcação
/// da linha apontada pela correção.
class CodeEditor extends StatefulWidget {
  final CodeEditingController controller;
  final bool readOnly;

  /// Linha (1-indexada) que a IA apontou como origem do erro. Fica destacada
  /// até o aluno editar o código.
  final int? errorLine;

  const CodeEditor({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.errorLine,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  final _scroll = ScrollController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// Enter mantém a indentação da linha anterior e adiciona um nível depois
  /// de ":" — sem isso, escrever um `for` em Python no celular é sofrível.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final controller = widget.controller;
    final selection = controller.selection;
    if (!selection.isValid) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _insert('    ');
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final upToCursor = controller.text.substring(0, selection.start);
      final lineStart = upToCursor.lastIndexOf('\n') + 1;
      final currentLine = upToCursor.substring(lineStart);
      final indent = RegExp(r'^[ \t]*').firstMatch(currentLine)?.group(0) ?? '';
      final extra = currentLine.trimRight().endsWith(':') ? '    ' : '';
      _insert('\n$indent$extra');
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _insert(String value) {
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;
    final newText =
        text.replaceRange(selection.start, selection.end, value);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(widget.controller.text).length + 1;
    const textStyle = TextStyle(
      fontFamily: _monoFamily,
      fontFamilyFallback: _monoFallback,
      fontSize: _fontSize,
      height: _lineHeight,
      color: _EditorColors.plain,
    );

    return Container(
      decoration: BoxDecoration(
        color: _EditorColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        controller: _scroll,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Gutter(
                lineCount: lineCount,
                errorLine: widget.errorLine,
                textStyle: textStyle,
              ),
              Expanded(
                child: Stack(
                  children: [
                    if (widget.errorLine != null)
                      Positioned(
                        top: (widget.errorLine! - 1) *
                            _fontSize *
                            _lineHeight,
                        left: 0,
                        right: 0,
                        height: _fontSize * _lineHeight,
                        child: Container(color: _EditorColors.errorLine),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
                      child: Focus(
                        focusNode: _focus,
                        onKeyEvent: _onKey,
                        child: TextField(
                          controller: widget.controller,
                          readOnly: widget.readOnly,
                          maxLines: null,
                          expands: false,
                          style: textStyle,
                          cursorColor: _EditorColors.plain,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.none,
                          // Corretor automático em campo de código
                          // transforma "def" em "deu" e enlouquece o aluno.
                          autocorrect: false,
                          enableSuggestions: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: '# escreva sua solução aqui',
                            hintStyle: TextStyle(
                              fontFamily: _monoFamily,
                              fontFamilyFallback: _monoFallback,
                              fontSize: _fontSize,
                              height: _lineHeight,
                              color: _EditorColors.comment,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gutter extends StatelessWidget {
  final int lineCount;
  final int? errorLine;
  final TextStyle textStyle;

  const _Gutter({
    required this.lineCount,
    required this.errorLine,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _EditorColors.gutter,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(lineCount, (i) {
          final isError = errorLine != null && errorLine == i + 1;
          return Text(
            '${i + 1}',
            style: textStyle.copyWith(
              color: isError ? const Color(0xFFEF4444) : _EditorColors.gutterText,
              fontWeight: isError ? FontWeight.w700 : FontWeight.w400,
            ),
          );
        }),
      ),
    );
  }
}
