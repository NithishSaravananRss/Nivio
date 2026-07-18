import '../interfaces/details_repository.dart';
import '../../features/details/models/detail_models.dart';
import '../../features/details/models/detail_route_args.dart';
import '../../features/details/data/detail_dtos.dart';
import '../../shared/mappers/detail_mapper.dart';
import '../network/anilist_client.dart';
import '../network/tmdb_client.dart';

class TmdbDetailsRepository implements DetailsRepository {
  final TmdbClient client;
  final AniListClient aniListClient;
  final Map<int, List<DetailEpisode>> _animeEpisodesCache = {};

  TmdbDetailsRepository({required this.client, AniListClient? aniListClient})
    : aniListClient = aniListClient ?? AniListClient();

  @override
  Future<DetailMedia> loadCompleteDetail(DetailRouteArgs args) async {
    if (args.mediaType == 'anime') {
      return _loadAnimeDetail(args.mediaId);
    }

    final detailFuture = client.getDetails(
      args.mediaId,
      args.mediaType,
      appendToResponse: 'credits,videos',
    );
    final providersFuture = client.getWatchProviders(
      args.mediaId,
      args.mediaType,
    );
    final recommendationsFuture = client.getRecommendations(
      args.mediaId,
      args.mediaType,
    );
    final imagesFuture = client.getImages(args.mediaId, args.mediaType);

    final results = await Future.wait([
      detailFuture,
      providersFuture,
      recommendationsFuture,
      imagesFuture,
    ]);

    final detailDto = DetailDto(results[0]);
    final creditsDto = CreditsDto(results[0]['credits'] ?? {});
    final videosDto = VideosDto(results[0]['videos'] ?? {});
    final providersDto = ProvidersDto(results[1]);
    final imagesDto = ImagesDto(results[3]);
    final recommendationsList = (results[2]['results'] as List? ?? [])
        .map((r) => Map<String, dynamic>.from(r))
        .toList();

    return DetailMapper.toDetailMedia(
      detailDto: detailDto,
      creditsDto: creditsDto,
      videosDto: videosDto,
      providersDto: providersDto,
      imagesDto: imagesDto,
      recommendationsRaw: recommendationsList,
    );
  }

