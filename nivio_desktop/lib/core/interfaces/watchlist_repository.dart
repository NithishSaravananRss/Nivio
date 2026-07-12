/// Contract for managing saved media items.
abstract class WatchlistRepository {
  Future<List<Map<String, dynamic>>> getWatchlist();

  Future<bool> isInWatchlist({required int mediaId, required String mediaType});

  Future<void> addToWatchlist(Map<String, dynamic> item);

  Future<void> removeFromWatchlist({
    required int mediaId,
    required String mediaType,
  });

  Future<void> clearWatchlist();
}
