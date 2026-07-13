import 'package:flutter/material.dart';
import '../../theme/index.dart';

class MetadataChip extends StatefulWidget {
  const MetadataChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<MetadataChip> createState() => _MetadataChipState();
}

class _MetadataChipState extends State<MetadataChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Colors.black.withValues(alpha: 0.24);
    final fg = widget.foregroundColor ?? AppColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimation.hover,
        curve: AppAnimation.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.surfaceVariant.withValues(alpha: 0.42)
              : bg,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: _isHovered
                ? AppColors.textPrimary.withValues(alpha: 0.26)
                : AppColors.textPrimary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 14,
                color: _isHovered
                    ? AppColors.primary
                    : fg.withValues(alpha: 0.72),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              widget.label,
              style: AppTypography.metadata.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
