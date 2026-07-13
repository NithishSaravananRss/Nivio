import 'package:flutter/material.dart';

import '../../theme/index.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.title, this.message});

  final String? title;
  final String? message;

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
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                if (title != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(title!, style: AppTypography.title),
                ],
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
