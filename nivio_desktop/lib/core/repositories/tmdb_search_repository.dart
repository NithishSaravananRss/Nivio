import '../interfaces/search_repository.dart';
import '../network/tmdb_client.dart';
import '../../shared/dto/media_dto.dart';
import '../../shared/mappers/media_mapper.dart';
import '../../features/search/models/search_media_item.dart';

class TmdbSearchRepository implements SearchRepository {
  final TmdbClient _client;

  // ignore: prefer_initializing_formals
  TmdbSearchRepository({required TmdbClient client}) : _client = client;

  @override
  Future<List<SearchMediaItem>> search({
    required String query,
    required SearchLanguageFilter language,
    required SearchMediaTypeFilter mediaType,
    required SearchSortOption sort,
    int page = 1,
  }) async {
    if (query.trim().isEmpty) return [];

    Map<String, dynamic> responseData;

    switch (mediaType) {
      case SearchMediaTypeFilter.movie:
        responseData = await _client.searchMovie(query, page: page);
        for (var item in responseData['results'] ?? []) {
          item['media_type'] = 'movie';
        }
        break;
      case SearchMediaTypeFilter.tv:
      case SearchMediaTypeFilter.anime:
        responseData = await _client.searchTv(query, page: page);
        for (var item in responseData['results'] ?? []) {
          item['media_type'] = mediaType == SearchMediaTypeFilter.anime ? 'anime' : 'tv';
        }
        break;
      case SearchMediaTypeFilter.all:
        responseData = await _client.searchMulti(query, page: page);
        break;
    }

    final searchResponse = SearchResponseDto.fromJson(responseData);
    
    var results = searchResponse.results
        .where((dto) => dto.type == 'movie' || dto.type == 'tv' || dto.type == 'anime')
        .map((dto) => MediaMapper.toSearchMediaItem(dto))
        .toList();

    // In a real app we might pass language to TMDB, but for now we filter locally if requested
    if (language != SearchLanguageFilter.all) {
      results = results.where((item) => item.language == language).toList();
    }

    // Since TMDB search doesn't natively support sorting by everything, we sort the page locally.
    switch (sort) {
      case SearchSortOption.defaultOrder:
        break;
      case SearchSortOption.title:
        results.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SearchSortOption.year:
        results.sort((a, b) => b.year.compareTo(a.year));
        break;
      case SearchSortOption.rating:
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return results;
  }
}
