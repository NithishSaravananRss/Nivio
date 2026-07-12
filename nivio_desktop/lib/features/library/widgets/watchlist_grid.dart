import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';

class WatchlistGrid extends StatelessWidget {
  const WatchlistGrid({super.key});

  static const _items = [
    _WatchlistItem('Signal Lost', '2026', '8.4', 'Action · Drama'),
    _WatchlistItem('Midnight Harbor', '2025', '7.9', 'Mystery · Thriller'),
    _WatchlistItem('Sky Forge', '2026', '9.0', 'Anime · Action'),
    _WatchlistItem('Archive West', '2024', '7.8', 'TV · Drama'),
    _WatchlistItem('Moon Harbor', '2025', '8.1', 'Drama · Mystery'),
    _WatchlistItem('Glass Orbit', '2024', '7.5', 'Adventure · Sci-Fi'),
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
            onTap: _noop,
            onSecondaryTap: _noop,
            onPlay: _noop,
            onWatchlist: _noop,
            onMore: _noop,
          ),
      ],
    );
  }
}

class _WatchlistItem {
  const _WatchlistItem(this.title, this.year, this.rating, this.subtitle);

  final String title;
  final String year;
  final String rating;
  final String subtitle;
}

void _noop() {}
