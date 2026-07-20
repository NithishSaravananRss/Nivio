import 'package:flutter/foundation.dart';

import '../../details/models/detail_models.dart';
import '../../search/models/search_media_item.dart';
import '../models/library_models.dart';
import 'library_data_service.dart';
import 'library_persistence.dart';

class WatchlistSyncController extends ChangeNotifier {
  WatchlistSyncController._() {
    _boxListenable = LibraryPersistence.isReady
        ? _service.listenable()
        : ValueNotifier<int>(0);
    _boxListenable.addListener(notifyListeners);
  }

  static final WatchlistSyncController instance = WatchlistSyncController._();

  final LibraryWatchlistService _service = LibraryWatchlistService();
  late final ValueListenable<dynamic> _boxListenable;

  bool isInWatchlist(String mediaId) {
    final id = _numericMediaId(mediaId);
    if (id == null) return false;
    return _service.isInWatchlist(id);
  }

  Future<void> toggleDetailMedia(DetailMedia media) {
    final id = _numericMediaId(media.id);
    if (id == null) return Future<void>.value();
    return _service.toggle(
      LibraryWatchlistItem(
        id: id,
        title: media.title,
        posterPath: media.posterPath,
        mediaType: _detailMediaType(media),
        addedAt: DateTime.now(),
        voteAverage: media.rating,
        releaseDate: media.releaseDate,
        overview: media.overview,
      ),
    );
  }

  Future<void> toggleSearchItem(SearchMediaItem item) {
    final id = _numericMediaId(item.id);
    if (id == null) return Future<void>.value();
    return _service.toggle(
      LibraryWatchlistItem(
        id: id,
        title: item.title,
        posterPath: item.posterPath,
        mediaType: _searchMediaType(item),
        addedAt: DateTime.now(),
        voteAverage: item.rating,
        releaseDate: item.year > 0 ? '${item.year}' : null,
        overview: item.overview,
      ),
    );
  }

  @override
  void dispose() {
    _boxListenable.removeListener(notifyListeners);
    super.dispose();
  }

  String _detailMediaType(DetailMedia media) {
    return switch (media.mediaType) {
      DetailMediaType.movie => 'movie',
      DetailMediaType.tv => 'tv',
      DetailMediaType.anime => 'anime',
      DetailMediaType.live => 'tv',
    };
  }

  String _searchMediaType(SearchMediaItem item) {
    return switch (item.mediaType) {
      SearchMediaTypeFilter.movie => 'movie',
      SearchMediaTypeFilter.tv => 'tv',
      SearchMediaTypeFilter.anime => 'anime',
      SearchMediaTypeFilter.all => 'movie',
    };
  }

  int? _numericMediaId(String mediaId) {
    final raw = mediaId.contains(':') ? mediaId.split(':').last : mediaId;
    return int.tryParse(raw);
  }
}
