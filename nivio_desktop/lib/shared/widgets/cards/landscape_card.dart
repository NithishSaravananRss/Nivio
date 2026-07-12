import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../badges/metadata_badge.dart';
import '../common/hover_card.dart';

class LandscapeCard extends StatelessWidget {
  const LandscapeCard({
    super.key,
    required this.title,
    this.imageProvider,
    this.subtitle,
    this.metadata,
    this.progress,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.isLoading = false,
  });

  final String title;
  final ImageProvider? imageProvider;
  final String? subtitle;
  final List<String>? metadata;
  final double? progress;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel ?? title,
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: AspectRatio(
          aspectRatio: AppBreakpoints.landscapeRatio,
          child: Row(
            children: [
              Expanded(flex: 4, child: _Artwork(imageProvider: imageProvider, isLoading: isLoading, progress: progress)),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.title),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle!, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.body),
                      ],
                      if (metadata != null && metadata!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: metadata!.map((value) => MetadataBadge(label: value)).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.imageProvider, required this.isLoading, required this.progress});

  final ImageProvider? imageProvider;
  final bool isLoading;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final content = imageProvider == null || isLoading
        ? const _LandscapePlaceholder()
        : Image(
            image: imageProvider!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return const _LandscapePlaceholder();
            },
            errorBuilder: (context, error, stackTrace) => const _LandscapePlaceholder(errorState: true),
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.large)),
          child: content,
        ),
        if (progress != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(value: progress!.clamp(0, 1), minHeight: 6),
              ),
            ),
          ),
      ],
    );
  }
}

class _LandscapePlaceholder extends StatelessWidget {
  const _LandscapePlaceholder({this.errorState = false});

  final bool errorState;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: errorState
              ? [AppColors.surfaceVariant, AppColors.surface]
              : [AppColors.surfaceVariant, AppColors.background],
        ),
      ),
      child: Center(
        child: Icon(
          errorState ? Icons.broken_image_outlined : Icons.movie_outlined,
          color: AppColors.textMuted,
          size: 40,
        ),
      ),
    );
  }
}
