import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Google's button, following their branding rules: white surface, neutral
/// border, and the four-colour G. Drawn in code so there is no image asset
/// to ship or to go missing in a release build.
class GoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GoogleButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleG(size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF3C4043),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// O "G" oficial do Google, desenhado a partir dos quatro paths do logo
/// (viewBox 48x48) em vez de aproximado com arcos — a versão anterior saía
/// como uma bolha colorida que não lia como o logo.
///
/// Desenhado em código, e não como asset de imagem, para não haver arquivo
/// para faltar num build de release.
class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleGPainter());
}

class _GoogleGPainter extends CustomPainter {
  // Paths do logo oficial, na ordem azul / verde / amarelo / vermelho.
  static const _paths = <(int, String)>[
    (
      0xFF4285F4,
      'M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 '
          '6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z'
    ),
    (
      0xFF34A853,
      'M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.1-7.45 '
          '2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 46 24 46z'
    ),
    (
      0xFFFBBC05,
      'M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 '
          '17.09 2 20.45 2 24s.85 6.91 2.34 9.88l7.35-5.7z'
    ),
    (
      0xFFEA4335,
      'M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 '
          '15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z'
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48.0, size.height / 48.0);
    for (final (color, data) in _paths) {
      canvas.drawPath(
        _parseSvgPath(data),
        Paint()
          ..color = Color(color)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final _numberPattern = RegExp(r'-?\d*\.?\d+(?:[eE][-+]?\d+)?');

/// Parser mínimo de path SVG: só os comandos usados pelo logo do Google
/// (M/m, L/l, H/h, V/v, C/c, S/s, Z/z). Não tenta ser um parser completo.
Path _parseSvgPath(String data) {
  final path = Path();
  double cx = 0, cy = 0; // ponto atual
  double sx = 0, sy = 0; // início do subpath, para o Z
  double? lastC1x, lastC1y; // controle anterior, para o S
  var i = 0;
  String? command;

  List<double> readNumbers(int count) {
    final values = <double>[];
    while (values.length < count) {
      while (i < data.length && (data[i] == ' ' || data[i] == ',')) {
        i++;
      }
      final match = _numberPattern.matchAsPrefix(data, i);
      if (match == null) break;
      values.add(double.parse(match.group(0)!));
      i = match.end;
    }
    return values;
  }

  while (i < data.length) {
    final char = data[i];
    if (char == ' ' || char == ',') {
      i++;
      continue;
    }
    if (RegExp(r'[A-Za-z]').hasMatch(char)) {
      command = char;
      i++;
    }
    if (command == null) break;

    final relative = command == command.toLowerCase();
    switch (command.toUpperCase()) {
      case 'M':
        final v = readNumbers(2);
        if (v.length < 2) return path;
        cx = relative ? cx + v[0] : v[0];
        cy = relative ? cy + v[1] : v[1];
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        lastC1x = lastC1y = null;
        // Coordenadas extras depois de um M viram L, como manda o SVG.
        command = relative ? 'l' : 'L';
      case 'L':
        final v = readNumbers(2);
        if (v.length < 2) return path;
        cx = relative ? cx + v[0] : v[0];
        cy = relative ? cy + v[1] : v[1];
        path.lineTo(cx, cy);
        lastC1x = lastC1y = null;
      case 'H':
        final v = readNumbers(1);
        if (v.isEmpty) return path;
        cx = relative ? cx + v[0] : v[0];
        path.lineTo(cx, cy);
        lastC1x = lastC1y = null;
      case 'V':
        final v = readNumbers(1);
        if (v.isEmpty) return path;
        cy = relative ? cy + v[0] : v[0];
        path.lineTo(cx, cy);
        lastC1x = lastC1y = null;
      case 'C':
        final v = readNumbers(6);
        if (v.length < 6) return path;
        final x1 = relative ? cx + v[0] : v[0];
        final y1 = relative ? cy + v[1] : v[1];
        final x2 = relative ? cx + v[2] : v[2];
        final y2 = relative ? cy + v[3] : v[3];
        cx = relative ? cx + v[4] : v[4];
        cy = relative ? cy + v[5] : v[5];
        path.cubicTo(x1, y1, x2, y2, cx, cy);
        lastC1x = x2;
        lastC1y = y2;
      case 'S':
        final v = readNumbers(4);
        if (v.length < 4) return path;
        // O primeiro controle é o reflexo do controle anterior.
        final x1 = lastC1x == null ? cx : 2 * cx - lastC1x;
        final y1 = lastC1y == null ? cy : 2 * cy - lastC1y;
        final x2 = relative ? cx + v[0] : v[0];
        final y2 = relative ? cy + v[1] : v[1];
        cx = relative ? cx + v[2] : v[2];
        cy = relative ? cy + v[3] : v[3];
        path.cubicTo(x1, y1, x2, y2, cx, cy);
        lastC1x = x2;
        lastC1y = y2;
      case 'Z':
        path.close();
        cx = sx;
        cy = sy;
        lastC1x = lastC1y = null;
      default:
        return path;
    }
  }
  return path;
}
