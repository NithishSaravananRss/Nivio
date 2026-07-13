import '../../features/search/models/search_media_item.dart';
import '../interfaces/home_repository.dart';
import '../network/tmdb_client.dart';
import '../../shared/mappers/media_mapper.dart';
import '../../shared/dto/media_dto.dart';

class TmdbHomeRepository implements HomeRepository {
  final TmdbClient client;

  TmdbHomeRepository({required this.client});

  @override
  Future<List<SearchMediaItem>> getTrendingMovies() async {
    final response = await client.getTrending('movie', 'day');
    return _parseResults(response, 'movie');
  }

  @override
  Future<List<SearchMediaItem>> getTrendingTv() async {
    final response = await client.getTrending('tv', 'day');
    return _parseResults(response, 'tv');
  }

  @override
  Future<List<SearchMediaItem>> getTrendingAnime() async {
    return [];
  }

  @override
  Future<List<SearchMediaItem>> getFeaturedContent() async {
    final response = await client.getTrending('all', 'day');
    return _parseResults(response, null).take(10).toList(growable: false);
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
}
