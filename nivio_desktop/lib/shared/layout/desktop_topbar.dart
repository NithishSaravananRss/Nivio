import 'package:flutter/material.dart';

import '../theme/index.dart';
import '../widgets/buttons/icon_action_button.dart';

/// Top application bar for the desktop shell.
class DesktopTopbar extends StatelessWidget {
  const DesktopTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.topbarBackground,
        border: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Row(
          children: [
            Text(
              'Nivio Desktop',
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            const Spacer(),
            const SizedBox(width: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                IconActionButton(
                  icon: Icon(Icons.notifications_none_outlined),
                  semanticLabel: 'Notifications',
                  tooltip: 'Notifications',
                ),
                IconActionButton(
                  icon: Icon(Icons.system_update_alt_outlined),
                  semanticLabel: 'Updates',
                  tooltip: 'Updates',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
