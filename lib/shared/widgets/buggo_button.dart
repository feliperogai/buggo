import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum BuggoButtonVariant { primary, secondary, success, danger, ghost }

class BuggoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final BuggoButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const BuggoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BuggoButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  State<BuggoButton> createState() => _BuggoButtonState();
}

class _BuggoButtonState extends State<BuggoButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  LinearGradient get _gradient {
    switch (widget.variant) {
      case BuggoButtonVariant.primary:
        return AppColors.primaryGradient;
      case BuggoButtonVariant.success:
        return AppColors.successGradient;
      case BuggoButtonVariant.danger:
        return const LinearGradient(
            colors: [Color(0xFFFF1744), Color(0xFFFF6B00)]);
      case BuggoButtonVariant.secondary:
        return const LinearGradient(
            colors: [AppColors.surface, AppColors.surfaceVariant]);
      case BuggoButtonVariant.ghost:
        return const LinearGradient(
            colors: [Colors.transparent, Colors.transparent]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          height: 56,
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(16),
            border: widget.variant == BuggoButtonVariant.secondary
                ? Border.all(color: AppColors.cardBorder, width: 1.5)
                : null,
            boxShadow: widget.onPressed != null &&
                    widget.variant != BuggoButtonVariant.ghost
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(widget.label, style: AppTextStyles.labelLarge),
                    ],
                  ),
          ),
        ),
      ),
    )
        .animate(target: widget.onPressed == null ? 0.5 : 1.0)
        .fade(duration: 200.ms);
  }
}
