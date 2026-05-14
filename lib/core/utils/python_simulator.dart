/// A minimal Python interpreter for the code-fill challenges.
/// Supports: assignment, print, if/elif/else, for+range, def+call.
class PythonSimulator {
  final _vars = <String, dynamic>{};
  final _funcs = <String, _Func>{};
  final _out = <String>[];

  String simulate(String code) {
    _vars.clear();
    _funcs.clear();
    _out.clear();
    _execBlock(code.split('\n'), 0, 0);
    return _out.join('\n');
  }

  // ── Block execution ──────────────────────────────────────────
  // Returns index of first line AFTER this block.
  int _execBlock(List<String> lines, int start, int baseIndent) {
    int i = start;
    while (i < lines.length) {
      final raw = lines[i];
      final t = raw.trimLeft();
      if (t.isEmpty || t.startsWith('#')) { i++; continue; }
      final ind = _indent(raw);
      if (ind < baseIndent) return i;   // exiting block
      if (ind > baseIndent) { i++; continue; } // skip deeper

      if (t.startsWith('def ')) {
        i = _parseDef(lines, i, ind);
      } else if (t.startsWith('for ')) {
        i = _execFor(lines, i, ind);
      } else if (t.startsWith('if ')) {
        i = _execIf(lines, i, ind);
      } else {
        _execStmt(t);
        i++;
      }
    }
    return i;
  }

  // ── Statements ───────────────────────────────────────────────
  void _execStmt(String s) {
    s = s.trim();
    if (s.isEmpty || s.startsWith('#')) return;

    // print(...)
    if (s.startsWith('print(') && s.endsWith(')')) {
      final inner = s.substring(6, s.length - 1);
      _out.add(_fmtPrint(inner));
      return;
    }

    // Assignment: look for a single = not part of ==, !=, >=, <=
    final eqIdx = _findAssignEq(s);
    if (eqIdx > 0) {
      final name = s.substring(0, eqIdx).trim();
      final expr = s.substring(eqIdx + 1).trim();
      if (RegExp(r'^\w+$').hasMatch(name)) {
        _vars[name] = _eval(expr);
        return;
      }
    }

    // Bare function call: name(args)
    final callM = RegExp(r'^(\w+)\((.*)\)$').firstMatch(s);
    if (callM != null) {
      _callFunc(callM.group(1)!, callM.group(2) ?? '');
    }
  }

  int _findAssignEq(String s) {
    for (int i = 1; i < s.length; i++) {
      if (s[i] == '=' &&
          (i == 0 || (s[i - 1] != '!' && s[i - 1] != '<' &&
              s[i - 1] != '>' && s[i - 1] != '=')) &&
          (i + 1 >= s.length || s[i + 1] != '=')) {
        return i;
      }
    }
    return -1;
  }

  // ── Function definition ──────────────────────────────────────
  int _parseDef(List<String> lines, int start, int baseIndent) {
    final m = RegExp(r'def (\w+)\(([^)]*)\):').firstMatch(lines[start].trim());
    if (m == null) throw SimulatorError('SyntaxError: invalid def');
    final params = m.group(2)!
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final bodyIndent = baseIndent + 4;
    int end = start + 1;
    while (end < lines.length) {
      final t = lines[end].trimLeft();
      if (t.isNotEmpty && !t.startsWith('#') && _indent(lines[end]) < bodyIndent) break;
      end++;
    }
    _funcs[m.group(1)!] = _Func(params, lines.sublist(start + 1, end), bodyIndent);
    return end;
  }

  void _callFunc(String name, String argsStr) {
    final fn = _funcs[name];
    if (fn == null) throw SimulatorError("NameError: name '$name' is not defined");
    final args = _splitArgs(argsStr).map((a) => _eval(a.trim())).toList();
    final saved = Map<String, dynamic>.from(_vars);
    for (int i = 0; i < fn.params.length && i < args.length; i++) {
      _vars[fn.params[i]] = args[i];
    }
    _execBlock(fn.body, 0, fn.indent);
    _vars
      ..clear()
      ..addAll(saved);
  }

