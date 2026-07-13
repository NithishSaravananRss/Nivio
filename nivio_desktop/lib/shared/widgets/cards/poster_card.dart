import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../badges/rating_badge.dart';
import '../badges/year_badge.dart';
import '../buttons/ghost_button.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';
import '../common/animated_fade_container.dart';
import '../common/hover_card.dart';

class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.title,
    this.imageProvider,
    this.year,
    this.rating,
    this.subtitle,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.isLoading = false,
    this.onPlay,
    this.onWatchlist,
    this.isInWatchlist = false,
    this.onMore,
  });

  final String title;
  final ImageProvider? imageProvider;
  final String? year;
  final String? rating;
  final String? subtitle;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;
  final bool isLoading;
  final VoidCallback? onPlay;
  final VoidCallback? onWatchlist;
  final bool isInWatchlist;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel ?? title,
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      padding: EdgeInsets.zero,
      child: const SizedBox.shrink(),
      builder: (context, isHovered, isFocused) {
        return GestureDetector(
          onDoubleTap: onDoubleTap,
          behavior: HitTestBehavior.opaque,
          child: AspectRatio(
            aspectRatio: AppBreakpoints.posterRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _PosterArtwork(
                        imageProvider: imageProvider,
                        isLoading: isLoading,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              if (year != null) YearBadge(year: year!),
                              if (rating != null) RatingBadge(rating: rating!),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: isHovered || isFocused ? 1 : 0,
                    duration: AppAnimation.hover,
                    curve: AppAnimation.standard,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, const Color(0xDB000000)],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PrimaryButton(
                              label: 'Play',
                              onPressed: onPlay ?? onTap,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                SecondaryButton(
                                  label: isInWatchlist
                                      ? 'In Watchlist'
                                      : 'Watchlist',
                                  onPressed: onWatchlist,
                                ),
                                GhostButton(
                                  label: 'More',
                                  onPressed: onMore ?? onSecondaryTap,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PosterArtwork extends StatelessWidget {
  const _PosterArtwork({required this.imageProvider, required this.isLoading});

  final ImageProvider? imageProvider;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (imageProvider == null || isLoading) {
      return _Placeholder();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.large),
      ),
      child: Image(
        image: imageProvider!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return const _Placeholder();
        },
        errorBuilder: (context, error, stackTrace) =>
            const _Placeholder(errorState: true),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.errorState = false});

  final bool errorState;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: errorState
          ? [AppColors.surfaceVariant, AppColors.surface]
          : [AppColors.surfaceVariant, AppColors.background],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      child: Center(
        child: AnimatedFadeContainer(
          visible: true,
          child: Icon(
            errorState ? Icons.broken_image_outlined : Icons.image_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
        ),
      ),
    );
  }
}
