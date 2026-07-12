import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../buttons/ghost_button.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.danger = false,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.pageTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTypography.body),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GhostButton(label: cancelLabel, onPressed: onCancel ?? () => Navigator.of(context).maybePop()),
                const SizedBox(width: AppSpacing.sm),
                if (danger)
                  SecondaryButton(label: confirmLabel, onPressed: onConfirm)
                else
                  PrimaryButton(label: confirmLabel, onPressed: onConfirm),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
