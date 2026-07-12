/// Contract for reading and writing local watch progress.
abstract class WatchHistoryRepository {
  Future<List<Map<String, dynamic>>> getWatchHistory();

  Future<Map<String, dynamic>?> getWatchProgress({
    required int mediaId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  });

  Future<void> saveWatchProgress(Map<String, dynamic> progress);

  Future<void> removeWatchProgress({
    required int mediaId,
    required String mediaType,
  });

  Future<void> clearWatchHistory();
}
