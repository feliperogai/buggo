import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

enum MascotMood { idle, happy, thinking, celebrating, sad }

class MascotWidget extends StatelessWidget {
  final MascotMood mood;
  final double size;
  final String? speechBubble;

  const MascotWidget({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 120,
    this.speechBubble,
  });

  String get _emoji {
    switch (mood) {
      case MascotMood.happy:
        return '🐛';
      case MascotMood.celebrating:
        return '🎉';
      case MascotMood.thinking:
        return '🤔';
      case MascotMood.sad:
        return '😢';
      case MascotMood.idle:
        return '🐛';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (speechBubble != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              speechBubble!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _emoji,
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -8,
              duration: 1200.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}
