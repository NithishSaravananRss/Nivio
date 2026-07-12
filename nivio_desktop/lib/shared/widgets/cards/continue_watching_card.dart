import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../buttons/secondary_button.dart';
import '../common/hover_card.dart';

class ContinueWatchingCard extends StatelessWidget {
  const ContinueWatchingCard({
    super.key,
    required this.title,
    this.episodeLabel,
    this.posterLabel,
    this.progress = 0,
    this.onResume,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final String title;
  final String? episodeLabel;
  final String? posterLabel;
  final double progress;
  final VoidCallback? onResume;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel ?? title,
      borderRadius: AppRadius.large,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: AppBreakpoints.landscapeRatio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surfaceVariant, AppColors.background],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Text(
                        posterLabel ?? (title.isNotEmpty ? title.substring(0, 1) : '?'),
                        style: AppTypography.pageTitle.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.title),
                  if (episodeLabel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(episodeLabel!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SecondaryButton(label: 'Resume', onPressed: onResume, minimumSize: const Size(0, 32)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
