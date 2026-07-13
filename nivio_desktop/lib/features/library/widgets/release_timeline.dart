import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/image/tmdb_image_builder.dart';
import '../../../shared/theme/index.dart';
import '../models/library_models.dart';

class ReleaseTimeline extends StatelessWidget {
  const ReleaseTimeline({
    super.key,
    required this.releases,
    required this.watchlistOnly,
    this.onOpenDetail,
  });

  final List<LibraryScheduleItem> releases;
  final bool watchlistOnly;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (releases.isEmpty) {
      return _ScheduleEmptyState(watchlistOnly: watchlistOnly);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final release in releases)
          _ReleaseItem(release: release, onOpenDetail: onOpenDetail),
      ],
    );
  }
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
  const _ReleaseItem({required this.release, this.onOpenDetail});

  final LibraryScheduleItem release;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final episodeLabel = release.episodeNumber == null
        ? null
        : 'Episode ${release.episodeNumber}';
    final metadata = [
      if (release.seasonNumber != null) 'Season ${release.seasonNumber}',
      ?episodeLabel,
    ].join(' · ');
    final imageUrl = release.posterPath == null || release.posterPath!.isEmpty
        ? null
        : TmdbImageBuilder.poster(release.posterPath!);
    final canOpen = release.id != -1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.large),
          onTap: () {
            if (!canOpen) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Details unavailable. Please search for this show.',
                  ),
                ),
              );
              return;
            }
            onOpenDetail?.call('${release.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: SizedBox(
                    width: 70,
                    height: 105,
                    child: imageUrl == null
                        ? const ColoredBox(
                            color: AppColors.surfaceVariant,
                            child: Icon(Icons.movie_creation_outlined),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(
                                  color: AppColors.surfaceVariant,
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
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
                      Text(
                        release.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title,
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(metadata, style: AppTypography.caption),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      _AiringStatus(release: release),
                    ],
                  ),
                ),
                if (canOpen) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiringStatus extends StatelessWidget {
  const _AiringStatus({required this.release});

  final LibraryScheduleItem release;

  @override
  Widget build(BuildContext context) {
    final isPast = release.releaseDate.isBefore(DateTime.now());
    final color = isPast ? AppColors.textMuted : AppColors.primary;

    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        if (release.hasPreciseTime) ...[
          _CountdownText(targetDate: release.releaseDate, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '• ${DateFormat('h:mm a').format(release.releaseDate)}',
            style: AppTypography.caption,
          ),
        ] else
          Text(
            _statusText(release),
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  String _statusText(LibraryScheduleItem item) {
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
    if (item.releaseDate.isBefore(todayStart)) return 'Aired';
    return 'Upcoming';
  }
}

class _CountdownText extends StatefulWidget {
  const _CountdownText({required this.targetDate, required this.color});

  final DateTime targetDate;
  final Color color;

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final left = widget.targetDate.isAfter(now)
        ? widget.targetDate.difference(now)
        : Duration.zero;
    if (left == Duration.zero) {
      _timer?.cancel();
    }
    return Text(
      _formatDuration(left),
      style: AppTypography.caption.copyWith(
        color: widget.color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return 'Aired';
    if (duration.inDays > 0) {
      return 'Airs in ${duration.inDays}d ${duration.inHours % 24}h';
    }
    if (duration.inHours > 0) {
      return 'Airs in ${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return 'Airs in ${duration.inMinutes}m ${duration.inSeconds % 60}s';
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
