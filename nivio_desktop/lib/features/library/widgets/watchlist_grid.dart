import 'package:flutter/material.dart';

import '../../../shared/theme/index.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/library_models.dart';
import '../services/library_data_service.dart';
import '../../player/models/playback_request.dart';
import '../../player/playback_request_factory.dart';
import 'library_empty_state.dart';

class WatchlistGrid extends StatefulWidget {
  const WatchlistGrid({
    super.key,
    required this.items,
    required this.service,
    required this.historyByMediaId,
    this.onOpenDetail,
    this.onPlay,
  });

  final List<LibraryWatchlistItem> items;
  final LibraryWatchlistService service;
  final Map<int, Map<String, dynamic>> historyByMediaId;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

  @override
  State<WatchlistGrid> createState() => _WatchlistGridState();
}

class _WatchlistGridState extends State<WatchlistGrid> {
  final TextEditingController _searchController = TextEditingController();
  var _isListView = false;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      if (_query.isEmpty) return true;
      return item.title.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search watchlist...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: _searchController.clear,
                        ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton(
              tooltip: _isListView ? 'Grid view' : 'List view',
              onPressed: () => setState(() => _isListView = !_isListView),
              icon: Icon(_isListView ? Icons.grid_view : Icons.view_list),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (filtered.isEmpty)
          LibraryEmptyState(
            title: _query.isEmpty
                ? 'Your watchlist is empty'
                : 'No results found for "$_query"',
            message: _query.isEmpty
                ? 'Add movies and TV shows to watch later.'
                : 'Try a different title.',
          )
        else if (_isListView)
          Column(
            children: [
              for (final item in filtered)
                _WatchlistListItem(
                  item: item,
                  service: widget.service,
                  onOpenDetail: widget.onOpenDetail,
                  onPlay: widget.onPlay,
                ),
            ],
          )
        else
          ResponsiveGrid(
            minItemWidth: 170,
            childAspectRatio: 0.66,
            children: [
              for (final item in filtered)
                MediaCard(
                  title: item.title,
                  posterPath: item.posterPath,
                  year: _year(item.releaseDate),
                  rating: item.voteAverage?.toStringAsFixed(1),
                  subtitle: _subtitle(item),
                  progress: _progress(item.id),
                  onTap: () =>
                      widget.onOpenDetail?.call('${item.mediaType}:${item.id}'),
                  onPlay: () => widget.onPlay?.call(
                    PlaybackRequestFactory.fromWatchlist(item),
                  ),
                  onMore: () =>
                      widget.onOpenDetail?.call('${item.mediaType}:${item.id}'),
                  isInWatchlist: true,
                  onWatchlist: () => widget.service.remove(item.id),
                ),
            ],
          ),
      ],
    );
  }

  String? _year(String? releaseDate) {
    if (releaseDate == null || releaseDate.length < 4) return null;
    return releaseDate.substring(0, 4);
  }

  double? _progress(int mediaId) {
    final history = widget.historyByMediaId[mediaId];
    if (history == null || history['isCompleted'] == true) return null;
    final value = (history['progressPercent'] as num?)?.toDouble();
    return value == null || value <= 0 ? null : value.clamp(0.0, 1.0);
  }

  String _subtitle(LibraryWatchlistItem item) {
    final progress = _progress(item.id);
    if (progress == null) return item.mediaType.toUpperCase();
    return '${item.mediaType.toUpperCase()} · ${(progress * 100).round()}% watched';
  }
}

class _WatchlistListItem extends StatelessWidget {
  const _WatchlistListItem({
    required this.item,
    required this.service,
    this.onOpenDetail,
    this.onPlay,
  });

  final LibraryWatchlistItem item;
  final LibraryWatchlistService service;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        tileColor: AppColors.surface,
        leading: const Icon(Icons.movie_outlined),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            item.mediaType.toUpperCase(),
            if (item.releaseDate != null && item.releaseDate!.length >= 4)
              item.releaseDate!.substring(0, 4),
            if (item.voteAverage != null) item.voteAverage!.toStringAsFixed(1),
          ].join(' · '),
        ),
        onTap: () => onOpenDetail?.call('${item.mediaType}:${item.id}'),
        trailing: Wrap(
          spacing: AppSpacing.xs,
          children: [
            IconButton(
              tooltip: 'Play',
              onPressed: () =>
                  onPlay?.call(PlaybackRequestFactory.fromWatchlist(item)),
              icon: const Icon(Icons.play_circle_fill),
            ),
            IconButton(
              tooltip: 'Remove from watchlist',
              icon: const Icon(Icons.close),
              onPressed: () => service.remove(item.id),
            ),
          ],
        ),
      ),
    );
  }
}
