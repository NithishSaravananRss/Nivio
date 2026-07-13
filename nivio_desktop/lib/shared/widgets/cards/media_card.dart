import 'package:flutter/material.dart';
import '../../../core/network/image/tmdb_image_builder.dart';
import '../../theme/index.dart';
import '../badges/rating_badge.dart';
import '../badges/year_badge.dart';
import '../common/hover_card.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.title,
    this.imageProvider,
    this.posterPath,
    this.year,
    this.rating,
    this.subtitle,
    this.onTap,
    this.onPlay,
    this.onWatchlist,
    this.onMore,
  });

  final String title;
  final ImageProvider? imageProvider;
  final String? posterPath;
  final String? year;
  final String? rating;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onWatchlist;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final resolvedImage =
        imageProvider ??
        ((posterPath != null && posterPath!.isNotEmpty)
            ? NetworkImage(TmdbImageBuilder.poster(posterPath!))
            : null);

    return HoverCard(
      semanticLabel: title,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: const SizedBox.shrink(),
      builder: (context, isHovered, isFocused) {
        final active = isHovered || isFocused;

        return AnimatedScale(
          scale: active ? 1.045 : 1.0,
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          child: AspectRatio(
            aspectRatio: AppBreakpoints.posterRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Art Background
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(
                      color: active
                          ? Colors.white.withValues(alpha: 0.42)
                          : AppColors.borderSubtle.withValues(alpha: 0.55),
                      width: active ? 1.2 : 1.0,
                    ),
                    image: resolvedImage != null
                        ? DecorationImage(
                            image: resolvedImage,
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: active ? 0.52 : 0.22,
                        ),
                        blurRadius: active ? 28 : 14,
                        spreadRadius: active ? -2 : -6,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: resolvedImage == null
                      ? Center(
                          child: Icon(
                            Icons.movie_filter_outlined,
                            color: AppColors.textMuted,
                            size: 44,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Premium Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: active ? 0.24 : 0.1),
                          Colors.black.withValues(alpha: active ? 0.9 : 0.78),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Text Content & Badges (Always visible at the bottom)
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: AnimatedTranslation(
                    translation: active ? const Offset(0, -8) : Offset.zero,
                    duration: AppAnimation.hover,
                    curve: AppAnimation.standard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (year != null) ...[YearBadge(year: year!)],
                            if (rating != null) RatingBadge(rating: rating!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Play / Action hover overlays
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: active ? 1.0 : 0.0,
                    duration: AppAnimation.hover,
                    curve: AppAnimation.standard,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.14),
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (onPlay != null)
                              _CircleActionButton(
                                icon: Icons.play_arrow,
                                onTap: onPlay!,
                                primary: true,
                              ),
                            if (onWatchlist != null)
                              _CircleActionButton(
                                icon: Icons.add,
                                onTap: onWatchlist!,
                              ),
                            if (onMore != null)
                              _CircleActionButton(
                                icon: Icons.info_outline,
                                onTap: onMore!,
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

class _CircleActionButton extends StatefulWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<_CircleActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.primary
        ? AppColors.primary
        : Colors.black.withValues(alpha: 0.5);
    final fg = widget.primary ? AppColors.background : AppColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          width: widget.primary ? 48 : 42,
          height: widget.primary ? 48 : 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? bg.withValues(alpha: 0.9) : bg,
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.borderSubtle,
              width: 1.5,
            ),
            boxShadow: widget.primary
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.36),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(child: Icon(widget.icon, size: 22, color: fg)),
        ),
      ),
    );
  }
}

class AnimatedTranslation extends StatelessWidget {
  const AnimatedTranslation({
    super.key,
    required this.translation,
    required this.child,
    required this.duration,
    required this.curve,
  });

  final Offset translation;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: Offset.zero, end: translation),
      duration: duration,
      curve: curve,
      builder: (context, offset, child) {
        return Transform.translate(offset: offset, child: child);
      },
      child: child,
    );
  }
}
