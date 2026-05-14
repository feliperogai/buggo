import 'dart:io';
import 'package:flutter/material.dart';

class PixelAvatarData {
  final String name;
  final List<List<String>> grid; // 10 × 10
  final Map<String, Color> palette;
  final Color backgroundColor;

  const PixelAvatarData(
      this.name, this.grid, this.palette, this.backgroundColor);
}

// ── Avatar grids (10 × 10) ─────────────────────────────────────
// '.' = transparent (backgroundColor shows through)

// 1 · Robot ─ indigo border, silver body, amber LEDs
const _robotGrid = [
  ['I', 'I', 'I', 'I', 'I', 'I', 'I', 'I', 'I', 'I'],
  ['I', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'I'],
  ['I', 'M', 'E', 'E', 'M', 'M', 'E', 'E', 'M', 'I'],
  ['I', 'M', 'E', 'B', 'M', 'M', 'B', 'E', 'M', 'I'],
  ['I', 'M', 'E', 'E', 'M', 'M', 'E', 'E', 'M', 'I'],
  ['I', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'I'],
  ['I', 'M', 'Y', 'M', 'M', 'M', 'M', 'Y', 'M', 'I'],
  ['I', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'I'],
  ['I', 'M', 'M', 'S', 'S', 'S', 'S', 'M', 'M', 'I'],
  ['I', 'I', 'I', 'I', 'I', 'I', 'I', 'I', 'I', 'I'],
];
const _robotPal = <String, Color>{
  'I': Color(0xFF4338CA),
  'M': Color(0xFFB0BEC5),
  'E': Color(0xFFFFFFFF),
  'B': Color(0xFF1E40AF),
  'Y': Color(0xFFF59E0B),
  'S': Color(0xFF374151),
};

// 2 · Panda ─ black patches, white face, pink nose
const _pandaGrid = [
  ['.', 'B', 'B', '.', '.', '.', '.', 'B', 'B', '.'],
  ['B', 'B', 'W', 'W', 'W', 'W', 'W', 'W', 'B', 'B'],
  ['B', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'B'],
  ['B', 'W', 'K', 'K', 'W', 'W', 'K', 'K', 'W', 'B'],
  ['B', 'W', 'K', 'W', 'W', 'W', 'W', 'K', 'W', 'B'],
  ['B', 'W', 'K', 'K', 'W', 'W', 'K', 'K', 'W', 'B'],
  ['B', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'B'],
  ['B', 'W', 'W', 'P', 'W', 'W', 'W', 'W', 'W', 'B'],
  ['.', 'B', 'W', 'W', 'W', 'W', 'W', 'W', 'B', '.'],
  ['.', '.', 'B', 'B', 'B', 'B', 'B', 'B', '.', '.'],
];
const _pandaPal = <String, Color>{
  'B': Color(0xFF212121),
  'W': Color(0xFFF0F0F0),
  'K': Color(0xFF1A1A1A),
  'P': Color(0xFFF48FB1),
};

// 3 · Gato ─ orange tabby, white muzzle, pink nose
const _catGrid = [
  ['O', '.', '.', '.', '.', '.', '.', '.', '.', 'O'],
  ['O', 'O', '.', '.', '.', '.', '.', '.', 'O', 'O'],
  ['.', 'O', 'O', 'O', 'O', 'O', 'O', 'O', 'O', '.'],
  ['O', 'O', 'O', 'O', 'O', 'O', 'O', 'O', 'O', 'O'],
  ['O', 'O', 'W', 'W', 'O', 'O', 'W', 'W', 'O', 'O'],
  ['O', 'O', 'W', 'B', 'O', 'O', 'B', 'W', 'O', 'O'],
  ['O', 'O', 'O', 'O', 'O', 'O', 'O', 'O', 'O', 'O'],
  ['W', 'W', 'O', 'O', 'P', 'O', 'O', 'O', 'W', 'W'],
  ['W', 'W', 'W', 'O', 'O', 'O', 'O', 'W', 'W', 'W'],
  ['.', 'W', 'O', 'O', 'O', 'O', 'O', 'O', 'W', '.'],
];
const _catPal = <String, Color>{
  'O': Color(0xFFFF9800),
  'W': Color(0xFFFFFFFF),
  'B': Color(0xFF212121),
  'P': Color(0xFFEC407A),
};

