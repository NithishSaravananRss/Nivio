/// Contract for loading metadata for a selected media item.
abstract class DetailsRepository {
  Future<Map<String, dynamic>?> getMediaDetails({
    required int mediaId,
    required String mediaType,
  });

  Future<List<Map<String, dynamic>>> getRelatedMedia({
    required int mediaId,
    required String mediaType,
  });

  Future<List<Map<String, dynamic>>> getSeasonEpisodes({
    required int mediaId,
    required int seasonNumber,
  });
}
