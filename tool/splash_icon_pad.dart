// One-off helper: builds a heavily-padded version of the Buggo icon for the
// Android 12+ system splash screen, which masks the icon into a circle.
// The launcher icon (ic_launcher_foreground, 16% inset) fits fine in the
// gentler adaptive-icon squircle, but a circle crops much more — so the
// splash icon needs extra margin so nothing (antennae, code brackets) gets
// clipped.
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const srcPath = 'assets/images/icon_buggo.png';
  const outPath =
      'android/app/src/main/res/drawable/splash_icon.png';
  final source = img.decodePng(File(srcPath).readAsBytesSync())!;

  // Content currently fills ~100% of the square; scale it down to ~55% and
  // center it on a transparent canvas the same size as the source.
  const contentFraction = 0.55;
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

  File(outPath).writeAsBytesSync(img.encodePng(canvas));
  print('Padded splash icon written: ${source.width}x${source.height} '
      '(content ${contentSize}x$contentSize)');
}
