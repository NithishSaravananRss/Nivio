import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/index.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/library_models.dart';
import 'library_empty_state.dart';

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
      return LibraryEmptyState(
        title: watchlistOnly
            ? 'No releases in your watchlist today'
            : 'No upcoming releases found today',
        message: watchlistOnly
            ? 'Switch to Discover to browse all scheduled releases.'
            : 'Pick another day or add shows to your watchlist.',
      );
    }

    return ResponsiveGrid(
      minItemWidth: 236,
      maxCrossAxisCount: 7,
      childAspectRatio: 236 / 420,
      mainAxisSpacing: AppSpacing.xl,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        for (final release in releases)
          _ReleaseMediaCard(release: release, onOpenDetail: onOpenDetail),
      ],
    );
  }
}

class _ReleaseMediaCard extends StatelessWidget {
  const _ReleaseMediaCard({required this.release, this.onOpenDetail});

  final LibraryScheduleItem release;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final canOpen = release.id != -1;
    final metadata = [
      release.mediaType.toUpperCase(),
      if (release.seasonNumber != null) 'S${release.seasonNumber}',
      if (release.episodeNumber != null) 'E${release.episodeNumber}',
    ].join(' · ');
    final schedule = [
      DateFormat.MMMd().format(release.releaseDate),
      _statusText(release),
    ].join(' · ');

    return MediaCard(
      mediaId: canOpen ? '${release.mediaType}:${release.id}' : null,
      title: release.title,
      posterPath: release.posterPath,
      year: DateFormat.MMMd().format(release.releaseDate),
      subtitle: metadata,
      overview: schedule,
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
        onOpenDetail?.call('${release.mediaType}:${release.id}');
      },
      onMore: canOpen
          ? () => onOpenDetail?.call('${release.mediaType}:${release.id}')
          : null,
    );
  }

  String _statusText(LibraryScheduleItem item) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final isToday =
        item.releaseDate.year == now.year &&
        item.releaseDate.month == now.month &&
        item.releaseDate.day == now.day;

    if (item.hasPreciseTime) {
      final time = DateFormat('h:mm a').format(item.releaseDate);
      if (item.releaseDate.isBefore(now)) return 'Aired $time';
      return isToday ? 'Airs $time' : time;
    }
    if (isToday) return 'Airing Today';
    if (item.releaseDate.isBefore(todayStart)) return 'Aired';
    return 'Upcoming';
  }
}
