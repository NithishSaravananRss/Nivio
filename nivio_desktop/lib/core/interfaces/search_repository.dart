/// Contract for searching movies, TV shows, anime, and other media.
abstract class SearchRepository {
  Future<List<Map<String, dynamic>>> searchMedia(
    String query, {
    int page = 1,
    String? mediaType,
  });

  Future<List<Map<String, dynamic>>> getSearchSuggestions(String query);
}
