import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum MascotMood { idle, happy, thinking, celebrating, sad }

class MascotWidget extends StatelessWidget {
  final MascotMood mood;
  final double size;
  final String? speechBubble;

  const MascotWidget({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 110,
    this.speechBubble,
  });

  // Pixel grids: 8 cols × 9 rows
  static const List<List<String>> _happyGrid = [
    ['.', '.', 'G', 'G', 'G', 'G', '.', '.'],
    ['.', 'G', 'G', 'G', 'G', 'G', 'G', '.'],
    ['G', 'G', 'W', 'W', 'G', 'W', 'W', 'G'],
    ['G', 'G', 'W', 'B', 'G', 'B', 'W', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'R', 'G', 'G', 'G', 'R', 'G'],
    ['G', 'G', 'G', 'R', 'R', 'R', 'G', 'G'],
    ['.', 'G', 'G', 'G', 'G', 'G', 'G', '.'],
    ['.', '.', 'G', 'G', 'G', 'G', '.', '.'],
  ];

  static const List<List<String>> _sadGrid = [
    ['.', '.', 'G', 'G', 'G', 'G', '.', '.'],
    ['.', 'G', 'G', 'G', 'G', 'G', 'G', '.'],
    ['G', 'G', 'W', 'W', 'G', 'W', 'W', 'G'],
    ['G', 'G', 'W', 'B', 'G', 'B', 'W', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'R', 'R', 'R', 'G', 'G'],
    ['G', 'G', 'R', 'G', 'G', 'G', 'R', 'G'],
    ['.', 'G', 'G', 'G', 'G', 'G', 'G', '.'],
    ['.', '.', 'G', 'G', 'G', 'G', '.', '.'],
  ];

  static const List<List<String>> _thinkingGrid = [
    ['.', '.', 'G', 'G', 'G', 'G', '.', '.'],
    ['.', 'G', 'G', 'G', 'G', 'G', 'G', '.'],
    ['G', 'G', 'W', 'W', 'G', 'W', 'W', 'G'],
    ['G', 'G', 'B', 'W', 'G', 'W', 'B', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'R', 'R', 'G', 'G', 'G'],
    ['.', 'G', 'G', 'G', 'G', 'G', 'G', '.'],
    ['.', '.', 'G', 'G', 'G', 'G', '.', '.'],
  ];

  List<List<String>> get _grid {
    switch (mood) {
      case MascotMood.sad:
        return _sadGrid;
      case MascotMood.thinking:
        return _thinkingGrid;
      default:
        return _happyGrid;
    }
  }

  Color get _borderColor {
    switch (mood) {
      case MascotMood.celebrating:
        return AppColors.accent;
      case MascotMood.sad:
        return AppColors.error;
      case MascotMood.thinking:
        return AppColors.primaryLight;
      default:
        return AppColors.success;
    }
  }

  Color get _bgColor {
    switch (mood) {
      case MascotMood.celebrating:
        return AppColors.accent.withValues(alpha: 0.1);
      case MascotMood.sad:
        return AppColors.error.withValues(alpha: 0.07);
      case MascotMood.thinking:
        return AppColors.primaryLight.withValues(alpha: 0.08);
      default:
        return AppColors.success.withValues(alpha: 0.08);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = _borderColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (speechBubble != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Text(
              speechBubble!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Tail da bolha
          CustomPaint(
            size: const Size(14, 8),
            painter: _BubbleTailPainter(),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(size * 0.22),
            border: Border.all(color: border.withValues(alpha: 0.6), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: border.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CustomPaint(
              painter: _PixelBugPainter(_grid),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -8,
              duration: 1400.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.cardBorder;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
    final paintFill = Paint()..color = AppColors.surface;
    final pathInner = Path()
      ..moveTo(1, 0)
      ..lineTo(size.width / 2, size.height - 1)
      ..lineTo(size.width - 1, 0)
      ..close();
    canvas.drawPath(pathInner, paintFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _PixelBugPainter extends CustomPainter {
  final List<List<String>> grid;

  static const Map<String, Color> _palette = {
    'G': Color(0xFF4EC94A),
    'D': Color(0xFF2A7A27),
    'W': Color(0xFFFFFFFF),
    'B': Color(0xFF1E1B4B),
    'R': Color(0xFFEF4444),
  };

  const _PixelBugPainter(this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final rows = grid.length;
    final cols = grid[0].length;
    final pW = size.width / cols;
    final pH = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final key = grid[r][c];
        if (key == '.') continue;
        final color = _palette[key];
        if (color == null) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * pW + 0.5, r * pH + 0.5, pW - 1, pH - 1),
            const Radius.circular(1.5),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelBugPainter old) => old.grid != grid;
}
