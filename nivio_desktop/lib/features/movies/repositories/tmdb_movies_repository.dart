import 'package:dio/dio.dart';

import '../../../core/constants/constants.dart';
import '../../../core/errors/network_errors.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../shared/dto/media_dto.dart';
import '../../../shared/mappers/media_mapper.dart';
import '../../search/models/search_media_item.dart';
import '../models/movie_category.dart';
import '../models/movie_genre.dart';
import '../models/movie_page.dart';
import 'movies_repository.dart';

class TmdbMoviesRepository implements MoviesRepository {
  TmdbMoviesRepository({required this.client, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: tmdbBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              queryParameters: {'api_key': tmdbApiKey},
              headers: {'User-Agent': 'NivioDesktop/1.0'},
            ),
          );

  final TmdbClient client;
  final Dio _dio;

  final Map<String, MoviePage> _pageCache = <String, MoviePage>{};
  List<MovieGenre>? _genreCache;

  @override
  Future<List<MovieGenre>> getGenres() async {
    final cached = _genreCache;
    if (cached != null) return cached;

    try {
      final response = await _dio.get(
        '/3/genre/movie/list',
        queryParameters: {'language': 'en'},
      );
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Invalid genre response format');
      }
      final rawGenres = data['genres'];
      if (rawGenres is! List) return const [];

      final genres = rawGenres
          .whereType<Map>()
          .map((genre) {
            final id = (genre['id'] as num?)?.toInt();
            final name = genre['name'] as String?;
            if (id == null || name == null || name.trim().isEmpty) {
              return null;
            }
            return MovieGenre(id: id, name: name);
          })
          .whereType<MovieGenre>()
          .toList(growable: false);

      _genreCache = genres;
      return genres;
    } on AppNetworkError {
      rethrow;
    } catch (error) {
      throw NetworkErrorMapper.fromError(error);
    }
  }

  @override
  Future<MoviePage> getMovies({
    required MovieCategory category,
    int? genreId,
    int page = 1,
  }) async {
    if (page < 1) {
      return const MoviePage(items: [], page: 1, totalPages: 1);
    }

    final cacheKey = '${category.name}:${genreId ?? 'all'}:$page';
    final cached = _pageCache[cacheKey];
    if (cached != null) return cached;

    try {
      final response = genreId == null
          ? await _loadCategory(category, page)
          : await _discoverByGenre(
              category: category,
              genreId: genreId,
              page: page,
            );
      final moviePage = _parseMoviePage(response, page);
      _pageCache[cacheKey] = moviePage;
      return moviePage;
    } on AppNetworkError {
      rethrow;
    } catch (error) {
      throw NetworkErrorMapper.fromError(error);
    }
  }

  Future<Map<String, dynamic>> _loadCategory(
    MovieCategory category,
    int page,
  ) async {
    switch (category) {
      case MovieCategory.trending:
        if (page == 1) {
          return client.getTrending('movie', 'day');
        }
        return _discoverByCategory(category: category, page: page);
      case MovieCategory.popular:
        return client.getPopular('movie', page: page);
      case MovieCategory.topRated:
        return client.getTopRated('movie', page: page);
      case MovieCategory.nowPlaying:
        return _getMovieList('now_playing', page);
      case MovieCategory.upcoming:
        return _getMovieList('upcoming', page);
    }
  }

  Future<Map<String, dynamic>> _getMovieList(String list, int page) async {
    final response = await _dio.get(
      '/3/movie/$list',
      queryParameters: {'language': 'en', 'page': page},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> _discoverByGenre({
    required MovieCategory category,
    required int genreId,
    required int page,
  }) {
    return _discoverByCategory(
      category: category,
      page: page,
      extraParameters: {'with_genres': genreId},
    );
  }

  Future<Map<String, dynamic>> _discoverByCategory({
    required MovieCategory category,
    required int page,
    Map<String, dynamic> extraParameters = const {},
  }) {
    final parameters = <String, dynamic>{
      'language': 'en',
      'page': page,
      'include_adult': false,
      'include_video': false,
      'sort_by': switch (category) {
        MovieCategory.trending => 'popularity.desc',
        MovieCategory.popular => 'popularity.desc',
        MovieCategory.nowPlaying => 'primary_release_date.desc',
        MovieCategory.topRated => 'vote_average.desc',
        MovieCategory.upcoming => 'primary_release_date.asc',
      },
      ...extraParameters,
    };

    if (category == MovieCategory.topRated) {
      parameters['vote_count.gte'] = 200;
    }

    final today = DateTime.now();
    final todayText = _dateText(today);
    if (category == MovieCategory.nowPlaying) {
      parameters['primary_release_date.lte'] = todayText;
      parameters['primary_release_date.gte'] = _dateText(
        today.subtract(const Duration(days: 45)),
      );
    } else if (category == MovieCategory.upcoming) {
      parameters['primary_release_date.gte'] = todayText;
    }

    return client.discover('movie', parameters);
  }

  MoviePage _parseMoviePage(Map<String, dynamic> response, int fallbackPage) {
    final searchResponse = SearchResponseDto.fromJson(response);
    final page = searchResponse.page == 0 ? fallbackPage : searchResponse.page;
    final totalPages = searchResponse.totalPages < page
        ? page
        : searchResponse.totalPages;
    final items = searchResponse.results
        .map((dto) => _toMovieItem(dto))
        .where((item) => item.title.trim().isNotEmpty)
        .toList(growable: false);

    return MoviePage(items: items, page: page, totalPages: totalPages);
  }

  SearchMediaItem _toMovieItem(MediaDto dto) {
    final movieDto = MediaDto(
      id: dto.id,
      malId: dto.malId,
      title: dto.title,
      type: 'movie',
      posterPath: dto.posterPath,
      backdropPath: dto.backdropPath,
      overview: dto.overview,
      voteAverage: dto.voteAverage,
      releaseDate: dto.releaseDate,
      originalLanguage: dto.originalLanguage,
    );
    return MediaMapper.toSearchMediaItem(movieDto);
  }

  String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
