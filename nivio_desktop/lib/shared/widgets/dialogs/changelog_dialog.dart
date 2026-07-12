import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../buttons/primary_button.dart';

class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({
    super.key,
    required this.title,
    required this.changes,
    this.onClose,
  });

  final String title;
  final String changes;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.pageTitle),
              const SizedBox(height: AppSpacing.lg),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(changes, style: AppTypography.body),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Align(
                alignment: Alignment.centerRight,
                child: PrimaryButton(label: 'Close', onPressed: onClose ?? () => Navigator.of(context).maybePop()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
