import '../../../core/network/anilist_client.dart';
import '../../../core/network/aniskip_client.dart';
import '../../../core/network/theintrodb_client.dart';
import '../../../shared/models/skip_times_models.dart';
import '../models/playback_request.dart';

class DesktopSkipTimesService {
  DesktopSkipTimesService({
    AniSkipClient? aniSkipClient,
    TheIntroDbClient? theIntroDbClient,
    AniListClient? aniListClient,
  }) : _aniSkipClient = aniSkipClient ?? AniSkipClient(),
       _theIntroDbClient = theIntroDbClient ?? TheIntroDbClient(),
       _aniListClient = aniListClient ?? AniListClient();

  final AniSkipClient _aniSkipClient;
  final TheIntroDbClient _theIntroDbClient;
  final AniListClient _aniListClient;
  final Map<String, List<SkipTime>> _memoryCache = {};

  Future<List<SkipTime>> getSkipTimes(PlaybackRequest request) async {
    if (request.isLive) return const [];
    final episode = request.episode;
    if (episode == null || episode <= 0) return const [];

    final key = _cacheKey(request);
    final cached = _memoryCache[key];
    if (cached != null) return cached;

    final result = switch (request.mediaType) {
      PlaybackMediaType.anime => await _getAnimeSkipTimes(request, episode),
      PlaybackMediaType.tv => await _getTvSkipTimes(request, episode),
      _ => const <SkipTime>[],
    };
    _memoryCache[key] = result;
    return result;
  }

  Future<List<SkipTime>> _getAnimeSkipTimes(
    PlaybackRequest request,
    int episode,
  ) async {
    final malId = await _resolveMalId(request);
    if (malId == null) return const [];
    try {
      final response = await _aniSkipClient.getSkipTimes(malId, episode);
      if (response['found'] != true || response['results'] is! List) {
        return const [];
      }
      return (response['results'] as List)
          .whereType<Map>()
          .map((item) => _aniSkipTime(Map<String, dynamic>.from(item)))
          .whereType<SkipTime>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<SkipTime>> _getTvSkipTimes(
    PlaybackRequest request,
    int episode,
  ) async {
    final tmdbId = request.numericMediaId;
    if (tmdbId == null) return const [];
    try {
      final response = await _theIntroDbClient.getMedia(
        tmdbId,
        request.season ?? 1,
        episode,
      );
      return _theIntroDbSkipTimes(response);
    } catch (_) {
      return const [];
    }
  }

  Future<int?> _resolveMalId(PlaybackRequest request) async {
    final numericId = request.numericMediaId;
    final mediaIdPrefix = request.mediaId.contains(':')
        ? request.mediaId.split(':').first
        : request.mediaTypeName;

    final variables = <String, Object?>{};
    if (mediaIdPrefix == 'anime' && numericId != null) {
      variables['id'] = numericId;
    } else if (request.title.trim().isNotEmpty) {
      variables['search'] = request.title.trim();
    } else {
      return null;
    }

    const query = '''
      query NivioDesktopMalId(\$id: Int, \$search: String) {
        Media(id: \$id, search: \$search, type: ANIME) {
          idMal
        }
      }
    ''';

    try {
      final response = await _aniListClient.query(query, variables: variables);
      final data = response['data'];
      if (data is! Map) return null;
      final media = data['Media'];
      if (media is! Map) return null;
      return media['idMal'] is int
          ? media['idMal'] as int
          : int.tryParse(media['idMal']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  SkipTime? _aniSkipTime(Map<String, dynamic> item) {
    final interval = item['interval'];
    if (interval is! Map) return null;
    final start = (interval['startTime'] as num?)?.toDouble();
    final end = (interval['endTime'] as num?)?.toDouble();
    if (start == null || end == null || end <= start) return null;
    return SkipTime(
      startTime: Duration(milliseconds: (start * 1000).round()),
      endTime: Duration(milliseconds: (end * 1000).round()),
      type: item['skipType']?.toString() ?? 'unknown',
    );
  }

  List<SkipTime> _theIntroDbSkipTimes(Map<String, dynamic> data) {
    final skipTimes = <SkipTime>[];
    void add(String sourceKey, String mappedType) {
      final values = data[sourceKey];
      if (values is! List) return;
      for (final value in values) {
        if (value is! Map) continue;
        final startMs = (value['start_ms'] as num?)?.toInt();
        final endMs = (value['end_ms'] as num?)?.toInt();
        if (startMs == null || startMs < 0) continue;
        skipTimes.add(
          SkipTime(
            startTime: Duration(milliseconds: startMs),
            endTime: endMs == null || endMs <= startMs
                ? const Duration(hours: 99)
                : Duration(milliseconds: endMs),
            type: mappedType,
          ),
        );
      }
    }

    add('intro', 'op');
    add('credits', 'ed');
    add('recap', 'recap');
    add('preview', 'preview');
    return skipTimes;
  }

  String _cacheKey(PlaybackRequest request) {
    return [
      request.mediaTypeName,
      request.numericMediaId?.toString() ?? request.mediaId,
      request.season ?? 0,
      request.episode ?? 0,
    ].join(':');
  }
}
