import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/interfaces/home_repository.dart';
import '../../../core/interfaces/watch_history_repository.dart';
import '../../search/models/search_media_item.dart';

class HomeSectionState {
  const HomeSectionState({
    this.isLoading = true,
    this.items = const [],
    this.error,
  });

  final bool isLoading;
  final List<SearchMediaItem> items;
  final String? error;

  HomeSectionState copyWith({
    bool? isLoading,
    List<SearchMediaItem>? items,
    String? error,
    bool clearError = false,
  }) {
    return HomeSectionState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class HomeController extends ChangeNotifier {
  final HomeRepository repository;
  final WatchHistoryRepository watchHistoryRepository;

  HomeController({
    required this.repository,
    required this.watchHistoryRepository,
  }) {
    if (watchHistoryRepository case final Listenable listenable) {
      _historyListenable = listenable;
      listenable.addListener(_onHistoryChanged);
    }
  }

  Listenable? _historyListenable;

  bool _isLoadingHistory = true;
  bool _isLoadingFeatured = true;
  bool _isLoadingRecommendations = true;

  bool _isFetchingHistory = false;
  bool _historyRefreshPending = false;
  bool _isFetchingFeatured = false;
  bool _isFetchingRecommendations = false;
  final Set<String> _fetchingSections = {};

  List<Map<String, dynamic>> _watchHistory = [];

  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingRecommendations => _isLoadingRecommendations;

  String? _historyError;
  String? _featuredError;
  String? _recommendationsError;

  String? get historyError => _historyError;
  String? get featuredError => _featuredError;
  String? get recommendationsError => _recommendationsError;

  final Map<String, HomeSectionState> _sections = {
    for (final id in sectionOrder) id: const HomeSectionState(),
  };
  List<SearchMediaItem> _featuredItems = [];
  List<SearchMediaItem> _recommendations = [];

  static const sectionOrder = [
    'popular_movies',
    'trending_movies',
    'top_rated_movies',
    'popular_tv',
    'trending_tv',
    'popular_anime',
    'trending_anime',
    'tamil',
    'telugu',
    'hindi',
    'malayalam',
    'korean',
  ];

  static const sectionTitles = {
    'popular_movies': 'All Time Popular',
    'trending_movies': 'Trending Now',
    'top_rated_movies': 'Top Rated Movies',
    'popular_tv': 'Popular TV Shows',
    'trending_tv': 'Trending TV Shows',
    'popular_anime': 'Popular Anime',
    'trending_anime': 'Trending Anime',
    'tamil': 'Tamil Picks',
    'telugu': 'Telugu Picks',
    'hindi': 'Hindi Picks',
    'malayalam': 'Malayalam Picks',
    'korean': 'Korean Dramas',
  };

  Map<String, HomeSectionState> get sections => Map.unmodifiable(_sections);
  List<SearchMediaItem> get featuredItems => _featuredItems;
  List<SearchMediaItem> get recommendations => _recommendations;
  List<Map<String, dynamic>> get watchHistory => _watchHistory;

  SearchMediaItem? get heroItem =>
      _featuredItems.isNotEmpty ? _featuredItems.first : null;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _historyListenable?.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    if (_isDisposed) return;
    if (_isFetchingHistory) {
      _historyRefreshPending = true;
      return;
    }
    unawaited(_loadHistory());
  }

  Future<void> loadAll() async {
    _loadHistory();
    _loadFeatured();
    for (final sectionId in sectionOrder) {
      _loadSection(sectionId);
    }
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
      _watchHistory = results.where(_isIncompleteHistoryItem).take(10).toList();
      _loadRecommendations();
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
        if (_historyRefreshPending) {
          _historyRefreshPending = false;
          unawaited(_loadHistory());
        }
      }
    }
  }

  Future<void> _loadRecommendations() async {
    if (_isFetchingRecommendations) return;
    if (_watchHistory.isEmpty) {
      _isLoadingRecommendations = false;
      _recommendations = [];
      _recommendationsError = null;
      notifyListeners();
      return;
    }
    _isFetchingRecommendations = true;
    _isLoadingRecommendations = true;
    _recommendationsError = null;
    notifyListeners();

    try {
      final results = await repository.getRecommendationsForHistory(
        _watchHistory,
      );
      if (_isDisposed) return;
      _recommendations = results;
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _recommendationsError = _debugError(
        title: 'Failed to load recommendations.',
        endpoint: '/3/{mediaType}/{id}/recommendations',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_isDisposed) {
        _isLoadingRecommendations = false;
        _isFetchingRecommendations = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadSection(String sectionId) async {
    if (_fetchingSections.contains(sectionId)) return;
    _fetchingSections.add(sectionId);
    _sections[sectionId] = (_sections[sectionId] ?? const HomeSectionState())
        .copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final results = await _fetchSection(sectionId);
      if (_isDisposed) return;
      _sections[sectionId] = HomeSectionState(isLoading: false, items: results);
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _sections[sectionId] = HomeSectionState(
        isLoading: false,
        error: _debugError(
          title: 'Failed to load ${sectionTitles[sectionId] ?? sectionId}.',
          endpoint: _sectionEndpoint(sectionId),
          error: e,
          stackTrace: stackTrace,
        ),
      );
    } finally {
      _fetchingSections.remove(sectionId);
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<List<SearchMediaItem>> _fetchSection(String sectionId) {
    return switch (sectionId) {
      'popular_movies' => repository.getPopularMovies(),
      'trending_movies' => repository.getTrendingMovies(),
      'top_rated_movies' => repository.getTopRatedMovies(),
      'popular_tv' => repository.getPopularTv(),
      'trending_tv' => repository.getTrendingTv(),
      'popular_anime' => repository.getPopularAnime(),
      'trending_anime' => repository.getTrendingAnime(),
      'tamil' => repository.getTamilPicks(),
      'telugu' => repository.getTeluguPicks(),
      'hindi' => repository.getHindiPicks(),
      'malayalam' => repository.getMalayalamPicks(),
      'korean' => repository.getKoreanDramas(),
      _ => Future.value(const <SearchMediaItem>[]),
    };
  }

  Future<void> retrySection(String sectionId) async {
    await _loadSection(sectionId);
  }

  Future<void> retryRecommendations() async {
    await _loadRecommendations();
  }

  bool _isIncompleteHistoryItem(Map<String, dynamic> item) {
    return item['isCompleted'] != true;
  }

  String _sectionEndpoint(String sectionId) {
    return switch (sectionId) {
      'popular_movies' => '/3/movie/popular',
      'trending_movies' => '/3/trending/movie/day',
      'top_rated_movies' => '/3/movie/top_rated',
      'popular_tv' => '/3/tv/popular',
      'trending_tv' => '/3/trending/tv/day',
      'popular_anime' => 'AniList POPULARITY_DESC',
      'trending_anime' => 'AniList TRENDING_DESC',
      'tamil' => '/3/discover/movie?with_original_language=ta',
      'telugu' => '/3/discover/movie?with_original_language=te',
      'hindi' => '/3/discover/movie?with_original_language=hi',
      'malayalam' => '/3/discover/movie?with_original_language=ml',
      'korean' => '/3/discover/tv?with_original_language=ko',
      _ => sectionId,
    };
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
