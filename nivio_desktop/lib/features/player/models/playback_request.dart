import '../../../shared/models/stream_result.dart';

enum PlaybackMediaType { movie, tv, anime, liveTv, unknown }

/// Everything the player needs to identify and, when already resolved, open a
/// piece of media. Source resolution is added in Phase 22.2.
class PlaybackRequest {
  const PlaybackRequest({
    required this.mediaId,
    required this.title,
    required this.mediaType,
    this.posterPath,
    this.source,
    this.httpHeaders = const {},
    this.season,
    this.episode,
    this.providerIndex,
    this.watchPartyCode,
    this.watchPartyRole,
    this.isLive = false,
    this.startPosition = Duration.zero,
    this.totalSeasons = 1,
    this.totalEpisodes,
    this.streamResult,
    this.preferredAudioTrack,
    this.preferredSubtitleTrack,
    this.preferredQuality,
  });

  final String mediaId;
  final String title;
  final PlaybackMediaType mediaType;
  final String? posterPath;

  /// A direct URL or local file path. Provider resolution is intentionally not
  /// part of the foundation phase.
  final String? source;
  final Map<String, String> httpHeaders;
  final int? season;
  final int? episode;
  final int? providerIndex;
  final String? watchPartyCode;
  final String? watchPartyRole;
  final bool isLive;
  final Duration startPosition;
  final int totalSeasons;
  final int? totalEpisodes;
  final StreamResult? streamResult;
  final String? preferredAudioTrack;
  final String? preferredSubtitleTrack;
  final String? preferredQuality;

  bool get hasPlayableSource => source?.trim().isNotEmpty ?? false;

  int? get numericMediaId {
    final segments = mediaId.split(':');
    return int.tryParse(segments.last);
  }

  String get mediaTypeName => switch (mediaType) {
    PlaybackMediaType.movie => 'movie',
    PlaybackMediaType.tv => 'tv',
    PlaybackMediaType.anime => 'anime',
    PlaybackMediaType.liveTv => 'live',
    PlaybackMediaType.unknown =>
      mediaId.contains(':') ? mediaId.split(':').first : 'unknown',
  };

  PlaybackRequest copyWith({
    String? mediaId,
    String? title,
    PlaybackMediaType? mediaType,
    String? posterPath,
    String? source,
    Map<String, String>? httpHeaders,
    int? season,
    int? episode,
    int? providerIndex,
    String? watchPartyCode,
    String? watchPartyRole,
    bool? isLive,
    Duration? startPosition,
    int? totalSeasons,
    int? totalEpisodes,
    StreamResult? streamResult,
    String? preferredAudioTrack,
    String? preferredSubtitleTrack,
    String? preferredQuality,
    bool clearStreamResult = false,
    bool clearSource = false,
    bool clearPreferredQuality = false,
  }) {
    return PlaybackRequest(
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      posterPath: posterPath ?? this.posterPath,
      source: clearSource ? null : source ?? this.source,
      httpHeaders: httpHeaders ?? this.httpHeaders,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      providerIndex: providerIndex ?? this.providerIndex,
      watchPartyCode: watchPartyCode ?? this.watchPartyCode,
      watchPartyRole: watchPartyRole ?? this.watchPartyRole,
      isLive: isLive ?? this.isLive,
      startPosition: startPosition ?? this.startPosition,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      streamResult: clearStreamResult
          ? null
          : streamResult ?? this.streamResult,
      preferredAudioTrack: preferredAudioTrack ?? this.preferredAudioTrack,
      preferredSubtitleTrack:
          preferredSubtitleTrack ?? this.preferredSubtitleTrack,
      preferredQuality: clearPreferredQuality
          ? null
          : preferredQuality ?? this.preferredQuality,
    );
  }
}
