import 'package:dio/dio.dart';

import '../../../shared/models/stream_result.dart';
import '../models/playback_request.dart';

class NetMirrorStreamProvider {
  NetMirrorStreamProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              validateStatus: (status) => status != null && status < 600,
            ),
          );

  final Dio _dio;

  Future<StreamResult?> resolve(PlaybackRequest request) async {
    final id = request.numericMediaId;
    if (id == null) return null;

    final isSeries = request.mediaType != PlaybackMediaType.movie;
    final season = request.season ?? 1;
    final episode = request.episode ?? 1;

    try {
      final variantsUrl = isSeries
          ? 'https://net27.cc/api/variants-tmdb/tv/$id?se=$season&ep=$episode'
          : 'https://net27.cc/api/variants-tmdb/movie/$id';
      final variantsResponse = await _dio.get<Object?>(
        variantsUrl,
        options: Options(headers: const {'Accept': 'application/json'}),
      );

      final variants = _asMap(variantsResponse.data);
      final defaultSubjectId = variants?['defaultSubjectId']?.toString();
      final defaultDetailPath = variants?['defaultDetailPath']?.toString();

      var url =
          'https://net27.cc/api/embed-tmdb/$id?type=${isSeries ? 'tv' : 'movie'}&se=$season&ep=$episode';
      if (defaultSubjectId != null && defaultDetailPath != null) {
        url +=
            '&sid=${Uri.encodeQueryComponent(defaultSubjectId)}&dp=${Uri.encodeQueryComponent(defaultDetailPath)}';
      }

      final response = await _dio.get<Object?>(
        url,
        options: Options(
          headers: const {
            'Accept': 'application/json',
            'User-Agent': _desktopUserAgent,
          },
        ),
      );
      if (response.statusCode != 200) return null;

      final data = _asMap(response.data);
      if (data == null || data['ok'] != true) return null;

      final sources = <StreamSource>[];
      final rawStreams = data['streams'];
      if (rawStreams is List) {
        for (final raw in rawStreams) {
          final stream = _asMap(raw);
          final streamUrl = stream?['url']?.toString();
          if (streamUrl == null || streamUrl.isEmpty) continue;
          final resolution = stream?['resolution']?.toString() ?? 'auto';
          sources.add(
            StreamSource(
              url: streamUrl,
              quality: resolution.endsWith('p') ? resolution : '${resolution}p',
              isM3U8: _isHls(streamUrl),
            ),
          );
        }
      }

      final mp4 = data['mp4']?.toString();
      if (sources.isEmpty && mp4 != null && mp4.isNotEmpty) {
        final resolution = data['resolution']?.toString() ?? 'auto';
        sources.add(
          StreamSource(
            url: mp4,
            quality: resolution.endsWith('p') ? resolution : '${resolution}p',
            isM3U8: _isHls(mp4),
          ),
        );
      }
      if (sources.isEmpty) return null;

      sources.sort(
        (a, b) => _resolution(b.quality).compareTo(_resolution(a.quality)),
      );

      final subtitles = <SubtitleTrack>[];
      final captions = data['captions'];
      if (captions is List) {
        for (final raw in captions) {
          final caption = _asMap(raw);
          var subtitleUrl = caption?['url']?.toString();
          if (subtitleUrl == null || subtitleUrl.isEmpty) continue;
          if (subtitleUrl.startsWith('/')) {
            subtitleUrl = 'https://net27.cc$subtitleUrl';
          }
          subtitles.add(
            SubtitleTrack(
              url: subtitleUrl,
              lang:
                  caption?['name']?.toString() ??
                  caption?['lang']?.toString() ??
                  'Unknown',
            ),
          );
        }
      }

      final selected = sources.first;
      return StreamResult(
        url: selected.url,
        quality: selected.quality,
        provider: 'Nivio',
        subtitles: subtitles,
        availableQualities: sources.map((source) => source.quality).toList(),
        isM3U8: selected.isM3U8,
        headers: const {
          'Referer': 'https://videodownloader.site/',
          'User-Agent': _desktopUserAgent,
        },
        sources: sources,
      );
    } on DioException {
      return null;
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static bool _isHls(String url) =>
      url.toLowerCase().contains('.m3u8') ||
      url.toLowerCase().contains('application/vnd.apple.mpegurl');

  static int _resolution(String quality) =>
      int.tryParse(quality.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
}

const String _desktopUserAgent =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36';
