/// Contract for loading desktop home screen content groups.
abstract class HomeRepository {
  Future<List<Map<String, dynamic>>> getTrendingMedia({int page = 1});

  Future<List<Map<String, dynamic>>> getPopularMedia({int page = 1});

  Future<List<Map<String, dynamic>>> getRecentlyUpdatedMedia({int page = 1});
}
