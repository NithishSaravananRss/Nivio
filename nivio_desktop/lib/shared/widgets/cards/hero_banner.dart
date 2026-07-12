import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../badges/metadata_badge.dart';
import '../badges/genre_chip.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';
import '../common/animated_fade_container.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.title,
    required this.overview,
    this.rating,
    this.year,
    this.runtime,
    this.genres = const [],
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.posterLabel,
    this.backdropLabel,
    this.semanticLabel,
  });

  final String title;
  final String overview;
  final String? rating;
  final String? year;
  final String? runtime;
  final List<String> genres;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String? posterLabel;
  final String? backdropLabel;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < AppBreakpoints.standard;

        return Semantics(
          label: semanticLabel ?? title,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.panel),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppShadows.hover,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.panel),
              child: Stack(
                children: [
                  Positioned.fill(child: _Backdrop(label: backdropLabel ?? posterLabel ?? title)),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.posterScrimBottom,
                            const Color(0xC7000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: AnimatedFadeContainer(
                      visible: true,
                      child: stacked
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PosterTile(label: posterLabel ?? title),
                                const SizedBox(height: AppSpacing.xxl),
                                _HeroCopy(
                                  title: title,
                                  overview: overview,
                                  rating: rating,
                                  year: year,
                                  runtime: runtime,
                                  genres: genres,
                                  primaryActionLabel: primaryActionLabel,
                                  secondaryActionLabel: secondaryActionLabel,
                                  onPrimaryAction: onPrimaryAction,
                                  onSecondaryAction: onSecondaryAction,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _HeroCopy(
                                    title: title,
                                    overview: overview,
                                    rating: rating,
                                    year: year,
                                    runtime: runtime,
                                    genres: genres,
                                    primaryActionLabel: primaryActionLabel,
                                    secondaryActionLabel: secondaryActionLabel,
                                    onPrimaryAction: onPrimaryAction,
                                    onSecondaryAction: onSecondaryAction,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xxl),
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _PosterTile(label: posterLabel ?? title),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
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
          child: Text(label, style: AppTypography.display.copyWith(fontSize: 72)),
        ),
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  const _PosterTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppBreakpoints.posterRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D3343), Color(0xFF1A1D24)],
          ),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppShadows.popover,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle.copyWith(fontSize: 24, color: AppColors.textMuted),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, const Color(0x59000000)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.title,
    required this.overview,
    required this.rating,
    required this.year,
    required this.runtime,
    required this.genres,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  final String title;
  final String overview;
  final String? rating;
  final String? year;
  final String? runtime;
  final List<String> genres;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(title, style: AppTypography.display.copyWith(fontSize: 34)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (rating != null) MetadataBadge(label: rating!),
            if (year != null) MetadataBadge(label: year!),
            if (runtime != null) MetadataBadge(label: runtime!),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: genres.map((genre) => GenreChip(label: genre)).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(overview, maxLines: 4, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            PrimaryButton(label: primaryActionLabel ?? 'Play', onPressed: onPrimaryAction),
            SecondaryButton(label: secondaryActionLabel ?? 'More Info', onPressed: onSecondaryAction),
          ],
        ),
      ],
    );
  }
}