  @override
  Future<List<DetailEpisode>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
  }) async {
    final cachedAnimeEpisodes = _animeEpisodesCache[tvId];
    if (cachedAnimeEpisodes != null) return cachedAnimeEpisodes;

    final response = await client.getSeasonInfo(tvId, seasonNumber);
    final rawEpisodes = response['episodes'] as List? ?? [];
    return DetailMapper.toEpisodeList(rawEpisodes);
  }

  Future<DetailMedia> _loadAnimeDetail(int anilistId) async {
    const query = '''
      query (\$id: Int) {
        Media(id: \$id, type: ANIME) {
          id
          idMal
          title { romaji english native }
          description
          coverImage { extraLarge large }
          bannerImage
          averageScore
          popularity
          favourites
          seasonYear
          startDate { year month day }
          endDate { year month day }
          episodes
          duration
          status
          format
          genres
          studios(isMain: true) { nodes { name } }
          trailer { site id }
          recommendations(sort: RATING_DESC, perPage: 12) {
            nodes {
              mediaRecommendation {
                id
                title { romaji english }
                coverImage { extraLarge large }
                bannerImage
                averageScore
                seasonYear
                description
              }
            }
          }
        }
      }
    ''';
    final response = await aniListClient.query(
      query,
      variables: {'id': anilistId},
    );
    final media = response['data']?['Media'];
    if (media is! Map) throw Exception('Anime details not found');

    final title = media['title'] as Map?;
    final cover = media['coverImage'] as Map?;
    final studios = media['studios'] is Map
        ? (media['studios']['nodes'] as List? ?? const [])
        : const [];
    final genres = (media['genres'] as List? ?? const [])
        .map((value) => value.toString())
        .toList();
    final episodesCount = (media['episodes'] as num?)?.toInt() ?? 0;
    final durationMinutes = (media['duration'] as num?)?.toInt() ?? 0;
    final startDate = _dateFromAniList(media['startDate']);
    final releaseYear = (media['seasonYear'] ?? startDate.split('-').first)
        .toString();
    final rating = ((media['averageScore'] as num?)?.toDouble() ?? 0) / 10;
    final trailer = media['trailer'] as Map?;

    final episodes = episodesCount > 0
        ? [
            for (var index = 1; index <= episodesCount; index++)
              DetailEpisode(
                number: index,
                title: 'Episode $index',
                runtime: durationMinutes > 0 ? '${durationMinutes}m' : '',
                overview: '',
                progress: 0,
                status: 'Unwatched',
              ),
          ]
        : const <DetailEpisode>[];
    _animeEpisodesCache[anilistId] = episodes;

    final related = <DetailPosterItem>[];
    final recommendationNodes = media['recommendations'] is Map
        ? (media['recommendations']['nodes'] as List? ?? const [])
        : const [];
    for (final rawNode in recommendationNodes) {
      final node = rawNode is Map ? rawNode['mediaRecommendation'] : null;
      if (node is! Map) continue;
      final recTitle = node['title'] as Map?;
      final recCover = node['coverImage'] as Map?;
      final id = (node['id'] as num?)?.toInt();
      if (id == null) continue;
      related.add(
        DetailPosterItem(
          id: 'anime:$id',
          title:
              recTitle?['english']?.toString() ??
              recTitle?['romaji']?.toString() ??
              'Unknown',
          year: node['seasonYear']?.toString() ?? 'N/A',
          rating: (((node['averageScore'] as num?)?.toDouble() ?? 0) / 10)
              .toStringAsFixed(1),
          subtitle: 'Anime',
          posterPath:
              recCover?['extraLarge']?.toString() ??
              recCover?['large']?.toString(),
        ),
      );
    }

    return DetailMedia(
      id: 'anime:$anilistId',
      title:
          title?['english']?.toString() ??
          title?['romaji']?.toString() ??
          'Unknown',
      originalTitle:
          title?['romaji']?.toString() ?? title?['native']?.toString(),
      mediaType: DetailMediaType.anime,
      releaseYear: releaseYear,
      releaseDate: startDate,
      runtime: durationMinutes > 0 ? '${durationMinutes}m' : 'N/A',
      certification: 'TV',
      rating: rating,
      voteCount: (media['favourites'] as num?)?.toInt() ?? 0,
      popularity: (media['popularity'] as num?)?.toDouble() ?? 0,
      genres: genres,
      overview: _stripHtml(media['description']?.toString() ?? ''),
      tagline: media['format']?.toString() ?? '',
      providers: const ['AniList'],
      languages: const ['Japanese'],
      audioTracks: const ['Sub', 'Dub'],
      subtitleTracks: const ['English'],
      productionCompanies: studios
          .whereType<Map>()
          .map((studio) => studio['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      productionCountries: const ['Japan'],
      status: media['status']?.toString() ?? 'Unknown',
      cast: const [],
      crew: const DetailCrew(
        director: 'N/A',
        writer: 'N/A',
        producer: 'N/A',
        composer: 'N/A',
        editor: 'N/A',
        production: 'N/A',
      ),
      related: related,
      moreLikeThis: related,
      seasons: episodes.isEmpty
          ? const []
          : [DetailSeason(number: 1, name: 'Episodes', episodes: episodes)],
      posterPath:
          cover?['extraLarge']?.toString() ?? cover?['large']?.toString(),
      backdropPath: media['bannerImage']?.toString(),
      trailers:
          trailer?['site']?.toString().toLowerCase() == 'youtube' &&
              trailer?['id'] != null
          ? [trailer!['id'].toString()]
          : const [],
      images: [
        if (media['bannerImage'] != null) media['bannerImage'].toString(),
      ],
    );
  }

  String _dateFromAniList(Object? value) {
    if (value is! Map) return '';
    final year = (value['year'] as num?)?.toInt();
    if (year == null) return '';
    final month = ((value['month'] as num?)?.toInt() ?? 1).toString().padLeft(
      2,
      '0',
    );
    final day = ((value['day'] as num?)?.toInt() ?? 1).toString().padLeft(
      2,
      '0',
    );
    return '$year-$month-$day';
  }

  String _stripHtml(String value) =>
      value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
