import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/core/network/anilist_client.dart';
import 'package:nivio_desktop/core/network/aniskip_client.dart';
import 'package:nivio_desktop/core/network/theintrodb_client.dart';
import 'package:nivio_desktop/features/player/models/playback_request.dart';
import 'package:nivio_desktop/features/player/services/skip_times_service.dart';

void main() {
  group('DesktopSkipTimesService', () {
    test('fetches anime skip times through AniList and AniSkip', () async {
      final aniListRequests = <RequestOptions>[];
      final aniSkipRequests = <RequestOptions>[];
      final service = DesktopSkipTimesService(
        aniListClient: AniListClient(
          dio: _dio('https://graphql.anilist.co', (options) {
            aniListRequests.add(options);
            return {
              'data': {
                'Media': {'idMal': 21},
              },
            };
          }),
        ),
        aniSkipClient: AniSkipClient(
          dio: _dio('https://api.aniskip.com/v2', (options) {
            aniSkipRequests.add(options);
            return {
              'found': true,
              'results': [
                {
                  'skipType': 'op',
                  'interval': {'startTime': 84.5, 'endTime': 174.2},
                },
                {
                  'skipType': 'ed',
                  'interval': {'startTime': 1320, 'endTime': 1410},
                },
              ],
            };
          }),
        ),
        theIntroDbClient: TheIntroDbClient(
          dio: _dio('https://unused', (_) => {}),
        ),
      );

      final skipTimes = await service.getSkipTimes(
        const PlaybackRequest(
          mediaId: 'anime:123',
          title: 'One Piece',
          mediaType: PlaybackMediaType.anime,
          season: 1,
          episode: 7,
        ),
      );

      expect(aniListRequests.single.data['variables'], {'id': 123});
      expect(aniSkipRequests.single.path, '/skip-times/21/7');
      expect(skipTimes, hasLength(2));
      expect(skipTimes.first.type, 'op');
      expect(skipTimes.first.startTime, const Duration(milliseconds: 84500));
      expect(skipTimes.first.endTime, const Duration(milliseconds: 174200));
    });

    test('fetches TV skip times through TheIntroDB', () async {
      final requests = <RequestOptions>[];
      final service = DesktopSkipTimesService(
        aniListClient: AniListClient(dio: _dio('https://unused', (_) => {})),
        aniSkipClient: AniSkipClient(dio: _dio('https://unused', (_) => {})),
        theIntroDbClient: TheIntroDbClient(
          dio: _dio('https://api.theintrodb.org/v3', (options) {
            requests.add(options);
            return {
              'intro': [
                {'start_ms': 10000, 'end_ms': 70000},
              ],
              'credits': [
                {'start_ms': 1700000, 'end_ms': null},
              ],
              'recap': [
                {'start_ms': 0, 'end_ms': 45000},
              ],
            };
          }),
        ),
      );

      final skipTimes = await service.getSkipTimes(
        const PlaybackRequest(
          mediaId: 'tv:1399',
          title: 'Game of Thrones',
          mediaType: PlaybackMediaType.tv,
          season: 2,
          episode: 4,
        ),
      );

      expect(requests.single.queryParameters, {
        'tmdb_id': 1399,
        'season': 2,
        'episode': 4,
      });
      expect(skipTimes.map((skip) => skip.type), ['op', 'ed', 'recap']);
      expect(skipTimes[1].endTime, const Duration(hours: 99));
    });
  });
}

Dio _dio(String baseUrl, Object? Function(RequestOptions options) handler) {
  return Dio(BaseOptions(baseUrl: baseUrl))
    ..httpClientAdapter = _JsonAdapter(handler);
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.handler);

  final Object? Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(handler(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
