import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/core/network/anilist_client.dart';
import 'package:nivio_desktop/core/network/tmdb_client.dart';
import 'package:nivio_desktop/core/repositories/tmdb_details_repository.dart';
import 'package:nivio_desktop/features/details/data/detail_dtos.dart';
import 'package:nivio_desktop/features/details/models/detail_route_args.dart';
import 'package:nivio_desktop/shared/mappers/detail_mapper.dart';

void main() {
  group('detail episode data', () {
    test('hydrates anime episodes from AniZip metadata', () async {
      final repository = TmdbDetailsRepository(
        client: TmdbClient(
          apiKey: 'test',
          dio: _dio('https://api.themoviedb.org', (_) => {}),
        ),
        aniListClient: AniListClient(
          dio: _dio('https://graphql.anilist.co', (options) {
            if (options.uri.host == 'api.ani.zip') {
              return {
                'episodes': {
                  '2': {
                    'title': {'en': 'Second Step'},
                    'overview': 'The next part.',
                    'runtime': 23,
                    'airDate': '2024-01-08',
                  },
                  '1': {
                    'title': {'en': 'First Step'},
                    'summary': 'The beginning.',
                    'image': 'https://image.test/1.jpg',
                    'runtime': 24,
                    'airDate': '2024-01-01',
                  },
                },
              };
            }
            return {
              'data': {'Media': _animeMedia(id: 321, episodes: 0)},
            };
          }),
        ),
      );

      final media = await repository.loadCompleteDetail(
        const DetailRouteArgs(mediaType: 'anime', mediaId: 321),
      );
      final episodes = await repository.getSeasonEpisodes(
        tvId: 321,
        seasonNumber: 1,
      );

      expect(media.seasons, hasLength(1));
      expect(episodes.map((episode) => episode.number), [1, 2]);
      expect(episodes.first.title, 'First Step');
      expect(episodes.first.overview, 'The beginning.');
      expect(episodes.first.stillPath, 'https://image.test/1.jpg');
    });

    test(
      'infers anime episode count from next airing when AniZip is empty',
      () async {
        final repository = TmdbDetailsRepository(
          client: TmdbClient(
            apiKey: 'test',
            dio: _dio('https://api.themoviedb.org', (_) => {}),
          ),
          aniListClient: AniListClient(
            dio: _dio('https://graphql.anilist.co', (options) {
              if (options.uri.host == 'api.ani.zip') {
                return {'episodes': <String, dynamic>{}};
              }
              return {
                'data': {
                  'Media': _animeMedia(
                    id: 654,
                    episodes: 0,
                    nextAiringEpisode: 4,
                    airedEpisodes: const {1: 1704067200, 2: 1704672000},
                  ),
                },
              };
            }),
          ),
        );

        await repository.loadCompleteDetail(
          const DetailRouteArgs(mediaType: 'anime', mediaId: 654),
        );
        final episodes = await repository.getSeasonEpisodes(
          tvId: 654,
          seasonNumber: 1,
        );

        expect(episodes.map((episode) => episode.number), [1, 2, 3]);
        expect(episodes.first.airDate, '2024-01-01');
      },
    );

    test('maps fallback TV seasons from TMDB counts', () {
      final media = DetailMapper.toDetailMedia(
        detailDto: const DetailDto({
          'id': 42,
          'media_type': 'tv',
          'name': 'Count Only Show',
          'first_air_date': '2024-01-01',
          'number_of_seasons': 2,
          'number_of_episodes': 16,
          'seasons': [],
        }),
        creditsDto: const CreditsDto({}),
        videosDto: const VideosDto({}),
        providersDto: const ProvidersDto({}),
        imagesDto: const ImagesDto({}),
        recommendationsRaw: const [],
      );

      expect(media.seasons.map((season) => season.number), [1, 2]);
      expect(media.seasons.map((season) => season.name), [
        'Season 1',
        'Season 2',
      ]);
    });

    test('maps TMDB rating, external IDs, and last/next episodes', () {
      final media = DetailMapper.toDetailMedia(
        detailDto: const DetailDto({
          'id': 1399,
          'media_type': 'tv',
          'name': 'Rich Detail Show',
          'first_air_date': '2011-04-17',
          'content_ratings': {
            'results': [
              {'iso_3166_1': 'US', 'rating': 'TV-MA'},
            ],
          },
          'external_ids': {'imdb_id': 'tt0944947', 'tvdb_id': 121361},
          'last_episode_to_air': {
            'episode_number': 6,
            'name': 'Finale',
            'runtime': 58,
            'air_date': '2019-05-19',
          },
          'next_episode_to_air': {
            'episode_number': 7,
            'name': 'Aftermath',
            'runtime': 55,
            'air_date': '2019-05-26',
          },
          'seasons': [],
        }),
        creditsDto: const CreditsDto({}),
        videosDto: const VideosDto({}),
        providersDto: const ProvidersDto({}),
        imagesDto: const ImagesDto({}),
        recommendationsRaw: const [],
      );

      expect(media.certification, 'TV-MA');
      expect(media.externalIds?['imdb_id'], 'tt0944947');
      expect(media.lastEpisode?.title, 'Finale');
      expect(media.lastEpisode?.runtime, '58m');
      expect(media.nextEpisode?.number, 7);
    });
  });
}

Map<String, dynamic> _animeMedia({
  required int id,
  required int episodes,
  int? nextAiringEpisode,
  Map<int, int> airedEpisodes = const {},
}) {
  return {
    'id': id,
    'idMal': id + 1000,
    'title': {'english': 'Anime $id', 'romaji': 'Anime Romaji $id'},
    'description': 'Description',
    'coverImage': {'extraLarge': 'https://image.test/poster.jpg'},
    'bannerImage': 'https://image.test/banner.jpg',
    'averageScore': 80,
    'popularity': 100,
    'favourites': 20,
    'seasonYear': 2024,
    'startDate': {'year': 2024, 'month': 1, 'day': 1},
    'endDate': {'year': null, 'month': null, 'day': null},
    'episodes': episodes,
    'duration': 24,
    'status': 'RELEASING',
    'format': 'TV',
    'genres': ['Action'],
    'nextAiringEpisode': nextAiringEpisode == null
        ? null
        : {'episode': nextAiringEpisode},
    'airingSchedule': {
      'nodes': [
        for (final entry in airedEpisodes.entries)
          {'episode': entry.key, 'airingAt': entry.value},
      ],
    },
    'studios': {'nodes': []},
    'trailer': null,
    'recommendations': {'nodes': []},
  };
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
