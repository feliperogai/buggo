import 'dart:io';
import 'package:flutter/material.dart';

class PixelAvatarData {
  final String name;
  final List<List<String>> grid; // 10 × 10
  final Map<String, Color> palette;
  final Color backgroundColor;

  /// Preço em moedas. Zero = disponível desde o começo.
  ///
  /// O preço mora aqui, e não numa tabela à parte, porque avatar e custo
  /// andam juntos: acrescentar um avatar pago é uma linha só, e não há como
  /// esquecer de cadastrar o preço em outro lugar.
  final int price;

  /// Fundo escuro pede texto claro por cima na grade de escolha.
  final bool darkBackground;

  const PixelAvatarData(
    this.name,
    this.grid,
    this.palette,
    this.backgroundColor, {
    this.price = 0,
    this.darkBackground = false,
  });

  bool get isFree => price == 0;
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


// ── Avatares gratuitos adicionais ──────────────────────────────

// 7 · Dino ─ verde, espinhos nas costas, dentinhos
const _dinoGrid = [
  ['.', '.', '.', '.', 'S', 'S', '.', '.', '.', '.'],
  ['.', '.', '.', 'S', 'G', 'G', 'S', '.', '.', '.'],
  ['.', '.', 'G', 'G', 'G', 'G', 'G', 'G', '.', '.'],
  ['.', 'G', 'G', 'W', 'G', 'G', 'W', 'G', 'G', '.'],
  ['.', 'G', 'G', 'K', 'G', 'G', 'K', 'G', 'G', '.'],
  ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
  ['G', 'G', 'W', 'W', 'W', 'W', 'W', 'W', 'G', 'G'],
  ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
  ['.', 'G', 'G', '.', '.', '.', '.', 'G', 'G', '.'],
  ['.', 'D', 'D', '.', '.', '.', '.', 'D', 'D', '.'],
];
const _dinoPal = <String, Color>{
  'S': Color(0xFF2E7D32),
  'G': Color(0xFF66BB6A),
  'W': Color(0xFFFFFFFF),
  'K': Color(0xFF1B1B1B),
  'D': Color(0xFF388E3C),
};

// 8 · Coruja ─ marrom, olhos grandes, bico amarelo
const _owlGrid = [
  ['.', 'T', 'T', '.', '.', '.', '.', 'T', 'T', '.'],
  ['.', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', '.'],
  ['B', 'B', 'W', 'W', 'B', 'B', 'W', 'W', 'B', 'B'],
  ['B', 'W', 'W', 'K', 'W', 'W', 'K', 'W', 'W', 'B'],
  ['B', 'W', 'W', 'W', 'Y', 'Y', 'W', 'W', 'W', 'B'],
  ['B', 'B', 'B', 'B', 'Y', 'Y', 'B', 'B', 'B', 'B'],
  ['B', 'C', 'B', 'B', 'B', 'B', 'B', 'B', 'C', 'B'],
  ['B', 'C', 'C', 'B', 'B', 'B', 'B', 'C', 'C', 'B'],
  ['.', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', '.'],
  ['.', '.', 'Y', 'Y', '.', '.', 'Y', 'Y', '.', '.'],
];
const _owlPal = <String, Color>{
  'T': Color(0xFF5D4037),
  'B': Color(0xFF8D6E63),
  'C': Color(0xFFD7CCC8),
  'W': Color(0xFFFFFDE7),
  'K': Color(0xFF212121),
  'Y': Color(0xFFFFB300),
};

// 9 · Ninja ─ máscara preta, faixa vermelha
const _ninjaGrid = [
  ['.', '.', 'K', 'K', 'K', 'K', 'K', 'K', '.', '.'],
  ['.', 'K', 'K', 'K', 'K', 'K', 'K', 'K', 'K', '.'],
  ['K', 'K', 'K', 'K', 'K', 'K', 'K', 'K', 'K', 'K'],
  ['R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R'],
  ['K', 'S', 'W', 'W', 'S', 'S', 'W', 'W', 'S', 'K'],
  ['K', 'S', 'W', 'D', 'S', 'S', 'D', 'W', 'S', 'K'],
  ['K', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'K'],
  ['K', 'K', 'K', 'K', 'K', 'K', 'K', 'K', 'K', 'K'],
  ['.', 'K', 'K', 'K', 'K', 'K', 'K', 'K', 'K', '.'],
  ['.', 'R', 'R', '.', '.', '.', '.', 'R', 'R', '.'],
];
const _ninjaPal = <String, Color>{
  'K': Color(0xFF1C1C1E),
  'R': Color(0xFFD32F2F),
  'S': Color(0xFFFFCCBC),
  'W': Color(0xFFFFFFFF),
  'D': Color(0xFF212121),
};

// 10 · Raposa ─ laranja, focinho branco
const _foxGrid = [
  ['.', 'O', 'O', '.', '.', '.', '.', 'O', 'O', '.'],
  ['.', 'O', 'D', 'O', '.', '.', 'O', 'D', 'O', '.'],
  ['.', 'O', 'O', 'O', 'O', 'O', 'O', 'O', 'O', '.'],
  ['O', 'O', 'O', 'O', 'O', 'O', 'O', 'O', 'O', 'O'],
  ['O', 'O', 'K', 'O', 'O', 'O', 'O', 'K', 'O', 'O'],
  ['O', 'W', 'W', 'O', 'O', 'O', 'O', 'W', 'W', 'O'],
  ['O', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'O'],
  ['.', 'O', 'W', 'W', 'N', 'N', 'W', 'W', 'O', '.'],
  ['.', '.', 'O', 'W', 'W', 'W', 'W', 'O', '.', '.'],
  ['.', '.', '.', 'O', 'O', 'O', 'O', '.', '.', '.'],
];
const _foxPal = <String, Color>{
  'O': Color(0xFFF57C00),
  'D': Color(0xFF6D4C41),
  'K': Color(0xFF1B1B1B),
  'W': Color(0xFFFFF3E0),
  'N': Color(0xFF3E2723),
};

// ── Avatares pagos ─────────────────────────────────────────────

// 11 · Caveira ─ 400 moedas
const _skullGrid = [
  ['.', '.', 'W', 'W', 'W', 'W', 'W', 'W', '.', '.'],
  ['.', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'W', '.'],
  ['W', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'W'],
  ['W', 'K', 'K', 'W', 'W', 'W', 'W', 'K', 'K', 'W'],
  ['W', 'K', 'R', 'W', 'W', 'W', 'W', 'R', 'K', 'W'],
  ['W', 'W', 'W', 'W', 'K', 'K', 'W', 'W', 'W', 'W'],
  ['.', 'W', 'W', 'W', 'K', 'K', 'W', 'W', 'W', '.'],
  ['.', 'W', 'W', 'W', 'W', 'W', 'W', 'W', 'W', '.'],
  ['.', '.', 'W', 'K', 'W', 'K', 'W', 'K', 'W', '.'],
  ['.', '.', 'W', 'W', 'W', 'W', 'W', 'W', '.', '.'],
];
const _skullPal = <String, Color>{
  'W': Color(0xFFECEFF1),
  'K': Color(0xFF161616),
  'R': Color(0xFFE53935),
};

// 12 · Dragão ─ 900 moedas
const _dragonGrid = [
  ['.', '.', 'B', '.', '.', '.', '.', 'B', '.', '.'],
  ['.', '.', 'B', 'P', 'P', 'P', 'P', 'B', '.', '.'],
  ['.', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', '.'],
  ['P', 'P', 'Y', 'K', 'P', 'P', 'K', 'Y', 'P', 'P'],
  ['P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
  ['P', 'P', 'N', 'P', 'P', 'P', 'P', 'N', 'P', 'P'],
  ['.', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', '.'],
  ['.', 'P', 'W', 'W', 'W', 'W', 'W', 'W', 'P', '.'],
  ['.', '.', 'P', 'F', 'F', 'F', 'F', 'P', '.', '.'],
  ['.', '.', '.', 'F', 'O', 'O', 'F', '.', '.', '.'],
];
const _dragonPal = <String, Color>{
  'B': Color(0xFFFFE0B2),
  'P': Color(0xFF7B1FA2),
  'Y': Color(0xFFFFD54F),
  'K': Color(0xFF1B1B1B),
  'N': Color(0xFF4A148C),
  'W': Color(0xFFFFF8E1),
  'F': Color(0xFFFF7043),
  'O': Color(0xFFFFC107),
};

// 13 · Neon ─ 1500 moedas
const _neonGrid = [
  ['.', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C', '.'],
  ['C', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'C'],
  ['C', 'D', 'N', 'N', 'D', 'D', 'N', 'N', 'D', 'C'],
  ['C', 'D', 'N', 'W', 'D', 'D', 'W', 'N', 'D', 'C'],
  ['C', 'D', 'N', 'N', 'D', 'D', 'N', 'N', 'D', 'C'],
  ['C', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'C'],
  ['C', 'D', 'M', 'M', 'M', 'M', 'M', 'M', 'D', 'C'],
  ['C', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'C'],
  ['.', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C', '.'],
  ['.', '.', 'N', 'N', '.', '.', 'N', 'N', '.', '.'],
];
const _neonPal = <String, Color>{
  'C': Color(0xFF00E5FF),
  'D': Color(0xFF16161D),
  'N': Color(0xFFFF2D95),
  'W': Color(0xFFFFFFFF),
  'M': Color(0xFF00E5FF),
};

// 14 · Buggo de Ouro ─ 3000 moedas
//
// O mascote do app em ouro. Três tons (brilho, ouro, sombra) dão relevo: em
// 10x10 é o que separa "amarelo chapado" de "dourado".
const _goldBuggoGrid = [
  ['.', 'D', '.', 'H', 'H', 'H', 'H', '.', 'D', '.'],
  ['.', '.', 'D', 'G', 'G', 'G', 'G', 'D', '.', '.'],
  ['.', 'H', 'G', 'G', 'G', 'G', 'G', 'G', 'H', '.'],
  ['H', 'G', 'W', 'W', 'G', 'G', 'W', 'W', 'G', 'H'],
  ['G', 'G', 'W', 'K', 'G', 'G', 'K', 'W', 'G', 'G'],
  ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
  ['G', 'S', 'G', 'R', 'R', 'R', 'R', 'G', 'S', 'G'],
  ['S', 'S', 'G', 'G', 'R', 'R', 'G', 'G', 'S', 'S'],
  ['.', 'S', 'S', 'G', 'G', 'G', 'G', 'S', 'S', '.'],
  ['.', '.', 'S', 'S', 'S', 'S', 'S', 'S', '.', '.'],
];
const _goldBuggoPal = <String, Color>{
  'H': Color(0xFFFFF3B0),
  'G': Color(0xFFFFC93C),
  'S': Color(0xFFB8860B),
  'D': Color(0xFF7A5C0A),
  'W': Color(0xFFFFFFFF),
  'K': Color(0xFF3E2723),
  'R': Color(0xFFD84315),
};

final List<PixelAvatarData> kPixelAvatars = [
  const PixelAvatarData('Robot', _robotGrid, _robotPal, Color(0xFFEEF0FF)),
  const PixelAvatarData('Panda', _pandaGrid, _pandaPal, Color(0xFFFAFAFA)),
  const PixelAvatarData('Gato',  _catGrid,   _catPal,   Color(0xFFFFF8F0)),
  const PixelAvatarData('Alien', _alienGrid, _alienPal, Color(0xFFF1F8E9)),
  const PixelAvatarData('Ghost', _ghostGrid, _ghostPal, Color(0xFFF3E5F5)),
  const PixelAvatarData('Urso',  _bearGrid,  _bearPal,  Color(0xFFEFEBE9)),
  const PixelAvatarData('Dino',   _dinoGrid,  _dinoPal,  Color(0xFFE8F5E9)),
  const PixelAvatarData('Coruja', _owlGrid,   _owlPal,   Color(0xFFEFEBE9)),
  const PixelAvatarData('Ninja',  _ninjaGrid, _ninjaPal, Color(0xFFECEFF1)),
  const PixelAvatarData('Raposa', _foxGrid,   _foxPal,   Color(0xFFFFF3E0)),
  // Pagos, do mais barato ao mais caro.
  const PixelAvatarData('Caveira', _skullGrid, _skullPal, Color(0xFF263238),
      price: 400, darkBackground: true),
  const PixelAvatarData('Dragão', _dragonGrid, _dragonPal, Color(0xFF311B92),
      price: 900, darkBackground: true),
  const PixelAvatarData('Neon', _neonGrid, _neonPal, Color(0xFF0D0D14),
      price: 1500, darkBackground: true),
  const PixelAvatarData('Buggo de Ouro', _goldBuggoGrid, _goldBuggoPal,
      Color(0xFF2A2118),
      price: 3000, darkBackground: true),
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
