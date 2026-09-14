import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_text_styles.dart';

/// Editor de código do desafio do dia.
///
/// Três coisas que um campo de texto comum não resolve e que fazem diferença
/// para quem está digitando código num celular:
///
/// 1. **Indentação automática.** O teclado do celular não tem Tab. Sem isso,
///    escrever o corpo de uma função exige encher de espaços na mão, e é onde
///    a maioria desiste. Enter repete a indentação da linha anterior e
///    adiciona um nível quando a linha termina em `:` (ou abre bloco).
/// 2. **Botão de Tab.** Para os casos em que a automática não acerta — sair
///    de um bloco, alinhar uma continuação.
/// 3. **Cor e numeração.** Sem elas o código vira um parágrafo cinza, e erro
///    de digitação passa despercebido.
class CodeEditor extends StatefulWidget {
  final CodeEditingController controller;
  final String language;

  /// Falso só enquanto a resposta está sendo enviada, ou depois de acertar.
  final bool enabled;

  /// Chamado quando a pessoa toca no código com uma resposta errada na tela.
  ///
  /// Depois de errar, o instinto é tocar no próprio código para consertar —
  /// não procurar um botão. Sem isto o toque não fazia nada e o editor
  /// parecia travado.
  final VoidCallback? onEditAfterResult;

