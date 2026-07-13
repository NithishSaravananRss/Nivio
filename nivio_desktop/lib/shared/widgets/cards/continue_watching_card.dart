import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../buttons/secondary_button.dart';
import '../common/hover_card.dart';

class ContinueWatchingCard extends StatelessWidget {
  const ContinueWatchingCard({
    super.key,
    required this.title,
    this.episodeLabel,
    this.trailingLabel,
    this.posterLabel,
    this.imageProvider,
    this.progress = 0,
    this.onResume,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final String title;
  final String? episodeLabel;
  final String? trailingLabel;
  final String? posterLabel;
  final ImageProvider? imageProvider;
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
                    if (imageProvider != null)
                      Image(
                        image: imageProvider!,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) =>
                            _PosterFallback(
                              title: title,
                              posterLabel: posterLabel,
                            ),
                      )
                    else
                      _PosterFallback(title: title, posterLabel: posterLabel),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, const Color(0x99000000)],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 7,
                          ),
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
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title,
                  ),
                  if (episodeLabel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            episodeLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                        ),
                        if (trailingLabel != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(trailingLabel!, style: AppTypography.caption),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SecondaryButton(
                      label: 'Resume',
                      onPressed: onResume,
                      minimumSize: const Size(0, 32),
                    ),
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

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.title, this.posterLabel});

  final String title;
  final String? posterLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceVariant, AppColors.background],
        ),
      ),
      child: Center(
        child: Text(
          posterLabel ?? (title.isNotEmpty ? title.substring(0, 1) : '?'),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.pageTitle.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
