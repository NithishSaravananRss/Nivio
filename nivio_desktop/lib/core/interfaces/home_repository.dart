import '../../features/search/models/search_media_item.dart';

/// Contract for loading desktop home screen content groups.
abstract class HomeRepository {
  Future<List<SearchMediaItem>> getTrendingMovies();
  Future<List<SearchMediaItem>> getTrendingTv();
  Future<List<SearchMediaItem>> getTrendingAnime();
  Future<List<SearchMediaItem>> getFeaturedContent();
}
