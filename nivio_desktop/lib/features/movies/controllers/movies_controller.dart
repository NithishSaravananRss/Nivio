import 'package:flutter/foundation.dart';

import '../../search/models/search_media_item.dart';
import '../models/movie_category.dart';
import '../models/movie_genre.dart';
import '../models/movie_page.dart';
import '../repositories/movies_repository.dart';

enum MoviesStatus { initial, loading, loaded, empty, offline, apiError, error }

class MoviesController extends ChangeNotifier {
  MoviesController({required this.repository});

  final MoviesRepository repository;
  final Map<String, _MoviesBucket> _buckets = <String, _MoviesBucket>{};

  bool _isDisposed = false;
  bool _initialized = false;
  bool _isLoadingGenres = false;
  String? _genreError;
  List<MovieGenre> _genres = const [];
  MovieCategory _selectedCategory = MovieCategory.trending;
  MovieGenre? _selectedGenre;
  double _scrollOffset = 0;

  List<MovieGenre> get genres => List.unmodifiable(_genres);
  MovieCategory get selectedCategory => _selectedCategory;
  MovieGenre? get selectedGenre => _selectedGenre;
  bool get isLoadingGenres => _isLoadingGenres;
  String? get genreError => _genreError;

  _MoviesBucket get _bucket => _buckets.putIfAbsent(
    _bucketKey(_selectedCategory, _selectedGenre?.id),
    _MoviesBucket.new,
  );

  List<SearchMediaItem> get movies => List.unmodifiable(_bucket.items);
  MoviesStatus get status => _bucket.status;
  String? get errorMessage => _bucket.errorMessage;
  bool get isInitialLoading =>
      _bucket.status == MoviesStatus.loading && _bucket.items.isEmpty;
  bool get isLoadingMore => _bucket.isLoadingMore;
  bool get hasMore => _bucket.hasMore;
  double get scrollOffset => _scrollOffset;

  void saveScrollOffset(double offset) {
    _scrollOffset = offset;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await Future.wait([loadGenres(), refresh()]);
  }

  Future<void> loadGenres() async {
    if (_isDisposed || _isLoadingGenres) return;
    _isLoadingGenres = true;
    _genreError = null;
    notifyListeners();

    try {
      final genres = await repository.getGenres();
      if (_isDisposed) return;
      _genres = genres;
    } catch (_) {
      if (_isDisposed) return;
      _genreError = 'We could not load movie genres right now.';
    } finally {
      if (!_isDisposed) {
        _isLoadingGenres = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() => refresh(force: true);

  Future<void> refresh({bool force = false}) async {
    if (_isDisposed) return;
    final bucket = _bucket;
    if (bucket.isLoading || bucket.isLoadingMore) return;
    if (!force && bucket.items.isNotEmpty) return;

    bucket
      ..isLoading = true
      ..errorMessage = null
      ..status = MoviesStatus.loading;
    notifyListeners();

    try {
      final page = await repository.getMovies(
        category: _selectedCategory,
        genreId: _selectedGenre?.id,
        page: 1,
      );
      if (_isDisposed) return;
      bucket.replace(page);
    } catch (error) {
      if (_isDisposed) return;
      bucket.fail(error, initialLoad: bucket.items.isEmpty);
    } finally {
      if (!_isDisposed) {
        bucket.isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isDisposed) return;
    final bucket = _bucket;
    if (bucket.isLoading || bucket.isLoadingMore || !bucket.hasMore) return;

    bucket.isLoadingMore = true;
    notifyListeners();

    try {
      final page = await repository.getMovies(
        category: _selectedCategory,
        genreId: _selectedGenre?.id,
        page: bucket.page + 1,
      );
      if (_isDisposed) return;
      bucket.append(page);
    } catch (_) {
      if (_isDisposed) return;
      bucket.hasMore = false;
    } finally {
      if (!_isDisposed) {
        bucket.isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectCategory(MovieCategory category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    await refresh();
  }

  Future<void> selectGenre(MovieGenre? genre) async {
    if (_selectedGenre?.id == genre?.id) return;
    _selectedGenre = genre;
    notifyListeners();
    await refresh();
  }

  static String _bucketKey(MovieCategory category, int? genreId) {
    return '${category.name}:${genreId ?? 'all'}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class _MoviesBucket {
  List<SearchMediaItem> items = <SearchMediaItem>[];
  int page = 0;
  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  MoviesStatus status = MoviesStatus.initial;
  String? errorMessage;

  void replace(MoviePage moviePage) {
    items = moviePage.items;
    page = moviePage.page;
    hasMore = moviePage.hasMore && moviePage.items.isNotEmpty;
    status = items.isEmpty ? MoviesStatus.empty : MoviesStatus.loaded;
    errorMessage = null;
  }

  void append(MoviePage moviePage) {
    final seen = items.map((item) => item.id).toSet();
    final nextItems = moviePage.items
        .where((item) => seen.add(item.id))
        .toList(growable: false);
    items = [...items, ...nextItems];
    page = moviePage.page;
    hasMore = moviePage.hasMore && nextItems.isNotEmpty;
    status = items.isEmpty ? MoviesStatus.empty : MoviesStatus.loaded;
    errorMessage = null;
  }

  void fail(Object error, {required bool initialLoad}) {
    errorMessage = 'We could not load movies right now.';
    if (!initialLoad) {
      status = items.isEmpty ? MoviesStatus.error : MoviesStatus.loaded;
      return;
    }

    final text = error.toString().toLowerCase();
    if (text.contains('internet') || text.contains('connection')) {
      status = MoviesStatus.offline;
    } else if (text.contains('api') || text.contains('status')) {
      status = MoviesStatus.apiError;
    } else {
      status = MoviesStatus.error;
    }
    hasMore = false;
  }
}
