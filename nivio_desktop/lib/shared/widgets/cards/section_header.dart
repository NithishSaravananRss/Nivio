import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../buttons/ghost_button.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onSeeAllPressed,
    this.seeAllLabel = 'See all',
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onSeeAllPressed;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (trailing != null) {
      actions.add(trailing!);
    }

    if (onSeeAllPressed != null) {
      actions.add(GhostButton(label: seeAllLabel, onPressed: onSeeAllPressed));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.sectionTitle),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: AppTypography.body),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.lg),
          Wrap(spacing: AppSpacing.sm, children: actions),
        ],
      ],
    );
  }
}
