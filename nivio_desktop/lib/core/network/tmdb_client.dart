import 'package:dio/dio.dart';
import '../errors/network_errors.dart';
import '../constants/constants.dart';

class TmdbClient {
  final Dio _dio;

  TmdbClient({required String apiKey, String baseUrl = tmdbBaseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              queryParameters: {'api_key': apiKey},
              headers: {'User-Agent': 'NivioDesktop/1.0'},
            ),
          );

  Future<Map<String, dynamic>> searchMovie(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/3/search/movie',
        queryParameters: {'query': query, 'page': page, 'include_adult': false},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> searchTv(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/3/search/tv',
        queryParameters: {'query': query, 'page': page, 'include_adult': false},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> searchMulti(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/3/search/multi',
        queryParameters: {'query': query, 'page': page, 'include_adult': false},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getSeriesInfo(int showId) async {
    try {
      final response = await _dio.get('/3/tv/$showId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getSeasonInfo(
    int showId,
    int seasonNumber,
  ) async {
    try {
      final response = await _dio.get('/3/tv/$showId/season/$seasonNumber');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getTrending(
    String mediaType,
    String timeWindow,
  ) async {
    try {
      final response = await _dio.get(
        '/3/trending/$mediaType/$timeWindow',
        queryParameters: {'language': 'en'},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getPopular(
    String mediaType, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/3/$mediaType/popular',
        queryParameters: {'language': 'en', 'page': page},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getTopRated(
    String mediaType, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/3/$mediaType/top_rated',
        queryParameters: {'language': 'en', 'page': page},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getWatchProviders(
    int id,
    String mediaType,
  ) async {
    try {
      final response = await _dio.get('/3/$mediaType/$id/watch/providers');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getRecommendations(
    int mediaId,
    String mediaType,
  ) async {
    try {
      final response = await _dio.get('/3/$mediaType/$mediaId/recommendations');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> discover(
    String mediaType,
    Map<String, dynamic> queryParameters,
  ) async {
    try {
      final response = await _dio.get(
        '/3/discover/$mediaType',
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getDetails(
    int id,
    String mediaType, {
    String? appendToResponse,
  }) async {
    try {
      final response = await _dio.get(
        '/3/$mediaType/$id',
        queryParameters: {
          'append_to_response':? appendToResponse,
          'language': 'en',
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getImages(int id, String mediaType) async {
    try {
      final response = await _dio.get('/3/$mediaType/$id/images');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }
}
