import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class M3u8VideoResolution {
  const M3u8VideoResolution({required this.quality, required this.url});

  final String quality;
  final String url;
}

class M3u8Track {
  const M3u8Track({required this.language, required this.name});

  final String language;
  final String name;
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

  static Future<Map<String, List<M3u8Track>>> parseTracks(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(headers: headers),
      );
      final content = response.data ?? '';
      final audios = <M3u8Track>[];
      final subtitles = <M3u8Track>[];

      for (final raw in content.split('\n')) {
        final line = raw.trim();
        if (!line.startsWith('#EXT-X-MEDIA:')) continue;
        final type = RegExp(r'TYPE=([A-Z]+)').firstMatch(line)?.group(1);
        final language = RegExp(
          r'LANGUAGE="([^"]+)"',
        ).firstMatch(line)?.group(1);
        final name = RegExp(r'NAME="([^"]+)"').firstMatch(line)?.group(1);
        if (type == null || language == null || name == null) continue;

        final track = M3u8Track(language: language, name: name);
        if (type == 'AUDIO' &&
            !audios.any((item) => item.language == language)) {
          audios.add(track);
        }
        if (type == 'SUBTITLES' &&
            !subtitles.any((item) => item.language == language)) {
          subtitles.add(track);
        }
      }

      return {'audio': audios, 'subtitle': subtitles};
    } catch (error) {
      debugPrint('M3u8Parser parseTracks Error: $error');
      return {'audio': const [], 'subtitle': const []};
    }
  }

  static Future<M3u8Streams> resolveStreams(
    String masterUrl,
    Map<String, String> headers,
    String? audioLang,
    String? subtitleLang,
  ) async {
    try {
      final response = await _dio.get<String>(
        masterUrl,
        options: Options(headers: headers),
      );
      final content = response.data ?? '';
      final lines = content.split('\n');

      if (!content.contains('#EXT-X-STREAM-INF') &&
          !content.contains('#EXT-X-MEDIA')) {
        return M3u8Streams(videoUrl: masterUrl);
      }

      String? videoUrl;
      String? audioUrl;
      String? subtitleUrl;
      String? firstAudioUrl;
      String? firstSubtitleUrl;

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('#EXT-X-MEDIA:')) {
          final type = RegExp(r'TYPE=([A-Z]+)').firstMatch(line)?.group(1);
          final uri = RegExp(r'URI="([^"]+)"').firstMatch(line)?.group(1);
          final language =
              RegExp(r'LANGUAGE="([^"]+)"').firstMatch(line)?.group(1) ??
              RegExp(r'NAME="([^"]+)"').firstMatch(line)?.group(1) ??
              '';
          if (type == null || uri == null) continue;
          final resolved = _resolveUrl(masterUrl, uri);
          final normalizedLanguage = language.toLowerCase();

          if (type == 'AUDIO') {
            firstAudioUrl ??= resolved;
            if (_matchesLanguage(normalizedLanguage, audioLang)) {
              audioUrl = resolved;
            }
          } else if (type == 'SUBTITLES') {
            firstSubtitleUrl ??= resolved;
            if (_matchesLanguage(normalizedLanguage, subtitleLang)) {
              subtitleUrl = resolved;
            }
          }
        }

        if (line.startsWith('#EXT-X-STREAM-INF:') && i + 1 < lines.length) {
          final uri = lines[i + 1].trim();
          if (uri.isNotEmpty && !uri.startsWith('#')) {
            videoUrl ??= _resolveUrl(masterUrl, uri);
          }
        }
      }

      audioUrl ??= firstAudioUrl;
      if (subtitleLang != null &&
          subtitleLang.isNotEmpty &&
          subtitleLang.toLowerCase() != 'off') {
        subtitleUrl ??= firstSubtitleUrl;
      }

      return M3u8Streams(
        videoUrl: videoUrl ?? masterUrl,
        audioUrl: audioUrl,
        subtitleUrl: subtitleUrl,
      );
    } catch (error) {
      debugPrint('M3u8Parser resolveStreams Error: $error');
      return M3u8Streams(videoUrl: masterUrl);
    }
  }

  static Future<List<M3u8Segment>> fetchSegments(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(headers: headers),
      );
      final lines = (response.data ?? '').split('\n');
      final segments = <M3u8Segment>[];
      M3u8EncryptionKey? currentKey;
      double? nextDuration;

      for (final raw in lines) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        if (line.startsWith('#EXT-X-KEY:')) {
          final method = RegExp(r'METHOD=([^,]+)').firstMatch(line)?.group(1);
          final uri = RegExp(r'URI="([^"]+)"').firstMatch(line)?.group(1);
          final iv = RegExp(r'IV=([^,]+)').firstMatch(line)?.group(1);
          if (method != null && uri != null && method != 'NONE') {
            currentKey = M3u8EncryptionKey(
              method: method,
              uri: _resolveUrl(url, uri),
              iv: iv,
            );
          } else if (method == 'NONE') {
            currentKey = null;
          }
          continue;
        }
        if (line.startsWith('#EXTINF:')) {
          nextDuration = double.tryParse(
            line.replaceAll('#EXTINF:', '').split(',').first.trim(),
          );
          continue;
        }
        if (!line.startsWith('#') && nextDuration != null) {
          segments.add(
            M3u8Segment(
              url: _resolveUrl(url, line),
              duration: nextDuration,
              encryptionKey: currentKey,
            ),
          );
          nextDuration = null;
        }
      }
      return segments;
    } catch (error) {
      debugPrint('M3u8Parser fetchSegments Error: $error');
      return const [];
    }
  }

  static bool _matchesLanguage(String language, String? target) {
    final normalizedTarget = target?.toLowerCase().trim();
    if (normalizedTarget == null ||
        normalizedTarget.isEmpty ||
        normalizedTarget == 'off') {
      return false;
    }
    return language.contains(normalizedTarget) ||
        normalizedTarget.contains(language);
  }

  static String _resolveUrl(String baseUrl, String uri) {
    if (uri.startsWith('http')) return uri;
    return Uri.parse(baseUrl).resolve(uri).toString();
  }
}

class M3u8Streams {
  const M3u8Streams({required this.videoUrl, this.audioUrl, this.subtitleUrl});

  final String videoUrl;
  final String? audioUrl;
  final String? subtitleUrl;
}

class M3u8EncryptionKey {
  const M3u8EncryptionKey({required this.method, required this.uri, this.iv});

  final String method;
  final String uri;
  final String? iv;
}

class M3u8Segment {
  const M3u8Segment({
    required this.url,
    required this.duration,
    this.encryptionKey,
  });

  final String url;
  final double duration;
  final M3u8EncryptionKey? encryptionKey;
}
