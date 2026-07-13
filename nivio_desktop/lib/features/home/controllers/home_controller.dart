import 'package:flutter/foundation.dart';
import '../../../core/interfaces/home_repository.dart';
import '../../../core/interfaces/watch_history_repository.dart';
import '../../search/models/search_media_item.dart';

class HomeController extends ChangeNotifier {
  final HomeRepository repository;
  final WatchHistoryRepository watchHistoryRepository;

  HomeController({
    required this.repository,
    required this.watchHistoryRepository,
  });

  bool _isLoadingMovies = true;
  bool _isLoadingTv = true;
  bool _isLoadingHistory = true;
  bool _isLoadingFeatured = true;

  bool _isFetchingMovies = false;
  bool _isFetchingTv = false;
  bool _isFetchingHistory = false;
  bool _isFetchingFeatured = false;

  List<Map<String, dynamic>> _watchHistory = [];

  bool get isLoadingMovies => _isLoadingMovies;
  bool get isLoadingTv => _isLoadingTv;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingFeatured => _isLoadingFeatured;

  String? _moviesError;
  String? _tvError;
  String? _historyError;
  String? _featuredError;

  String? get moviesError => _moviesError;
  String? get tvError => _tvError;
  String? get historyError => _historyError;
  String? get featuredError => _featuredError;

  List<SearchMediaItem> _trendingMovies = [];
  List<SearchMediaItem> _trendingTv = [];
  List<SearchMediaItem> _featuredItems = [];

  List<SearchMediaItem> get trendingMovies => _trendingMovies;
  List<SearchMediaItem> get trendingTv => _trendingTv;
  List<SearchMediaItem> get featuredItems => _featuredItems;
  List<Map<String, dynamic>> get watchHistory => _watchHistory;

  SearchMediaItem? get heroItem =>
      _featuredItems.isNotEmpty ? _featuredItems.first : null;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadAll() async {
    _loadMovies();
    _loadTv();
    _loadHistory();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    if (_isFetchingFeatured) return;
    _isFetchingFeatured = true;
    _isLoadingFeatured = true;
    _featuredError = null;
    notifyListeners();

    try {
      final results = await repository.getFeaturedContent();
      if (_isDisposed) return;
      _featuredItems = results;
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _featuredError = _debugError(
        title: 'Failed to load featured content.',
        endpoint: '/3/trending/all/day',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_isDisposed) {
        _isLoadingFeatured = false;
        _isFetchingFeatured = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadHistory() async {
    if (_isFetchingHistory) return;
    _isFetchingHistory = true;
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      final results = await watchHistoryRepository.getWatchHistory();
      if (_isDisposed) return;
      _watchHistory = results;
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _historyError = _debugError(
        title: 'Failed to load watch history.',
        endpoint: 'WatchHistoryRepository.getWatchHistory',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_isDisposed) {
        _isLoadingHistory = false;
        _isFetchingHistory = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadMovies() async {
    if (_isFetchingMovies) return;
    _isFetchingMovies = true;
    _isLoadingMovies = true;
    _moviesError = null;
    notifyListeners();

    try {
      final results = await repository.getTrendingMovies();
      if (_isDisposed) return;
      _trendingMovies = results;
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _moviesError = _debugError(
        title: 'Failed to load trending movies.',
        endpoint: '/3/trending/movie/day',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_isDisposed) {
        _isLoadingMovies = false;
        _isFetchingMovies = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadTv() async {
    if (_isFetchingTv) return;
    _isFetchingTv = true;
    _isLoadingTv = true;
    _tvError = null;
    notifyListeners();

    try {
      final results = await repository.getTrendingTv();
      if (_isDisposed) return;
      _trendingTv = results;
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _tvError = _debugError(
        title: 'Failed to load trending TV shows.',
        endpoint: '/3/trending/tv/day',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_isDisposed) {
        _isLoadingTv = false;
        _isFetchingTv = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryMovies() async {
    await _loadMovies();
  }

  Future<void> retryTv() async {
    await _loadTv();
  }

  String _debugError({
    required String title,
    required String endpoint,
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!kDebugMode) {
      return title;
    }

    return [
      title,
      'Endpoint: $endpoint',
      'Repository error: $error',
      'Stack trace: $stackTrace',
    ].join('\n');
  }
}
