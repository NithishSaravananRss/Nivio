import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../buttons/ghost_button.dart';
import '../buttons/primary_button.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    this.onInstall,
    this.onLater,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final VoidCallback? onInstall;
  final VoidCallback? onLater;

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
              Text('Update available', style: AppTypography.pageTitle),
              const SizedBox(height: AppSpacing.sm),
              Text('Current: $currentVersion', style: AppTypography.body),
              Text('Latest: $latestVersion', style: AppTypography.body),
              const SizedBox(height: AppSpacing.lg),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(releaseNotes, style: AppTypography.body),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GhostButton(label: 'Later', onPressed: onLater ?? () => Navigator.of(context).maybePop()),
                  const SizedBox(width: AppSpacing.sm),
                  PrimaryButton(label: 'Install', onPressed: onInstall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
