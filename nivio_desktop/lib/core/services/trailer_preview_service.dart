import '../constants/constants.dart';
import '../network/tmdb_client.dart';

class TrailerPreviewService {
  TrailerPreviewService._();

  static final TrailerPreviewService instance = TrailerPreviewService._();

  final TmdbClient _client = TmdbClient(apiKey: tmdbApiKey);
  final Map<String, Future<String?>> _cache = {};

  Future<String?> resolve(String mediaId) {
    return _cache.putIfAbsent(mediaId, () => _resolve(mediaId));
  }

  Future<String?> _resolve(String mediaId) async {
    final parts = mediaId.split(':');
    if (parts.length != 2) return null;

    final mediaType = parts.first;
    if (mediaType != 'movie' && mediaType != 'tv') return null;

    final id = int.tryParse(parts.last);
    if (id == null || id <= 0) return null;

    try {
      final response = await _client.getDetails(
        id,
        mediaType,
        appendToResponse: 'videos',
      );
      final videos = response['videos'];
      final results = videos is Map ? videos['results'] : null;
      if (results is! List) return null;

      final candidates = results.whereType<Map>().where((video) {
        final site = video['site']?.toString().toLowerCase();
        final type = video['type']?.toString().toLowerCase();
        final key = video['key']?.toString();
        return site == 'youtube' &&
            key != null &&
            key.isNotEmpty &&
            (type == 'trailer' || type == 'teaser');
      }).toList();

      if (candidates.isEmpty) return null;
      candidates.sort((left, right) {
        final leftOfficial = left['official'] == true ? 0 : 1;
        final rightOfficial = right['official'] == true ? 0 : 1;
        if (leftOfficial != rightOfficial) {
          return leftOfficial.compareTo(rightOfficial);
        }
        final leftTrailer = left['type']?.toString().toLowerCase() == 'trailer'
            ? 0
            : 1;
        final rightTrailer =
            right['type']?.toString().toLowerCase() == 'trailer' ? 0 : 1;
        return leftTrailer.compareTo(rightTrailer);
      });

      return candidates.first['key']?.toString();
    } catch (_) {
      return null;
    }
  }
}
