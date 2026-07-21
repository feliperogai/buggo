import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Compact heart+count indicator shown in the top-right corner while the
/// user is answering a question.
class LivesBadge extends StatelessWidget {
  final int lives;
  final bool unlimited;

  const LivesBadge({super.key, required this.lives, required this.unlimited});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded, color: AppColors.error, size: 14),
          const SizedBox(width: 4),
          Text(
            unlimited ? '∞' : '$lives',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
