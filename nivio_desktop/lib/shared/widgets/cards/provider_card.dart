import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../common/hover_card.dart';

class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key,
    required this.name,
    this.label,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.onTap,
  });

  final String name;
  final String? label;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel ?? name,
      onTap: onTap,
      borderRadius: AppRadius.large,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: Text(
                name.characters.first,
                style: AppTypography.sectionTitle.copyWith(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(name, style: AppTypography.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(label!, style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
