import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../features/search/models/search_media_item.dart';
import '../../../core/network/image/tmdb_image_builder.dart';
import '../../theme/index.dart';
import '../common/animated_fade_container.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.item,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.semanticLabel,
  });

  final SearchMediaItem item;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final title = item.title;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.compact;
        final contentWidth = compact ? constraints.maxWidth : 460.0;
        final contentInset = compact ? AppSpacing.xl : 92.0;

        return Semantics(
          label: semanticLabel ?? title,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(child: HeroBackdropLayer(item: item)),
                Positioned(
                  left: contentInset,
                  right: compact ? AppSpacing.xxl : null,
                  bottom: compact ? AppSpacing.xxl : 58,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: HeroContentPanel(
                      item: item,
                      primaryActionLabel: primaryActionLabel,
                      secondaryActionLabel: secondaryActionLabel,
                      onPrimaryAction: onPrimaryAction,
                      onSecondaryAction: onSecondaryAction,
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

class HeroBackdropLayer extends StatelessWidget {
  const HeroBackdropLayer({super.key, required this.item});

  final SearchMediaItem item;

  @override
  Widget build(BuildContext context) {
    final backdropImage =
        item.backdropPath != null && item.backdropPath!.isNotEmpty
        ? NetworkImage(
            TmdbImageBuilder.backdrop(item.backdropPath, size: 'w1280'),
          )
        : null;

    return Stack(
      children: [
        Positioned.fill(
          child: _Backdrop(label: item.title, imageProvider: backdropImage),
        ),
        const Positioned.fill(child: _MastheadScrims()),
      ],
    );
  }
}

class HeroContentPanel extends StatelessWidget {
  const HeroContentPanel({
    super.key,
    required this.item,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final SearchMediaItem item;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return AnimatedFadeContainer(
      visible: true,
      child: _HeroCopy(
        item: item,
        title: item.title,
        overview: item.overview,
        genres: item.genres,
        primaryActionLabel: primaryActionLabel,
        secondaryActionLabel: secondaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        onSecondaryAction: onSecondaryAction,
      ),
    );
  }
}

class _MastheadScrims extends StatelessWidget {
  const _MastheadScrims();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.58,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.background.withValues(alpha: 0.84),
                      AppColors.background.withValues(alpha: 0.58),
                      AppColors.background.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.38, 0.78, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.88),
                  AppColors.background.withValues(alpha: 0.46),
                  Colors.transparent,
                ],
                stops: const [0, 0.24, 0.72],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0, 0.28],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.label, this.imageProvider});

  final String label;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    if (imageProvider != null) {
      return Image(
        image: imageProvider!,
        fit: BoxFit.cover,
        alignment: Alignment.centerRight,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232734), Color(0xFF10131A), Color(0xFF0D0F14)],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.16,
          child: Text(
            label,
            style: AppTypography.display.copyWith(fontSize: 72),
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.item,
    required this.title,
    required this.overview,
    required this.genres,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  final SearchMediaItem item;
  final String title;
  final String overview;
  final List<String> genres;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight.isFinite && constraints.maxHeight < 300;
        final titleLength = title.runes.length;
        final titleSize = compact
            ? 34.0
            : titleLength > 52
            ? 38.0
            : titleLength > 32
            ? 42.0
            : 46.0;
        final overviewLines = compact ? 2 : 3;
        final metadata = <String>[
          if (item.year > 0) item.yearLabel,
          if (item.runtimeLabel.trim().isNotEmpty)
            item.runtimeLabel
          else if (item.mediaType == SearchMediaTypeFilter.tv ||
              item.mediaType == SearchMediaTypeFilter.anime)
            '1 Season',
          if (item.language != SearchLanguageFilter.all) item.languageLabel,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New Release',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: const Color(0xFF1492FF),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display.copyWith(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                height: 1.02,
                shadows: const [
                  Shadow(color: Color(0xB3000000), blurRadius: 22),
                ],
              ),
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _InlineMetadata(items: metadata),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              overview,
              maxLines: overviewLines,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.92),
                fontSize: 15,
                height: 1.38,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (genres.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _GenreLine(genres: genres.take(4).toList()),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Flexible(
                  child: _MastheadButton(
                    key: const ValueKey('hero_watch_now_button'),
                    icon: LucideIcons.play,
                    label: primaryActionLabel ?? 'Watch Now',
                    onPressed: onPrimaryAction,
                    minWidth: compact ? 220 : 348,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _MastheadButton.iconOnly(
                  icon: secondaryActionLabel == 'In watchlist'
                      ? LucideIcons.check
                      : LucideIcons.plus,
                  label: secondaryActionLabel ?? 'Add to watchlist',
                  onPressed: onSecondaryAction,
                  semanticLabel: secondaryActionLabel ?? 'Add to watchlist',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InlineMetadata extends StatelessWidget {
  const _InlineMetadata({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Text(
            items[i],
            style: AppTypography.title.copyWith(
              color: i == 1
                  ? AppColors.textPrimary.withValues(alpha: 0.74)
                  : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (i != items.length - 1)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ],
    );
  }
}

class _GenreLine extends StatelessWidget {
  const _GenreLine({required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < genres.length; i++) ...[
          Text(
            genres[i],
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (i != genres.length - 1)
            Text(
              '|',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ],
    );
  }
}

class _MastheadButton extends StatefulWidget {
  const _MastheadButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.minWidth,
  }) : semanticLabel = null,
       iconOnly = false;

  const _MastheadButton.iconOnly({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  }) : minWidth = 52,
       iconOnly = true;

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double minWidth;
  final String? semanticLabel;
  final bool iconOnly;

  @override
  State<_MastheadButton> createState() => _MastheadButtonState();
}

class _MastheadButtonState extends State<_MastheadButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final active = enabled && (_hovered || _focused);
    final accent = context.appAccent;
    final accentLight = Color.lerp(accent, Colors.white, active ? 0.28 : 0.16)!;
    final scale = _pressed
        ? 0.985
        : active
        ? 1.035
        : 1.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: Tooltip(
        message: widget.semanticLabel ?? widget.label,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          },
          child: FocusableActionDetector(
            enabled: enabled,
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? widget.onPressed : null,
              onTapDown: enabled
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
              onTapCancel: enabled
                  ? () => setState(() => _pressed = false)
                  : null,
              child: AnimatedScale(
                scale: scale,
                duration: AppAnimation.hover,
                curve: AppAnimation.standard,
                child: AnimatedSlide(
                  offset: active && !_pressed
                      ? const Offset(0, -0.045)
                      : Offset.zero,
                  duration: AppAnimation.hover,
                  curve: AppAnimation.standard,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: widget.minWidth),
                    child: AnimatedContainer(
                      duration: AppAnimation.hover,
                      curve: AppAnimation.standard,
                      height: 52,
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.iconOnly ? 0 : AppSpacing.xxl,
                      ),
                      decoration: BoxDecoration(
                        color: widget.iconOnly
                            ? Color.lerp(
                                const Color(0xFF3A3D46),
                                const Color(0xFF525661),
                                active ? 1 : 0,
                              )!.withValues(alpha: enabled ? 0.94 : 0.36)
                            : enabled
                            ? null
                            : Colors.white.withValues(alpha: 0.28),
                        gradient: !widget.iconOnly && enabled
                            ? LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [accentLight, accent],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: widget.iconOnly
                                ? active
                                      ? 0.22
                                      : 0.10
                                : active
                                ? 0.18
                                : 0,
                          ),
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color:
                                      (widget.iconOnly ? Colors.white : accent)
                                          .withValues(alpha: 0.28),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: widget.iconOnly
                            ? MainAxisSize.min
                            : MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSlide(
                            offset: active && !widget.iconOnly
                                ? const Offset(0.12, 0)
                                : Offset.zero,
                            duration: AppAnimation.hover,
                            curve: AppAnimation.standard,
                            child: Icon(
                              widget.icon,
                              size: widget.iconOnly ? 22 : 24,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (!widget.iconOnly) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.title.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
