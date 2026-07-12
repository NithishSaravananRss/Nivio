import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';

class WatchlistGrid extends StatelessWidget {
  const WatchlistGrid({super.key, this.onOpenDetail});

  final ValueChanged<String>? onOpenDetail;

  static const _items = [
    _WatchlistItem(
      'signal-lost',
      'Signal Lost',
      '2026',
      '8.4',
      'Action · Drama',
    ),
    _WatchlistItem(
      'midnight-harbor',
      'Midnight Harbor',
      '2025',
      '7.9',
      'Mystery · Thriller',
    ),
    _WatchlistItem('sky-forge', 'Sky Forge', '2026', '9.0', 'Anime · Action'),
    _WatchlistItem('archive-west', 'Archive West', '2024', '7.8', 'TV · Drama'),
    _WatchlistItem(
      'moon-harbor',
      'Moon Harbor',
      '2025',
      '8.1',
      'Drama · Mystery',
    ),
    _WatchlistItem(
      'glass-orbit',
      'Glass Orbit',
      '2024',
      '7.5',
      'Adventure · Sci-Fi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      minItemWidth: 170,
      childAspectRatio: 0.66,
      children: [
        for (final item in _items)
          PosterCard(
            title: item.title,
            year: item.year,
            rating: item.rating,
            subtitle: item.subtitle,
            onTap: () => onOpenDetail?.call(item.id),
            onSecondaryTap: () => onOpenDetail?.call(item.id),
            onPlay: () => onOpenDetail?.call(item.id),
            onWatchlist: _noop,
            onMore: _noop,
          ),
      ],
    );
  }
}

class _WatchlistItem {
  const _WatchlistItem(
    this.id,
    this.title,
    this.year,
    this.rating,
    this.subtitle,
  );

  final String id;
  final String title;
  final String year;
  final String rating;
  final String subtitle;
}

void _noop() {}
