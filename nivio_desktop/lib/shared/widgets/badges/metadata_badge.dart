import 'package:flutter/material.dart';

import '../../theme/index.dart';

class MetadataBadge extends StatelessWidget {
  const MetadataBadge({super.key, required this.label, this.backgroundColor = AppColors.surfaceVariant, this.foregroundColor = AppColors.textSecondary});

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DesktopBadge(text: label, backgroundColor: backgroundColor, foregroundColor: foregroundColor);
  }
}

class DesktopBadge extends StatelessWidget {
  const DesktopBadge({super.key, required this.text, required this.backgroundColor, required this.foregroundColor});

  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        text,
        style: AppTypography.metadata.copyWith(color: foregroundColor),
      ),
    );
  }
}
