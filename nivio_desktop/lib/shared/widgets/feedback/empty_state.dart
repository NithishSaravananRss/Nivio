import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../buttons/secondary_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  final String title;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final padding = (shortestSide * 0.08).clamp(
          AppSpacing.sm,
          AppSpacing.emptyState,
        );
        return Center(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: AppTypography.title),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SecondaryButton(label: actionLabel!, onPressed: onAction),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
