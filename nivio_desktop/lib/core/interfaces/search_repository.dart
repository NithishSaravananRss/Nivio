import '../../features/search/models/search_media_item.dart';

abstract class SearchRepository {
  Future<List<SearchMediaItem>> search({
    required String query,
    required SearchLanguageFilter language,
    required SearchMediaTypeFilter mediaType,
    required SearchSortOption sort,
    int page = 1,
  });
}