  // ── For loop ─────────────────────────────────────────────────
  int _execFor(List<String> lines, int start, int baseIndent) {
    final m = RegExp(r'for (\w+) in (.+):').firstMatch(lines[start].trim());
    if (m == null) throw SimulatorError('SyntaxError: invalid for');
    final varName = m.group(1)!;
    final iterVal = _eval(m.group(2)!.trim());

    List items;
    if (iterVal is List) {
      items = iterVal;
    } else {
      throw SimulatorError("TypeError: '${m.group(2)}' is not iterable");
    }

    final bodyIndent = baseIndent + 4;
    int end = start + 1;
    while (end < lines.length) {
      final t = lines[end].trimLeft();
      if (t.isNotEmpty && !t.startsWith('#') && _indent(lines[end]) < bodyIndent) break;
      end++;
    }
    final body = lines.sublist(start + 1, end);

    for (final item in items) {
      _vars[varName] = item;
      _execBlock(body, 0, bodyIndent);
    }
    return end;
  }

  // ── If / elif / else ─────────────────────────────────────────
  int _execIf(List<String> lines, int start, int baseIndent) {
    final blockIndent = baseIndent + 4;
    bool executed = false;
    int i = start;

    while (i < lines.length) {
      final raw = lines[i];
      final t = raw.trimLeft();
      if (t.isEmpty || t.startsWith('#')) { i++; continue; }
      final ind = _indent(raw);
      if (ind < baseIndent) return i;
      if (ind > baseIndent) { i++; continue; }

      // Find body end for current clause
      int bodyEnd = i + 1;
      while (bodyEnd < lines.length) {
        final bt = lines[bodyEnd].trimLeft();
        if (bt.isNotEmpty && !bt.startsWith('#') && _indent(lines[bodyEnd]) < blockIndent) break;
        bodyEnd++;
      }

      if (t.startsWith('if ') || t.startsWith('elif ')) {
        final kw = t.startsWith('if ') ? 'if' : 'elif';
        final condEnd = t.lastIndexOf(':');
        if (condEnd < 0) throw SimulatorError('SyntaxError: missing colon in $kw');
        final condExpr = t.substring(kw.length + 1, condEnd).trim();
        if (!executed && condExpr.isNotEmpty && _evalCond(condExpr)) {
          _execBlock(lines.sublist(i + 1, bodyEnd), 0, blockIndent);
          executed = true;
        }
        i = bodyEnd;
      } else if (t == 'else:') {
        if (!executed) {
          _execBlock(lines.sublist(i + 1, bodyEnd), 0, blockIndent);
        }
        return bodyEnd;
      } else {
        return i; // not part of this if chain
      }
    }
    return i;
  }

  // ── Expression evaluator ─────────────────────────────────────
  dynamic _eval(String expr) {
    expr = expr.trim();
    if (expr.isEmpty) return null;

    // String literal
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr.substring(1, expr.length - 1);
    }

    // Bool / None
    if (expr == 'True') return true;
    if (expr == 'False') return false;
    if (expr == 'None') return null;

    // Number
    final n = num.tryParse(expr);
    if (n != null) return n is double && n == n.truncateToDouble() ? n.toInt() : n;

    // range(n) or range(a, b)
    if (expr.startsWith('range(') && expr.endsWith(')')) {
      final inner = expr.substring(6, expr.length - 1);
      final parts = inner.split(',').map((p) => int.tryParse(p.trim()) ?? 0).toList();
      if (parts.length == 1) return List.generate(parts[0].clamp(0, 200), (i) => i);
      if (parts.length == 2) {
        return List.generate((parts[1] - parts[0]).clamp(0, 200), (i) => i + parts[0]);
      }
      return <int>[];
    }

    // len(), str(), int()
    if (expr.startsWith('len(') && expr.endsWith(')')) {
      final inner = _eval(expr.substring(4, expr.length - 1));
      if (inner is List) return inner.length;
      if (inner is String) return inner.length;
      throw SimulatorError('TypeError: object has no len()');
    }
    if (expr.startsWith('str(') && expr.endsWith(')')) {
      return _str(_eval(expr.substring(4, expr.length - 1)));
    }
    if (expr.startsWith('int(') && expr.endsWith(')')) {
      final v = _eval(expr.substring(4, expr.length - 1));
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // Binary operators (left-to-right: search right-to-left for lowest precedence)
    for (final op in [' + ', ' - ']) {
      final idx = _findOp(expr, op);
      if (idx >= 0) {
        final l = _eval(expr.substring(0, idx));
        final r = _eval(expr.substring(idx + op.length));
        return _applyOp(l, r, op.trim());
      }
    }
    for (final op in [' * ', ' / ', ' % ']) {
      final idx = _findOp(expr, op);
      if (idx >= 0) {
        final l = _eval(expr.substring(0, idx));
        final r = _eval(expr.substring(idx + op.length));
        return _applyOp(l, r, op.trim());
      }
    }

    // Variable
    if (_vars.containsKey(expr)) return _vars[expr];

    // Unknown function call → descriptive error
    if (RegExp(r'^\w+\(').hasMatch(expr)) {
      final fn = expr.substring(0, expr.indexOf('('));
      throw SimulatorError("NameError: name '$fn' is not defined");
    }

    throw SimulatorError("NameError: name '$expr' is not defined");
  }

