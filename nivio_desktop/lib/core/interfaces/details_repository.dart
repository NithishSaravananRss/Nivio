import '../../features/details/models/detail_models.dart';
import '../../features/details/models/detail_route_args.dart';

/// Contract for loading metadata for a selected media item.
abstract class DetailsRepository {
  Future<DetailMedia> loadCompleteDetail(DetailRouteArgs args);

  Future<List<DetailEpisode>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
  });
}
