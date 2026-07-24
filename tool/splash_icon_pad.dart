// One-off helper: builds padded versions of the Buggo icon for contexts that
// crop it into a shape (adaptive icon squircle, Android 12+ splash circle).
// The new source icon (`assets/images/icon_buggo.png`) is a full-bleed
// square with its own background baked in and no transparent margin, so it
// needs shrinking onto a transparent canvas before being used as an
// adaptive-icon foreground or a splash icon — otherwise the mask crops its
// edges (antennae, code brackets).
import 'dart:io';
import 'package:image/image.dart' as img;

void _writePadded(img.Image source, double contentFraction, String outPath) {
  final contentSize = (source.width * contentFraction).round();
  final resizedContent = img.copyResize(
    source,
    width: contentSize,
    height: contentSize,
    interpolation: img.Interpolation.average,
  );

  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final dx = (source.width - contentSize) ~/ 2;
  final dy = (source.height - contentSize) ~/ 2;
  img.compositeImage(canvas, resizedContent, dstX: dx, dstY: dy);

  File(outPath).createSync(recursive: true);
  File(outPath).writeAsBytesSync(img.encodePng(canvas));
  print('Written: $outPath (${source.width}x${source.height}, '
      'content ${contentSize}x$contentSize)');
}

void main() {
  const srcPath = 'assets/images/icon_buggo.png';
  final source = img.decodePng(File(srcPath).readAsBytesSync())!;

  // Adaptive icon foreground (home-screen launcher, squircle/circle mask
  // depending on OEM launcher) — standard safe zone, content ~66%.
  _writePadded(source, 0.66, 'assets/images/icon_buggo_adaptive.png');

  // Android 12+ system splash screen — masked into a circle, which crops
  // more aggressively than the adaptive-icon squircle, so needs more margin.
  _writePadded(
      source, 0.55, 'android/app/src/main/res/drawable/splash_icon.png');
}
