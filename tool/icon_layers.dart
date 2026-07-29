// Builds the Android adaptive-icon layers from `assets/images/icon_buggo.png`.
//
// The source icon is a full-bleed square: a dark purple background with the
// white "</>" glyph on top. Feeding that whole image in as the adaptive-icon
// *foreground* leaves the separate background colour showing as a ring around
// it. So instead we split it into the two layers the format actually wants:
//
//   background -> the icon's own dark purple, as a flat colour (set in
//                 pubspec.yaml), so the masked shape is filled edge to edge
//   foreground -> just the white glyph on transparency, generated here
//
// Run with: dart run tool/icon_layers.dart
import 'dart:io';
import 'package:image/image.dart' as img;

const _srcPath = 'assets/images/icon_buggo.png';
const _foregroundPath = 'assets/images/icon_buggo_foreground.png';

/// Maior bitmap que o `flutter_launcher_icons` precisa gerar a partir do
/// foreground: a adaptive icon em xxxhdpi (432x432). Gerar acima disso não
/// adiciona nitidez — só faz o pipeline ampliar e depois reduzir de novo,
/// que é justamente o que deixa o ícone borrado.
const _largestAndroidForeground = 432;

double _luminance(img.Pixel p) =>
    0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

void main() {
  final source = img.decodePng(File(_srcPath).readAsBytesSync())!;

  // The flat background colour is whatever fills the corners.
  final corner = source.getPixel(0, 0);
  final bgLuma = _luminance(corner);
  final bgHex = '#'
      '${corner.r.toInt().toRadixString(16).padLeft(2, '0')}'
      '${corner.g.toInt().toRadixString(16).padLeft(2, '0')}'
      '${corner.b.toInt().toRadixString(16).padLeft(2, '0')}';

  // Brightest pixel = the glyph colour, used as the far end of the ramp so
  // antialiased edges keep smooth alpha instead of hard-thresholding.
  var maxLuma = bgLuma;
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final l = _luminance(source.getPixel(x, y));
      if (l > maxLuma) maxLuma = l;
    }
  }

  final glyph = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  img.fill(glyph, color: img.ColorRgba8(0, 0, 0, 0));

  var minX = source.width, minY = source.height, maxX = -1, maxY = -1;
  final range = (maxLuma - bgLuma).clamp(1.0, 255.0);

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final p = source.getPixel(x, y);
      // How far this pixel is from the background, 0..1 -> alpha.
      final t = ((_luminance(p) - bgLuma) / range).clamp(0.0, 1.0);
      if (t <= 0.02) continue;
      final alpha = (t * 255).round();
      glyph.setPixel(x, y, img.ColorRgba8(255, 255, 255, alpha));
      if (t > 0.5) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  // Mantém a resolução nativa da fonte. Só amplia se ela for pequena demais
  // para o maior bitmap que o Android precisa — ampliar além disso não cria
  // detalhe, apenas introduz um reamostramento extra (fonte -> ampliação ->
  // redução por densidade) que borra o resultado.
  final img.Image output;
  if (glyph.width < _largestAndroidForeground) {
    output = img.copyResize(
      glyph,
      width: _largestAndroidForeground,
      height: _largestAndroidForeground,
      interpolation: img.Interpolation.cubic,
    );
    print('AVISO: fonte tem só ${source.width}px; ampliada para '
        '$_largestAndroidForeground px e o ícone pode sair borrado. '
        'Use uma imagem de 512px ou mais.');
  } else {
    output = glyph;
  }

  File(_foregroundPath).writeAsBytesSync(img.encodePng(output));

  final glyphFraction =
      ((maxX - minX + 1) / source.width * 100).toStringAsFixed(0);
  print('Cor de fundo (use como adaptive_icon_background): $bgHex');
  print('Glifo ocupa ~$glyphFraction% do quadrado da fonte');
  print('Gerado: $_foregroundPath (${output.width}x${output.height})');
}
