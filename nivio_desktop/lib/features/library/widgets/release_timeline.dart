import 'package:flutter/material.dart';

import '../../../shared/theme/index.dart';

class ReleaseTimeline extends StatelessWidget {
  const ReleaseTimeline({
    super.key,
    required this.releases,
    required this.watchlistOnly,
  });

  final List<ScheduleRelease> releases;
  final bool watchlistOnly;

  @override
  Widget build(BuildContext context) {
    if (releases.isEmpty) {
      return _ScheduleEmptyState(watchlistOnly: watchlistOnly);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final release in releases) _ReleaseItem(release: release),
      ],
    );
  }
}

class ScheduleRelease {
  const ScheduleRelease({
    required this.title,
    required this.mediaType,
    required this.releaseDate,
    this.episodeNumber,
    this.seasonNumber,
    this.hasPreciseTime = false,
    this.isInWatchlist = false,
  });

  final String title;
  final String mediaType;
  final DateTime releaseDate;
  final int? episodeNumber;
  final int? seasonNumber;
  final bool hasPreciseTime;
  final bool isInWatchlist;
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState({required this.watchlistOnly});

  final bool watchlistOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 64,
          color: AppColors.textMuted.withValues(alpha: 0.45),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          watchlistOnly
              ? 'No releases in your watchlist today'
              : 'No upcoming releases found today',
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
      ],
    );
  }
}

class _ReleaseItem extends StatelessWidget {
  const _ReleaseItem({required this.release});

  final ScheduleRelease release;

  @override
  Widget build(BuildContext context) {
    final episodeLabel = release.episodeNumber == null
        ? null
        : 'Episode ${release.episodeNumber}';
    final metadata = [
      if (release.seasonNumber != null) 'Season ${release.seasonNumber}',
      ?episodeLabel,
      _statusText(release),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MediaTypeBadge(mediaType: release.mediaType),
                        if (episodeLabel != null)
                          Text(episodeLabel, style: AppTypography.metadata),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(release.title, style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(metadata, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(ScheduleRelease item) {
    final now = DateTime.now();
    final isToday =
        item.releaseDate.year == now.year &&
        item.releaseDate.month == now.month &&
        item.releaseDate.day == now.day;
    final todayStart = DateTime(now.year, now.month, now.day);

    if (isToday) {
      return item.hasPreciseTime && item.releaseDate.isBefore(now)
          ? 'Aired Today'
          : 'Airing Today';
    }
    if (item.releaseDate.isBefore(todayStart)) {
      return 'Aired';
    }
    return 'Upcoming';
  }
}

class _MediaTypeBadge extends StatelessWidget {
  const _MediaTypeBadge({required this.mediaType});

  final String mediaType;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sidebarSelected,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          mediaType.toUpperCase(),
          style: AppTypography.metadata.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
