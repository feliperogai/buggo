import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class XpBar extends StatelessWidget {
  final int xp;
  final double progress;
  final int level;

  const XpBar({
    super.key,
    required this.xp,
    required this.progress,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$level',
              style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nível $level', style: AppTextStyles.bodySmall),
                  Text(
                    '$xp XP',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.xpColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearPercentIndicator(
                lineHeight: 8,
                percent: progress.clamp(0.0, 1.0),
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.cardBorder,
                linearGradient: AppColors.primaryGradient,
                barRadius: const Radius.circular(4),
                animation: true,
                animationDuration: 800,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
