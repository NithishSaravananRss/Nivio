import '../interfaces/watch_history_repository.dart';

class EmptyWatchHistoryRepository implements WatchHistoryRepository {
  @override
  Future<List<Map<String, dynamic>>> getWatchHistory() async => [];

  @override
  Future<Map<String, dynamic>?> getWatchProgress({
    required int mediaId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async => null;

  @override
  Future<void> saveWatchProgress(Map<String, dynamic> progress) async {}

  @override
  Future<void> removeWatchProgress({
    required int mediaId,
    required String mediaType,
  }) async {}

  @override
  Future<void> clearWatchHistory() async {}
}
