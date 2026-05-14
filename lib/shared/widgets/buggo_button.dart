import 'package:flutter/material.dart';
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
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Gradient? get _gradient {
    if (widget.onPressed == null) return null;
    switch (widget.variant) {
      case BuggoButtonVariant.primary:
        return AppColors.primaryGradient;
      case BuggoButtonVariant.success:
        return AppColors.successGradient;
      case BuggoButtonVariant.danger:
        return const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)]);
      default:
        return null;
    }
  }

  Color get _bgColor {
    if (widget.onPressed == null) return AppColors.divider;
    switch (widget.variant) {
      case BuggoButtonVariant.secondary:
        return AppColors.surface;
      case BuggoButtonVariant.ghost:
        return Colors.transparent;
      default:
        return AppColors.primary;
    }
  }

  Color get _textColor {
    if (widget.onPressed == null) return AppColors.textMuted;
    switch (widget.variant) {
      case BuggoButtonVariant.secondary:
        return AppColors.primary;
      case BuggoButtonVariant.ghost:
        return AppColors.primary;
      default:
        return Colors.white;
    }
  }

  Border? get _border {
    switch (widget.variant) {
      case BuggoButtonVariant.secondary:
        return Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5);
      case BuggoButtonVariant.ghost:
        return null;
      default:
        return null;
    }
  }

  List<BoxShadow> get _shadows {
    if (widget.onPressed == null) return [];
    switch (widget.variant) {
      case BuggoButtonVariant.primary:
        return [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      case BuggoButtonVariant.success:
        return [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      case BuggoButtonVariant.danger:
        return [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _ctrl.forward(),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: widget.width,
          height: 52,
          decoration: BoxDecoration(
            gradient: _gradient,
            color: _gradient == null ? _bgColor : null,
            borderRadius: BorderRadius.circular(100),
            border: _border,
            boxShadow: _shadows,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: _textColor, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: _textColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: _textColor),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
