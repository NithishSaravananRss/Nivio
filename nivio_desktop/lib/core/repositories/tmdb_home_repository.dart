import '../../features/search/models/search_media_item.dart';
import '../interfaces/home_repository.dart';
import '../network/anilist_client.dart';
import '../network/tmdb_client.dart';
import '../../shared/mappers/media_mapper.dart';
import '../../shared/dto/media_dto.dart';

class TmdbHomeRepository implements HomeRepository {
  final TmdbClient client;
  final AniListClient aniListClient;

  TmdbHomeRepository({required this.client, AniListClient? aniListClient})
    : aniListClient = aniListClient ?? AniListClient();

  @override
  Future<List<SearchMediaItem>> getPopularMovies() async {
    final response = await client.getPopular('movie');
    return _parseResults(response, 'movie');
  }

  @override
  Future<List<SearchMediaItem>> getTrendingMovies() async {
    final response = await client.getTrending('movie', 'day');
    return _parseResults(response, 'movie');
  }

  @override
  Future<List<SearchMediaItem>> getTopRatedMovies() async {
    final response = await client.getTopRated('movie');
    return _parseResults(response, 'movie');
  }

  @override
  Future<List<SearchMediaItem>> getPopularTv() async {
    final response = await client.getPopular('tv');
    return _parseResults(response, 'tv');
  }

  @override
  Future<List<SearchMediaItem>> getTrendingTv() async {
    final response = await client.getTrending('tv', 'day');
    return _parseResults(response, 'tv');
  }

  @override
  Future<List<SearchMediaItem>> getPopularAnime() async {
    return _getAniListAnime(sort: 'POPULARITY_DESC');
  }

  @override
  Future<List<SearchMediaItem>> getTrendingAnime() async {
    return _getAniListAnime(sort: 'TRENDING_DESC');
  }

  @override
  Future<List<SearchMediaItem>> getFeaturedContent() async {
    final results = await Future.wait([
      client
          .getTrending('all', 'day')
          .then((response) => _parseResults(response, null)),
      getTrendingAnime(),
    ]);
    final trending = results[0];
    final animeTrending = results[1];
    final interleaved = <SearchMediaItem>[];
    for (var i = 0; i < 5; i++) {
      if (i < trending.length) interleaved.add(trending[i]);
      if (i < animeTrending.length) interleaved.add(animeTrending[i]);
    }
    return interleaved;
  }

  @override
  Future<List<SearchMediaItem>> getTamilPicks() async {
    final sixMonthsAgo = DateTime.now()
        .subtract(const Duration(days: 180))
        .toIso8601String()
        .split('T')
        .first;
    final response = await client.discover('movie', {
      'with_original_language': 'ta',
      'sort_by': 'release_date.desc',
      'release_date.gte': sixMonthsAgo,
      'with_release_type': '4|5|6',
      'vote_count.gte': 5,
      'page': 1,
    });
    return _parseResults(response, 'movie');
  }

  @override
  Future<List<SearchMediaItem>> getTeluguPicks() =>
      _getByLanguage('movie', 'te');

  @override
  Future<List<SearchMediaItem>> getHindiPicks() =>
      _getByLanguage('movie', 'hi');

  @override
  Future<List<SearchMediaItem>> getMalayalamPicks() =>
      _getByLanguage('movie', 'ml');

  @override
  Future<List<SearchMediaItem>> getKoreanDramas() => _getByLanguage('tv', 'ko');

  @override
  Future<List<SearchMediaItem>> getRecommendationsForHistory(
    List<Map<String, dynamic>> history,
  ) async {
    final sorted = [...history]
      ..sort((a, b) {
        final aDate = _dateFromHistory(a['lastWatchedAt']);
        final bDate = _dateFromHistory(b['lastWatchedAt']);
        return bDate.compareTo(aDate);
      });
    final top5 = sorted.take(5).toList();
    if (top5.isEmpty) return [];

    final futures = top5.map((item) async {
      final id = _historyMediaId(item);
      final mediaType = _historyMediaType(item);
      if (id == null || mediaType == null) return <SearchMediaItem>[];
      final response = await client.getRecommendations(id, mediaType);
      return _parseResults(response, mediaType);
    });

    final lists = await Future.wait(futures);
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

  List<SearchMediaItem> _parseResults(dynamic response, String? injectedType) {
    if (response is! Map) {
      throw const FormatException('Invalid response format');
    }
    final responseMap = Map<String, dynamic>.from(response);
    final results = responseMap['results'];
    if (results is! List) return [];

    return results
        .map((json) {
          if (json is Map) {
            final map = Map<String, dynamic>.from(json);
            if (!map.containsKey('media_type') && injectedType != null) {
              map['media_type'] = injectedType;
            }
            final mediaType = map['media_type'];
            if (mediaType != 'movie' && mediaType != 'tv') {
              return null;
            }
            if (_isJapaneseAnimatedTv(map, mediaType)) {
              return null;
            }
            final dto = MediaDto.fromJson(map);
            return MediaMapper.toSearchMediaItem(dto);
          }
          return null;
        })
        .whereType<SearchMediaItem>()
        .toList();
  }

  bool _isJapaneseAnimatedTv(Map<String, dynamic> map, Object? mediaType) {
    if (mediaType != 'tv') {
      return false;
    }
    final genreIds = map['genre_ids'];
    final originCountry = map['origin_country'];
    final isJapanese =
        map['original_language'] == 'ja' ||
        (originCountry is List && originCountry.contains('JP'));
    final isAnimated =
        genreIds is List &&
        genreIds.whereType<num>().any((id) => id.toInt() == 16);
    return isJapanese && isAnimated;
  }

  Future<List<SearchMediaItem>> _getByLanguage(
    String mediaType,
    String language,
  ) async {
    final response = await client.discover(mediaType, {
      'with_original_language': language,
      'sort_by': 'popularity.desc',
      'vote_count.gte': 10,
      'page': 1,
    });
    return _parseResults(response, mediaType);
  }

  Future<List<SearchMediaItem>> _getAniListAnime({required String sort}) async {
    const query = '''
      query (\$page: Int, \$sort: [MediaSort]) {
        Page(page: \$page, perPage: 20) {
          media(type: ANIME, sort: \$sort) {
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
    final response = await aniListClient.query(
      query,
      variables: {
        'page': 1,
        'sort': [sort],
      },
    );
    final page = response['data']?['Page'];
    final media = page is Map ? page['media'] : null;
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
      };
      return MediaMapper.toSearchMediaItem(MediaDto.fromJson(map));
    }).toList();
  }

  String _stripHtml(String value) => value.replaceAll(RegExp(r'<[^>]*>'), '');

  int? _historyMediaId(Map<String, dynamic> item) {
    final raw = item['tmdbId'] ?? item['mediaId'] ?? item['id'];
    return raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  }

  String? _historyMediaType(Map<String, dynamic> item) {
    final raw = item['mediaType'] ?? item['type'];
    final type = raw?.toString();
    return type == 'movie' || type == 'tv' ? type : null;
  }

  DateTime _dateFromHistory(Object? raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime(1970);
  }
}
