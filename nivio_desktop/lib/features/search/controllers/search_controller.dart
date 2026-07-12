import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/search_media_item.dart';
import 'mock_search_repository.dart';

class SearchController extends ChangeNotifier {
  SearchController({required this._repository});

  final MockSearchRepository _repository;
  Timer? _debounceTimer;

  String _query = '';
  bool _isLoading = false;
  String? _errorMessage;
  List<SearchMediaItem> _results = const [];
  final List<String> _recentSearches = <String>[];
  SearchLanguageFilter _language = SearchLanguageFilter.all;
  SearchMediaTypeFilter _mediaType = SearchMediaTypeFilter.all;
  SearchSortOption _sort = SearchSortOption.defaultOrder;
  SearchViewMode _viewMode = SearchViewMode.grid;
  bool _initialized = false;

  String get query => _query;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SearchMediaItem> get results => List.unmodifiable(_results);
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  SearchLanguageFilter get language => _language;
  SearchMediaTypeFilter get mediaType => _mediaType;
  SearchSortOption get sort => _sort;
  SearchViewMode get viewMode => _viewMode;
  bool get hasError => _errorMessage != null;
  bool get hasResults => _results.isNotEmpty;
  bool get hasActiveFilters =>
      _language != SearchLanguageFilter.all ||
      _mediaType != SearchMediaTypeFilter.all ||
      _sort != SearchSortOption.defaultOrder;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await _runSearch();
  }

  void setQuery(String value) {
    if (_query == value) {
      return;
    }

    _query = value;
    _scheduleSearch();
    notifyListeners();
  }

  Future<void> submitQuery() async {
    _debounceTimer?.cancel();
    await _runSearch();
  }

  Future<void> retry() async {
    _debounceTimer?.cancel();
    await _runSearch();
  }

  void setLanguage(SearchLanguageFilter value) {
    if (_language == value) {
      return;
    }
    _language = value;
    unawaited(_runSearch());
    notifyListeners();
  }

  void setMediaType(SearchMediaTypeFilter value) {
    if (_mediaType == value) {
      return;
    }
    _mediaType = value;
    unawaited(_runSearch());
    notifyListeners();
  }

  void setSort(SearchSortOption value) {
    if (_sort == value) {
      return;
    }
    _sort = value;
    unawaited(_runSearch());
    notifyListeners();
  }

  void setViewMode(SearchViewMode value) {
    if (_viewMode == value) {
      return;
    }
    _viewMode = value;
    notifyListeners();
  }

  void clearFilters() {
    _language = SearchLanguageFilter.all;
    _mediaType = SearchMediaTypeFilter.all;
    _sort = SearchSortOption.defaultOrder;
    unawaited(_runSearch());
    notifyListeners();
  }

  void _scheduleSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_runSearch());
    });
  }

  Future<void> _runSearch() async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _repository.search(
        query: _query,
        language: _language,
        mediaType: _mediaType,
        sort: _sort,
      );
      _results = results;
      if (_query.trim().isNotEmpty && results.isNotEmpty) {
        _pushRecentSearch(_query.trim());
      }
    } catch (_) {
      _results = const [];
      _errorMessage = 'We could not load search results right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _pushRecentSearch(String query) {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 5) {
      _recentSearches.removeRange(5, _recentSearches.length);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
