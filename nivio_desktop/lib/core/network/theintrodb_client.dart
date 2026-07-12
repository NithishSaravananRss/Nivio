import 'package:dio/dio.dart';
import '../errors/network_errors.dart';

class TheIntroDbClient {
  final Dio _dio;

  TheIntroDbClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.theintrodb.org/v3',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  Future<Map<String, dynamic>> getMedia(int tmdbId, int season, int episode) async {
    try {
      final response = await _dio.get(
        '/media',
        queryParameters: {
          'tmdb_id': tmdbId,
          'season': season,
          'episode': episode,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 404 || e.response?.statusCode == 400)) {
         return {}; // Standard empty result for no skip times found
      }
      throw NetworkErrorMapper.fromError(e);
    }
  }
}
