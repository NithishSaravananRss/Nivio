import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class M3u8VideoResolution {
  const M3u8VideoResolution({required this.quality, required this.url});

  final String quality;
  final String url;
}

class M3u8Parser {
  static final Dio _dio = Dio();

  static Future<List<M3u8VideoResolution>> parseVideoResolutions(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(headers: headers),
      );
      final content = response.data ?? '';
      final lines = content.split('\n');
      final resolutions = <M3u8VideoResolution>[];

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;

        final resMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
        final quality = resMatch == null ? 'auto' : '${resMatch.group(2)}p';
        if (i + 1 >= lines.length) continue;
        final uri = lines[i + 1].trim();
        if (uri.isEmpty || uri.startsWith('#')) continue;

        final resolvedUrl = _resolveUrl(url, uri);
        if (!resolutions.any((item) => item.url == resolvedUrl)) {
          resolutions.add(
            M3u8VideoResolution(quality: quality, url: resolvedUrl),
          );
        }
      }
      return resolutions;
    } catch (error) {
      debugPrint('M3u8Parser parseVideoResolutions Error: $error');
      return const [];
    }
  }

  static String _resolveUrl(String baseUrl, String uri) {
    if (uri.startsWith('http')) return uri;
    return Uri.parse(baseUrl).resolve(uri).toString();
  }
}
