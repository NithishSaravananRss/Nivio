import 'package:flutter/material.dart';

import '../../theme/index.dart';

class LandscapeSkeleton extends StatelessWidget {
  const LandscapeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(AppRadius.large)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceVariant, AppColors.background],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: double.infinity, color: AppColors.surfaceVariant),
                  const SizedBox(height: AppSpacing.sm),
                  Container(height: 12, width: 120, color: AppColors.surfaceVariant),
                  const SizedBox(height: AppSpacing.lg),
                  Container(height: 8, width: double.infinity, color: AppColors.surfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
