enum PlaybackStatus {
  idle,
  loading,
  ready,
  buffering,
  stopped,
  completed,
  error,
}

enum PlaybackRepeatMode { none, one, all }

class SubtitleStyle {
  const SubtitleStyle({
    this.scale = 1,
    this.background = false,
    this.outline = false,
  });

  final double scale;
  final bool background;
  final bool outline;
}

class PlaybackDiagnostics {
  const PlaybackDiagnostics({
    this.backend = 'unknown',
    this.decoder = 'unknown',
    this.renderer = 'unknown',
    this.hardwareAcceleration = 'unknown',
    this.resolution = 'unknown',
    this.fps = 'unknown',
    this.bitrate = 'unknown',
    this.cache = 'unknown',
    this.buffer = 'unknown',
    this.droppedFrames = 'unknown',
    this.audioTrack = 'unknown',
    this.subtitleTrack = 'unknown',
  });

  final String backend;
  final String decoder;
  final String renderer;
  final String hardwareAcceleration;
  final String resolution;
  final String fps;
  final String bitrate;
  final String cache;
  final String buffer;
  final String droppedFrames;
  final String audioTrack;
  final String subtitleTrack;

  Map<String, String> toRows() => {
    'Backend': backend,
    'Decoder': decoder,
    'Renderer': renderer,
    'Hardware acceleration': hardwareAcceleration,
    'Resolution': resolution,
    'FPS': fps,
    'Bitrate': bitrate,
    'Cache': cache,
    'Buffer': buffer,
    'Dropped frames': droppedFrames,
    'Audio track': audioTrack,
    'Subtitle track': subtitleTrack,
  };
}

class PlaybackTrackOption {
  const PlaybackTrackOption({
    required this.id,
    required this.label,
    this.language,
    this.isExternal = false,
  });

  final String id;
  final String label;
  final String? language;
  final bool isExternal;

  bool get isOff => id == 'no';
  bool get isAuto => id == 'auto';
}

class PlaybackState {
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1,
    this.isMuted = false,
    this.playbackSpeed = 1,
    this.repeatMode = PlaybackRepeatMode.none,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.selectedAudioTrackId = 'auto',
    this.selectedSubtitleTrackId = 'auto',
    this.errorMessage,
  });

  final PlaybackStatus status;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;

  /// Normalized volume in the range 0.0 to 2.0. Values above 1.0 are
  /// Desktop/Linux loudness enhancement.
  final double volume;
  final bool isMuted;
  final double playbackSpeed;
  final PlaybackRepeatMode repeatMode;
  final List<PlaybackTrackOption> audioTracks;
  final List<PlaybackTrackOption> subtitleTracks;
  final String selectedAudioTrackId;
  final String selectedSubtitleTrackId;
  final String? errorMessage;

  bool get canSeek => duration > Duration.zero;

  PlaybackState copyWith({
    PlaybackStatus? status,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    bool? isMuted,
    double? playbackSpeed,
    PlaybackRepeatMode? repeatMode,
    List<PlaybackTrackOption>? audioTracks,
    List<PlaybackTrackOption>? subtitleTracks,
    String? selectedAudioTrackId,
    String? selectedSubtitleTrackId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: (volume ?? this.volume).clamp(0.0, 2.0),
      isMuted: isMuted ?? this.isMuted,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      repeatMode: repeatMode ?? this.repeatMode,
      audioTracks: audioTracks ?? this.audioTracks,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      selectedAudioTrackId: selectedAudioTrackId ?? this.selectedAudioTrackId,
      selectedSubtitleTrackId:
          selectedSubtitleTrackId ?? this.selectedSubtitleTrackId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