  const CodeEditor({
    super.key,
    required this.controller,
    required this.language,
    required this.enabled,
    this.onEditAfterResult,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  static const _indent = '    '; // 4 espaços, como o padrão de Python
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  /// Entrar no campo com uma resposta errada na tela limpa o resultado.
  ///
  /// Um `GestureDetector` em volta do campo não servia: o próprio `TextField`
  /// ganha a disputa de gestos e o `onTapDown` de fora nunca era chamado — o
  /// campo ficava editável, mas o cartão de erro continuava na tela. Foco não
  /// passa por essa disputa.
  void _onFocusChange() {
    if (_focus.hasFocus) widget.onEditAfterResult?.call();
  }

  /// Insere um nível de indentação na posição do cursor.
  void _insertIndent() {
    final value = widget.controller.value;
    final start = value.selection.start;
    if (start < 0) return;
    final text = value.text;
    widget.controller.value = TextEditingValue(
      text: text.replaceRange(start, value.selection.end, _indent),
      selection: TextSelection.collapsed(offset: start + _indent.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1720),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2434)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Toolbar(
            language: widget.language,
            onIndent: widget.enabled ? _insertIndent : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 14, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gutter = 28.0;
                const gap = 10.0;
                final textWidth = constraints.maxWidth - gutter - gap;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: gutter,
                      child: _LineNumbers(
                        controller: widget.controller,
                        textWidth: textWidth,
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: TextField(
                          // Campo já focado não dispara o ouvinte de foco de
                          // novo; o toque cobre esse caso.
                          onTap: widget.onEditAfterResult,
                          controller: widget.controller,
                          focusNode: _focus,
                          enabled: widget.enabled,
                          maxLines: null,
                          minLines: 6,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.none,
                          inputFormatters: [AutoIndentFormatter()],
                          cursorColor: const Color(0xFFB794F6),
                          style: _codeStyle,
                          strutStyle: _codeStrut,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Escreva aqui…',
                            hintStyle: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF6B6480),
                            ),
                          ),
                        ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _codeStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 14,
  height: 1.5,
  color: Color(0xFFF5F3FA),
);

/// Força a mesma altura em toda linha, no campo e na coluna de números. Sem
/// isso um caractere mais alto (acento, emoji) empurra a linha e a numeração
/// desalinha.
const _codeStrut = StrutStyle(
  fontFamily: 'monospace',
  fontSize: 14,
  height: 1.5,
  forceStrutHeight: true,
);

double get _rowHeight => _codeStyle.fontSize! * _codeStyle.height!;

class _Toolbar extends StatelessWidget {
  final String language;
  final VoidCallback? onIndent;

  const _Toolbar({required this.language, required this.onIndent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.code_rounded, size: 15, color: Color(0xFF8A8398)),
          const SizedBox(width: 6),
          Text(
            language.isEmpty ? 'Seu código' : language,
            style: AppTextStyles.bodySmall
                .copyWith(color: const Color(0xFF8A8398)),
          ),
          const Spacer(),
          // O teclado do celular não tem Tab; sem este botão, indentar à mão
          // é contar espaços.
          TextButton.icon(
            onPressed: onIndent,
            icon: const Icon(Icons.keyboard_tab_rounded, size: 16),
            label: const Text('Tab'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB794F6),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                  fontFamily: 'monospace', fontSize: 12, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coluna de números de linha, acompanhando o texto digitado.
///
/// Uma linha de código longa quebra em várias linhas na tela do celular. A
/// numeração conta linhas de código, não de tela: o número aparece só na
/// primeira parte, e as continuações ficam em branco — como no VS Code com
/// quebra automática. Contar só os `\n` deixava o número atrasado a partir da
/// primeira quebra.
class _LineNumbers extends StatelessWidget {
  final TextEditingController controller;

  /// Largura disponível para o texto, para medir onde cada linha quebra.
  final double textWidth;

  const _LineNumbers({required this.controller, required this.textWidth});

  /// Quantas linhas de tela uma linha de código ocupa nessa largura.
  int _visualRows(String line) {
    final painter = TextPainter(
      text: TextSpan(text: line.isEmpty ? ' ' : line, style: _codeStyle),
      strutStyle: _codeStrut,
      textDirection: TextDirection.ltr,
    )
      // O campo reserva a largura do cursor mais 1px antes de quebrar.
      ..layout(maxWidth: (textWidth - 3).clamp(1, double.infinity));
    final rows = painter.computeLineMetrics().length;
    painter.dispose();
    return rows < 1 ? 1 : rows;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final codeLines = value.text.split('\n');
        final children = <Widget>[];
        for (var i = 0; i < codeLines.length; i++) {
          final rows = _visualRows(codeLines[i]);
          for (var r = 0; r < rows; r++) {
            children.add(_number(r == 0 ? '${i + 1}' : '', filled: true));
          }
        }
        // Mínimo de 6 linhas de tela, igual ao `minLines` do campo, para a
        // coluna não encolher com o editor vazio.
        var next = codeLines.length + 1;
        while (children.length < 6) {
          children.add(_number('${next++}', filled: false));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: children,
        );
      },
    );
  }

  Widget _number(String label, {required bool filled}) {
    return SizedBox(
      height: _rowHeight,
      child: Text(
        label,
        strutStyle: _codeStrut,
        style: _codeStyle.copyWith(
          color: filled ? const Color(0xFF5C5470) : const Color(0xFF332D42),
        ),
      ),
    );
  }
}

/// Controlador que colore o código enquanto é digitado.
///
/// O destaque é deliberadamente genérico: o app ensina 16 linguagens, e mais
/// vale um conjunto de palavras-chave que acerta na maioria do que um
/// analisador por linguagem que precisa ser mantido dezesseis vezes.
class CodeEditingController extends TextEditingController {
  CodeEditingController({super.text});

  static final _keywords = RegExp(
    r'\b(def|class|return|if|elif|else|for|while|in|not|and|or|import|from|as|'
    r'try|except|finally|with|lambda|pass|break|continue|yield|global|'
    r'function|var|let|const|new|this|typeof|instanceof|=>|async|await|'
    r'public|private|protected|static|void|int|float|double|bool|boolean|'
    r'string|char|struct|enum|interface|extends|implements|package|'
    r'select|from|where|order|group|by|join|insert|update|delete|values|'
    r'true|false|null|none|nil|undefined|self|print|echo|puts|console)\b',
    caseSensitive: false,
  );
  static final _strings = RegExp(r'''("[^"\n]*"|'[^'\n]*')''');
  static final _numbers = RegExp(r'\b\d+(\.\d+)?\b');
  static final _comments = RegExp(r'(#[^\n]*|//[^\n]*)');

  static const _kwColor = Color(0xFFC792EA);
  static const _strColor = Color(0xFFC3E88D);
  static const _numColor = Color(0xFFF78C6C);
  static const _cmtColor = Color(0xFF6B6480);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    if (text.isEmpty) return TextSpan(text: text, style: base);

    // Um passe só: cada trecho fica com a primeira regra que o reivindicar,
    // na ordem comentário > texto > número > palavra-chave. Sem isso, uma
    // palavra-chave dentro de uma string apareceria colorida.
    final claims = <int, ({int end, Color color})>{};
    void claim(RegExp re, Color color) {
      for (final m in re.allMatches(text)) {
        final overlaps = claims.entries.any(
          (e) => m.start < e.value.end && e.key < m.end,
        );
        if (!overlaps) claims[m.start] = (end: m.end, color: color);
      }
    }

    claim(_comments, _cmtColor);
    claim(_strings, _strColor);
    claim(_numbers, _numColor);
    claim(_keywords, _kwColor);

    final starts = claims.keys.toList()..sort();
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final start in starts) {
      final c = claims[start]!;
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(start, c.end),
        style: base.copyWith(color: c.color),
      ));
      cursor = c.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return TextSpan(style: base, children: spans);
  }
}

/// Indentação que a próxima linha deve receber, dado o texto até o cursor.
///
/// Repete a indentação da linha atual e acrescenta um nível quando ela abre
/// um bloco — `:` em Python, `{`, `(` ou `[` nas outras. Função pura e
/// separada do widget porque é a regra que mais erra na prática e a única
/// parte do editor que dá para testar sem um aparelho.
String indentForNewLine(String textBeforeCursor, {String indent = '    '}) {
  final lineStart = textBeforeCursor.lastIndexOf('\n') + 1;
  final line = textBeforeCursor.substring(lineStart);
  final current = RegExp(r'^[ \t]*').firstMatch(line)?.group(0) ?? '';
  final opensBlock = RegExp(r'[:{(\[]\s*$').hasMatch(line);
  return '$current${opensBlock ? indent : ''}';
}

/// Indentação automática que funciona com o teclado virtual.
///
/// A primeira versão escutava a tecla Enter como evento de teclado, e o
/// teclado virtual do Android não emite esse evento: ele insere a quebra de
/// linha direto no texto. Num celular de verdade a indentação nunca
/// acontecia. O formatador vê a edição já aplicada, então pega a quebra de
/// linha venha de onde vier — teclado virtual, físico ou colagem de uma
/// linha só.
class AutoIndentFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sel = newValue.selection;
    if (!sel.isValid || !sel.isCollapsed) return newValue;
    final offset = sel.baseOffset;
    if (offset <= 0 || offset > newValue.text.length) return newValue;

    // Só a digitação de exatamente um Enter: a edição trocou a seleção
    // antiga por um único '\n'. Colar um bloco inteiro não é mexido.
    final removed = oldValue.selection.isValid
        ? oldValue.selection.end - oldValue.selection.start
        : 0;
    final grewByOne = newValue.text.length == oldValue.text.length - removed + 1;
    if (!grewByOne || newValue.text[offset - 1] != '\n') return newValue;

    final indent = indentForNewLine(newValue.text.substring(0, offset - 1));
    if (indent.isEmpty) return newValue;

    return TextEditingValue(
      text: newValue.text.replaceRange(offset, offset, indent),
      selection: TextSelection.collapsed(offset: offset + indent.length),
    );
  }
}