// 4 · Alien ─ lime green, big white eyes, dark pupils
const _alienGrid = [
  ['.', '.', 'G', 'G', 'G', 'G', 'G', 'G', '.', '.'],
  ['.', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', '.'],
  ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
  ['G', 'G', 'E', 'E', 'G', 'G', 'E', 'E', 'G', 'G'],
  ['G', 'G', 'E', 'B', 'G', 'G', 'B', 'E', 'G', 'G'],
  ['G', 'G', 'E', 'E', 'G', 'G', 'E', 'E', 'G', 'G'],
  ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
  ['G', 'G', 'G', 'D', 'G', 'G', 'D', 'G', 'G', 'G'],
  ['.', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', '.'],
  ['.', '.', 'G', 'G', 'G', 'G', 'G', 'G', '.', '.'],
];
const _alienPal = <String, Color>{
  'G': Color(0xFF76FF03),
  'E': Color(0xFFFFFFFF),
  'B': Color(0xFF1B5E20),
  'D': Color(0xFF33691E),
};

// 5 · Ghost ─ lavender body, dark eyes, wavy bottom
const _ghostGrid = [
  ['.', '.', 'V', 'V', 'V', 'V', 'V', 'V', '.', '.'],
  ['.', 'V', 'V', 'V', 'V', 'V', 'V', 'V', 'V', '.'],
  ['V', 'V', 'V', 'V', 'V', 'V', 'V', 'V', 'V', 'V'],
  ['V', 'V', 'E', 'E', 'V', 'V', 'E', 'E', 'V', 'V'],
  ['V', 'V', 'E', 'B', 'V', 'V', 'B', 'E', 'V', 'V'],
  ['V', 'V', 'E', 'E', 'V', 'V', 'E', 'E', 'V', 'V'],
  ['V', 'V', 'V', 'V', 'V', 'V', 'V', 'V', 'V', 'V'],
  ['V', '.', 'V', '.', 'V', '.', 'V', '.', 'V', '.'],
  ['.', '.', '.', '.', '.', '.', '.', '.', '.', '.'],
  ['.', '.', '.', '.', '.', '.', '.', '.', '.', '.'],
];
const _ghostPal = <String, Color>{
  'V': Color(0xFFBA68C8),
  'E': Color(0xFFFFFFFF),
  'B': Color(0xFF4527A0),
};

// 6 · Urso ─ brown bear with muzzle
const _bearGrid = [
  ['.', 'B', '.', '.', '.', '.', '.', '.', 'B', '.'],
  ['B', 'B', 'L', '.', '.', '.', '.', 'L', 'B', 'B'],
  ['B', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'B'],
  ['B', 'L', 'E', 'E', 'L', 'L', 'E', 'E', 'L', 'B'],
  ['B', 'L', 'E', 'D', 'L', 'L', 'D', 'E', 'L', 'B'],
  ['B', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'B'],
  ['B', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'L', 'B'],
  ['B', 'L', 'M', 'N', 'M', 'M', 'N', 'M', 'L', 'B'],
  ['B', 'L', 'L', 'M', 'M', 'M', 'M', 'L', 'L', 'B'],
  ['.', 'B', 'B', 'L', 'L', 'L', 'L', 'B', 'B', '.'],
];
const _bearPal = <String, Color>{
  'B': Color(0xFF4E342E),
  'L': Color(0xFFA1887F),
  'E': Color(0xFFFFFFFF),
  'D': Color(0xFF1A0A00),
  'M': Color(0xFFFFCCBC),
  'N': Color(0xFF212121),
};

final List<PixelAvatarData> kPixelAvatars = [
  const PixelAvatarData('Robot', _robotGrid, _robotPal, Color(0xFFEEF0FF)),
  const PixelAvatarData('Panda', _pandaGrid, _pandaPal, Color(0xFFFAFAFA)),
  const PixelAvatarData('Gato',  _catGrid,   _catPal,   Color(0xFFFFF8F0)),
  const PixelAvatarData('Alien', _alienGrid, _alienPal, Color(0xFFF1F8E9)),
  const PixelAvatarData('Ghost', _ghostGrid, _ghostPal, Color(0xFFF3E5F5)),
  const PixelAvatarData('Urso',  _bearGrid,  _bearPal,  Color(0xFFEFEBE9)),
];

// ── Painter ────────────────────────────────────────────────────
class _AvatarPainter extends CustomPainter {
  final PixelAvatarData data;
  _AvatarPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final rows = data.grid.length;
    final cols = data.grid[0].length;
    final pw = size.width / cols;
    final ph = size.height / rows;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final k = data.grid[r][c];
        if (k == '.') continue;
        final color = data.palette[k];
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(c * pw, r * ph, pw, ph),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => old.data != data;
}

// ── Public widget ──────────────────────────────────────────────
class PixelAvatar extends StatelessWidget {
  final int avatarIndex;
  final String? customPhotoPath;
  final double size;
  // circular=true → ClipOval (header/profile); false → no clip (caller handles)
  final bool circular;

  const PixelAvatar({
    super.key,
    this.avatarIndex = 0,
    this.customPhotoPath,
    this.size = 80,
    this.circular = true,
    // legacy params kept for compat — ignored
    bool showBorder = false,
    Color? borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (customPhotoPath != null && customPhotoPath!.isNotEmpty) {
      inner = Image.file(
        File(customPhotoPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _pixelWidget(),
      );
    } else {
      inner = _pixelWidget();
    }

    final sized = SizedBox(width: size, height: size, child: inner);
    return circular ? ClipOval(child: sized) : sized;
  }

  Widget _pixelWidget() {
    final idx = avatarIndex.clamp(0, kPixelAvatars.length - 1);
    final data = kPixelAvatars[idx];
    return ColoredBox(
      color: data.backgroundColor,
      child: CustomPaint(
        painter: _AvatarPainter(data),
        child: const SizedBox.expand(),
      ),
    );
  }
}