  // Find RIGHTMOST occurrence of [op] not inside strings/parens
  int _findOp(String expr, String op) {
    bool inStr = false;
    String q = '';
    int depth = 0;
    int last = -1;
    for (int i = 0; i <= expr.length - op.length; i++) {
      final c = expr[i];
      if (!inStr && (c == '"' || c == "'")) { inStr = true; q = c; }
      else if (inStr && c == q) inStr = false;
      else if (!inStr) {
        if (c == '(') depth++;
        else if (c == ')') depth--;
        else if (depth == 0 && expr.substring(i, i + op.length) == op) {
          last = i;
        }
      }
    }
    return last;
  }

  dynamic _applyOp(dynamic l, dynamic r, String op) {
    if (l is num && r is num) {
      num result;
      switch (op) {
        case '+': result = l + r; break;
        case '-': result = l - r; break;
        case '*': result = l * r; break;
        case '/':
          if (r == 0) throw SimulatorError('ZeroDivisionError: division by zero');
          result = l / r; break;
        case '%':
          if (r == 0) throw SimulatorError('ZeroDivisionError: modulo by zero');
          result = l % r; break;
        default: throw SimulatorError('TypeError: unsupported op $op');
      }
      return result is double && result == result.truncateToDouble()
          ? result.toInt() : result;
    }
    if (op == '+') return '${_str(l)}${_str(r)}';
    throw SimulatorError('TypeError: unsupported operand types for $op');
  }

  // ── Condition evaluator ───────────────────────────────────────
  bool _evalCond(String cond) {
    for (final op in ['>=', '<=', '!=', '==', '>', '<']) {
      final idx = cond.indexOf(' $op ');
      if (idx < 0) continue;
      final l = _eval(cond.substring(0, idx).trim());
      final r = _eval(cond.substring(idx + op.length + 2).trim());
      switch (op) {
        case '>=': return _cmp(l, r) >= 0;
        case '<=': return _cmp(l, r) <= 0;
        case '>':  return _cmp(l, r) > 0;
        case '<':  return _cmp(l, r) < 0;
        case '==': return l == r;
        case '!=': return l != r;
      }
    }
    // Boolean variable
    final v = _eval(cond);
    return v == true || (v is num && v != 0) || (v is String && v.isNotEmpty);
  }

  int _cmp(dynamic a, dynamic b) {
    if (a is num && b is num) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }

  // ── Print formatter ───────────────────────────────────────────
  String _fmtPrint(String inner) {
    return _splitArgs(inner).map((a) => _str(_eval(a.trim()))).join(' ');
  }

  // ── Helpers ───────────────────────────────────────────────────
  int _indent(String line) {
    int n = 0;
    for (final c in line.runes) {
      if (c == 32) n++;
      else if (c == 9) n += 4;
      else break;
    }
    return n;
  }

  String _str(dynamic v) {
    if (v == null) return 'None';
    if (v is bool) return v ? 'True' : 'False';
    return v.toString();
  }

  List<String> _splitArgs(String s) {
    final result = <String>[];
    int depth = 0;
    bool inStr = false;
    String q = '';
    int start = 0;
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      if (!inStr && (c == '"' || c == "'")) { inStr = true; q = c; }
      else if (inStr && c == q) inStr = false;
      else if (!inStr) {
        if (c == '(' || c == '[') depth++;
        else if (c == ')' || c == ']') depth--;
        else if (c == ',' && depth == 0) {
          result.add(s.substring(start, i));
          start = i + 1;
        }
      }
    }
    if (start < s.length) result.add(s.substring(start));
    return result.isEmpty ? [s] : result;
  }
}

class _Func {
  final List<String> params;
  final List<String> body;
  final int indent;
  _Func(this.params, this.body, this.indent);
}

class SimulatorError {
  final String message;
  SimulatorError(this.message);
  @override
  String toString() => message;
}
