import '../interfaces/details_repository.dart';
import '../../features/details/models/detail_models.dart';
import '../../features/details/models/detail_route_args.dart';
import '../../features/details/data/detail_dtos.dart';
import '../../shared/mappers/detail_mapper.dart';
import '../network/tmdb_client.dart';

class TmdbDetailsRepository implements DetailsRepository {
  final TmdbClient client;

  TmdbDetailsRepository({required this.client});

  @override
  Future<DetailMedia> loadCompleteDetail(DetailRouteArgs args) async {
    final detailFuture = client.getDetails(
      args.mediaId,
      args.mediaType,
      appendToResponse: 'credits,videos',
    );
    final providersFuture = client.getWatchProviders(args.mediaId, args.mediaType);
    final recommendationsFuture = client.getRecommendations(args.mediaId, args.mediaType);
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
    final response = await client.getSeasonInfo(tvId, seasonNumber);
    final rawEpisodes = response['episodes'] as List? ?? [];
    return DetailMapper.toEpisodeList(rawEpisodes);
  }
}
