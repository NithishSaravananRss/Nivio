import 'package:dio/dio.dart';
import '../errors/network_errors.dart';

class AniListClient {
  final Dio _dio;

  AniListClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://graphql.anilist.co',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  Future<Map<String, dynamic>> query(String query, {Map<String, dynamic>? variables}) async {
    try {
      final requestData = <String, dynamic>{
        'query': query,
      };
      if (variables != null) {
        requestData['variables'] = variables;
      }
      
      final response = await _dio.post(
        '',
        data: requestData,
      );
      
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('errors')) {
        throw ApiError(data['errors'].toString());
      }
      return data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }

  Future<Map<String, dynamic>> getAniZipMappings(int anilistId) async {
    try {
      final response = await _dio.get(
        'https://api.ani.zip/mappings',
        queryParameters: {'anilist_id': anilistId},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw NetworkErrorMapper.fromError(e);
    }
  }
}
