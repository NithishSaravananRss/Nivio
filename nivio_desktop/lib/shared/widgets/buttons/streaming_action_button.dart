import 'package:flutter/material.dart';
import '../../theme/index.dart';

enum StreamingActionButtonType { primary, secondary, iconOnly }

class StreamingActionButton extends StatefulWidget {
  const StreamingActionButton({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.type = StreamingActionButtonType.secondary,
    this.tooltip,
  });

  final VoidCallback onTap;
  final IconData? icon;
  final String? label;
  final StreamingActionButtonType type;
  final String? tooltip;

  @override
  State<StreamingActionButton> createState() => _StreamingActionButtonState();
}

class _StreamingActionButtonState extends State<StreamingActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget buttonContent;

    switch (widget.type) {
      case StreamingActionButtonType.primary:
        buttonContent = AnimatedContainer(
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 17),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.small),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.5 : 0.34),
                blurRadius: _isHovered ? 30 : 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 26, color: AppColors.background),
                if (widget.label != null) const SizedBox(width: AppSpacing.md),
              ],
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: AppTypography.title.copyWith(
                    fontSize: 17,
                    color: AppColors.background,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        );
        break;

      case StreamingActionButtonType.secondary:
        buttonContent = AnimatedContainer(
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.36)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: AppColors.textPrimary),
                if (widget.label != null) const SizedBox(width: AppSpacing.md),
              ],
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: AppTypography.title.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        );
        break;

      case StreamingActionButtonType.iconOnly:
        buttonContent = AnimatedContainer(
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 20,
              color: AppColors.textPrimary.withValues(
                alpha: _isHovered ? 1 : 0.82,
              ),
            ),
          ),
        );
        break;
    }

    if (widget.tooltip != null) {
      buttonContent = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: buttonContent,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.04 : 1.0,
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          child: buttonContent,
        ),
      ),
    );
  }
}
