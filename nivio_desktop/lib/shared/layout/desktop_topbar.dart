import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Top application bar for the desktop shell.
class DesktopTopbar extends StatelessWidget {
  const DesktopTopbar({super.key, this.isOverlay = false});

  final bool isOverlay;

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: isOverlay ? Colors.transparent : AppColors.topbarBackground,
        border: isOverlay
            ? null
            : const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: const SizedBox.expand(),
      ),
    );

    if (!isOverlay) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.38),
            Colors.black.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
      child: child,
    );
  }
}
