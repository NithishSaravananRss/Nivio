import 'package:dio/dio.dart';
import '../errors/network_errors.dart';

class AniSkipClient {
  final Dio _dio;

  AniSkipClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.aniskip.com/v2',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  Future<Map<String, dynamic>> getSkipTimes(int malId, int episodeNumber) async {
    try {
      final response = await _dio.get(
        '/skip-times/$malId/$episodeNumber',
        queryParameters: {
          'types': ['op', 'ed', 'recap', 'mixed-op', 'mixed-ed'],
          'episodeLength': 0,
        },
      );
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }
}
