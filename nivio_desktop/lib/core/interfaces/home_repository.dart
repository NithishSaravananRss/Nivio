import '../../features/search/models/search_media_item.dart';

/// Contract for loading desktop home screen content groups.
abstract class HomeRepository {
  Future<List<SearchMediaItem>> getPopularMovies();
  Future<List<SearchMediaItem>> getTrendingMovies();
  Future<List<SearchMediaItem>> getTopRatedMovies();
  Future<List<SearchMediaItem>> getPopularTv();
  Future<List<SearchMediaItem>> getTrendingTv();
  Future<List<SearchMediaItem>> getPopularAnime();
  Future<List<SearchMediaItem>> getTrendingAnime();
  Future<List<SearchMediaItem>> getTamilPicks();
  Future<List<SearchMediaItem>> getTeluguPicks();
  Future<List<SearchMediaItem>> getHindiPicks();
  Future<List<SearchMediaItem>> getMalayalamPicks();
  Future<List<SearchMediaItem>> getKoreanDramas();
  Future<List<SearchMediaItem>> getFeaturedContent();
  Future<List<SearchMediaItem>> getRecommendationsForHistory(
    List<Map<String, dynamic>> history,
  );
}
