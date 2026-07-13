// ignore_for_file: prefer_initializing_formals

import '../interfaces/search_repository.dart';
import '../network/anilist_client.dart';
import '../network/tmdb_client.dart';
import '../../shared/dto/media_dto.dart';
import '../../shared/mappers/media_mapper.dart';
import '../../features/search/models/search_media_item.dart';

class TmdbSearchRepository implements SearchRepository {
  final TmdbClient _client;
  final AniListClient _aniListClient;

  TmdbSearchRepository({
    required TmdbClient client,
    AniListClient? aniListClient,
  }) : _client = client,
       _aniListClient = aniListClient ?? AniListClient();

  @override
  Future<List<SearchMediaItem>> search({
    required String query,
    required SearchLanguageFilter language,
    required SearchMediaTypeFilter mediaType,
    required SearchSortOption sort,
    int page = 1,
  }) async {
    if (query.trim().isEmpty) return [];

    final movieFuture = _client.searchMovie(query, page: page);
    final tvFuture = _client.searchTv(query, page: page);
    final animeFuture = _searchAnime(query, page: page);

    var movieResults = _parseTypedResults(await movieFuture, 'movie');
    var tvResults = _parseTypedResults(await tvFuture, 'tv');
    var animeResults = await animeFuture;

    if (language != SearchLanguageFilter.all) {
      movieResults = movieResults
          .where((item) => item.language == language)
          .toList();
      tvResults = tvResults.where((item) => item.language == language).toList();
      if (language != SearchLanguageFilter.japanese) {
        animeResults = [];
      }
    }

    var results = _interleave([
      animeResults,
      [...movieResults, ...tvResults],
    ]);

    switch (sort) {
      case SearchSortOption.defaultOrder:
        break;
      case SearchSortOption.title:
        results.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
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

  List<SearchMediaItem> _parseTypedResults(
    Map<String, dynamic> responseData,
    String mediaType,
  ) {
    final results = responseData['results'];
    if (results is List) {
      for (final item in results) {
        if (item is Map<String, dynamic>) {
          item['media_type'] = mediaType;
        }
      }
    }
    final searchResponse = SearchResponseDto.fromJson(responseData);
    return searchResponse.results
        .where((dto) => dto.type == mediaType)
        .map(MediaMapper.toSearchMediaItem)
        .toList();
  }

  Future<List<SearchMediaItem>> _searchAnime(
    String query, {
    required int page,
  }) async {
    const graphQl = '''
      query (\$search: String, \$page: Int) {
        Page(page: \$page, perPage: 20) {
          media(search: \$search, type: ANIME, sort: POPULARITY_DESC) {
            id
            idMal
            title { romaji english }
            description
            coverImage { extraLarge large }
            bannerImage
            averageScore
            seasonYear
          }
        }
      }
    ''';
    final response = await _aniListClient.query(
      graphQl,
      variables: {'search': query, 'page': page},
    );
    final pageData = response['data']?['Page'];
    final media = pageData is Map ? pageData['media'] : null;
    if (media is! List) return [];
    return media.whereType<Map>().map((item) {
      final title = item['title'];
      final coverImage = item['coverImage'];
      final map = <String, dynamic>{
        'id': item['id'],
        'idMal': item['idMal'],
        'title': title is Map
            ? title['english'] ?? title['romaji'] ?? 'Unknown'
            : 'Unknown',
        'name': title is Map
            ? title['english'] ?? title['romaji'] ?? 'Unknown'
            : 'Unknown',
        'media_type': 'anime',
        'poster_path': coverImage is Map
            ? coverImage['extraLarge'] ?? coverImage['large']
            : null,
        'backdrop_path': item['bannerImage'],
        'overview': _stripHtml(item['description']?.toString() ?? ''),
        'vote_average': ((item['averageScore'] as num?)?.toDouble() ?? 0) / 10,
        'first_air_date': item['seasonYear']?.toString(),
        'original_language': 'ja',
      };
      return MediaMapper.toSearchMediaItem(MediaDto.fromJson(map));
    }).toList();
  }

  List<SearchMediaItem> _interleave(List<List<SearchMediaItem>> lists) {
    final interleaved = <SearchMediaItem>[];
    final seen = <String>{};
    final maxLength = lists.fold<int>(
      0,
      (max, list) => list.length > max ? list.length : max,
    );
    for (var i = 0; i < maxLength; i++) {
      for (final list in lists) {
        if (i >= list.length) continue;
        final item = list[i];
        if (seen.add(item.id)) interleaved.add(item);
      }
    }
    return interleaved;
  }

  String _stripHtml(String value) => value.replaceAll(RegExp(r'<[^>]*>'), '');
}
