import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

import 'models/playback_request.dart';
import 'models/playback_state.dart';
import 'playback_engine.dart';
import 'services/playback_runtime_diagnostics.dart';

class MediaKitPlaybackEngine implements PlaybackEngine {
  MediaKitPlaybackEngine({Player? player})
    : _player = player ?? _createPlayer() {
    PlaybackRuntimeDiagnostics.mediaKitEnginesCreated++;
    _mpvLog(
      'MediaKitPlaybackEngine#$debugInstanceId created '
      '${PlaybackRuntimeDiagnostics.lifecycleSummary()}',
    );
    videoController = VideoController(_player);
    PlaybackRuntimeDiagnostics.videoControllersCreated++;
    _mpvLog(
      'NativeVideoController Created active=${PlaybackRuntimeDiagnostics.textureCount}',
    );
    _mpvLog(
      'VideoOutput Created active=${PlaybackRuntimeDiagnostics.textureCount}',
    );
    _listenToPlayer();
  }

  static int _nextInstanceId = 0;

  final int debugInstanceId = ++_nextInstanceId;
  final Player _player;
  late final VideoController videoController;
  final ValueNotifier<PlaybackState> _state = ValueNotifier(
    const PlaybackState(),
  );
  final List<StreamSubscription<Object?>> _subscriptions = [];
  PlaybackRequest? _request;
  bool _disposed = false;
  Stopwatch? _loadClock;
  bool _firstFrameLogged = false;

  @override
  ValueListenable<PlaybackState> get state => _state;
  bool get debugDisposed => _disposed;

  static Player _createPlayer() {
    MediaKit.ensureInitialized();
    PlaybackRuntimeDiagnostics.mediaPlayersCreated++;
    PlaybackRuntimeDiagnostics.mpvLog(
      'Player Created active=${PlaybackRuntimeDiagnostics.mediaPlayersAlive}',
    );
    PlaybackRuntimeDiagnostics.snapshot('after media_kit player create');
    return Player(
      configuration: PlayerConfiguration(
        logLevel: PlaybackRuntimeDiagnostics.enabled
            ? MPVLogLevel.v
            : MPVLogLevel.error,
        bufferSize: 128 * 1024 * 1024,
      ),
    );
  }

  void _listenToPlayer() {
    _subscriptions.addAll([
      _player.stream.playing.listen((playing) {
        _mpvLog('Lifecycle: ${playing ? 'Playing' : 'Paused'}');
        _update(
          isPlaying: playing,
          status: _statusAfterPlayingChanged(playing),
        );
      }),
      _player.stream.position.listen((position) {
        if (position.inSeconds > 0 && position.inSeconds % 10 == 0) {
          _mpvLog('Position: ${position.inSeconds}s');
        }
        _update(position: position);
      }),
      _player.stream.duration.listen((duration) {
        _mpvLog('Duration: ${duration.inMilliseconds}ms');
        _update(duration: duration);
      }),
      _player.stream.buffer.listen((buffer) {
        _mpvLog('Buffer: ${buffer.inMilliseconds}ms');
        _update(bufferedPosition: buffer);
      }),
      _player.stream.volume.listen((volume) {
        final normalized = (volume / 100).clamp(0.0, 2.0);
        _update(volume: normalized, isMuted: normalized == 0);
      }),
      _player.stream.tracks.listen((tracks) {
        _mpvLog(
          'Tracks: video=${tracks.video.length} audio=${tracks.audio.length} '
          'subtitle=${tracks.subtitle.length}',
        );
        _update(
          audioTracks: tracks.audio.map(_audioOption).toList(),
          subtitleTracks: tracks.subtitle.map(_subtitleOption).toList(),
        );
      }),
      _player.stream.track.listen((track) {
        _mpvLog(
          'Selected tracks: video=${track.video.id} audio=${track.audio.id} '
          'subtitle=${track.subtitle.id}',
        );
        _update(
          selectedAudioTrackId: track.audio.id,
          selectedSubtitleTrackId: track.subtitle.id,
        );
      }),
      _player.stream.buffering.listen((buffering) {
        _mpvLog('Lifecycle: ${buffering ? 'Buffering' : 'Ready'}');
        final currentStatus = _state.value.status;
        if (currentStatus == PlaybackStatus.error ||
            currentStatus == PlaybackStatus.completed ||
            currentStatus == PlaybackStatus.stopped) {
          return;
        }
        _update(
          status: buffering
              ? PlaybackStatus.buffering
              : currentStatus == PlaybackStatus.buffering
              ? PlaybackStatus.ready
              : currentStatus,
        );
      }),
      _player.stream.completed.listen((completed) {
        if (completed) {
          _mpvLog('Lifecycle: Ended');
          _update(status: PlaybackStatus.completed, isPlaying: false);
        }
      }),
      _player.stream.error.listen((message) {
        _mpvLog('Lifecycle: Error $message');
        _update(
          status: PlaybackStatus.error,
          isPlaying: false,
          errorMessage: message,
        );
      }),
      _player.stream.videoParams.listen((params) {
        _mpvLog('Video params: $params');
      }),
      _player.stream.log.listen((event) {
        final text = event.text.trim();
        if (text.isEmpty) return;
        final lower = text.toLowerCase();
        if (!_firstFrameLogged &&
            lower.contains('first video frame after restart shown')) {
          _firstFrameLogged = true;
          PlaybackRuntimeDiagnostics.mpvLog(
            'First rendered frame',
            clock: _loadClock,
          );
        }
        if (lower.contains('http') ||
            lower.contains('hls') ||
            lower.contains('m3u8') ||
            lower.contains('.ts') ||
            lower.contains('.m4s') ||
            lower.contains('error') ||
            lower.contains('failed') ||
            lower.contains('cache') ||
            lower.contains('decoder') ||
            lower.contains('demux') ||
            lower.contains('video')) {
          _mpvLog('[${event.level}/${event.prefix}] $text');
        }
      }),
    ]);
  }

  PlaybackStatus _statusAfterPlayingChanged(bool playing) {
    return switch (_state.value.status) {
      PlaybackStatus.loading =>
        playing ? PlaybackStatus.ready : PlaybackStatus.loading,
      PlaybackStatus.buffering => PlaybackStatus.buffering,
      PlaybackStatus.error => PlaybackStatus.error,
      PlaybackStatus.completed => PlaybackStatus.completed,
      PlaybackStatus.stopped => PlaybackStatus.stopped,
      _ => PlaybackStatus.ready,
    };
  }

  @override
  Future<void> load(PlaybackRequest request) async {
    _request = request;
    _loadClock = Stopwatch()..start();
    _firstFrameLogged = false;
    if (!request.hasPlayableSource) {
      _update(
        status: PlaybackStatus.error,
        errorMessage: 'No playable source is available.',
      );
      return;
    }

    _update(
      status: PlaybackStatus.loading,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
      bufferedPosition: Duration.zero,
      clearError: true,
    );

    try {
      PlaybackRuntimeDiagnostics.mpvLog(
        'Lifecycle: Loading ${request.source}',
        clock: _loadClock,
      );
      await _configureNativeDefaults(request);
      await _player.open(
        Media(
          request.source!,
          httpHeaders: request.httpHeaders,
          start: request.startPosition > Duration.zero
              ? request.startPosition
              : null,
        ),
        play: true,
      );
      PlaybackRuntimeDiagnostics.mpvLog('open() completed', clock: _loadClock);
      unawaited(_dumpNativeState('after-open'));
    } catch (error) {
      _mpvLog('open() failed: $error');
      _update(
        status: PlaybackStatus.error,
        isPlaying: false,
        errorMessage: 'Playback failed: $error',
      );
    }
  }

  @override
  Future<void> retry() async {
    final request = _request;
    if (request != null) await load(request);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _update(status: PlaybackStatus.stopped, isPlaying: false);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) {
    return _player.setVolume(volume.clamp(0.0, 2.0) * 100);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    final normalized = speed.clamp(0.25, 4.0).toDouble();
    await _player.setRate(normalized);
    _update(playbackSpeed: normalized);
  }

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode mode) async {
    final playlistMode = switch (mode) {
      PlaybackRepeatMode.none => PlaylistMode.none,
      PlaybackRepeatMode.one => PlaylistMode.single,
      PlaybackRepeatMode.all => PlaylistMode.loop,
    };
    await _player.setPlaylistMode(playlistMode);
    _update(repeatMode: mode);
  }

  @override
  Future<void> selectAudioTrack(String trackId) async {
    final track = _player.state.tracks.audio.firstWhere(
      (track) => track.id == trackId,
      orElse: () => trackId == 'no' ? AudioTrack.no() : AudioTrack.auto(),
    );
    final position = _player.state.position;
    final wasPlaying = _player.state.playing;
    await _player.setAudioTrack(track);
    if (position > Duration.zero) await _player.seek(position);
    if (wasPlaying) await _player.play();
    _update(selectedAudioTrackId: track.id);
  }

  @override
  Future<void> selectSubtitleTrack(
    String trackId, {
    String? externalUrl,
  }) async {
    final SubtitleTrack track;
    if (externalUrl != null && externalUrl.trim().isNotEmpty) {
      track = SubtitleTrack.uri(externalUrl, title: trackId, language: trackId);
    } else {
      track = _player.state.tracks.subtitle.firstWhere(
        (track) => track.id == trackId,
        orElse: () =>
            trackId == 'no' ? SubtitleTrack.no() : SubtitleTrack.auto(),
      );
    }
    final position = _player.state.position;
    final wasPlaying = _player.state.playing;
    await _player.setSubtitleTrack(track);
    if (position > Duration.zero) await _player.seek(position);
    if (wasPlaying) await _player.play();
    _update(selectedSubtitleTrackId: trackId);
  }

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    final platform = _player.platform;
    if (platform is NativePlayer) {
      await platform.setProperty(
        'sub-delay',
        (delay.inMilliseconds / 1000).toString(),
      );
    }
  }

  @override
  Future<void> setSubtitleStyle(SubtitleStyle style) async {
    final platform = _player.platform;
    if (platform is! NativePlayer) return;
    await platform.setProperty('sub-scale', style.scale.toStringAsFixed(2));
    await platform.setProperty(
      'sub-back-color',
      style.background ? '#00000099' : '#00000000',
    );
    await platform.setProperty('sub-border-size', style.outline ? '3' : '1');
    await platform.setProperty(
      'sub-shadow-offset',
      style.outline ? '1.5' : '0',
    );
  }

  @override
  Future<void> setDebanding(bool enabled) async {
    final platform = _player.platform;
    if (platform is NativePlayer) {
      await platform.setProperty('deband', enabled ? 'yes' : 'no');
    }
  }

  @override
  Future<PlaybackDiagnostics> diagnostics() async {
    final platform = _player.platform;
    if (platform is! NativePlayer) {
      return const PlaybackDiagnostics(backend: 'media_kit');
    }

    final width = await _nativeProperty(platform, 'width');
    final height = await _nativeProperty(platform, 'height');
    final fps = await _nativeProperty(platform, 'estimated-vf-fps');
    final videoBitrate = await _nativeProperty(platform, 'video-bitrate');
    final audioBitrate = await _nativeProperty(platform, 'audio-bitrate');
    final cacheUsed = await _nativeProperty(platform, 'cache-used');
    final demuxerCache = await _nativeProperty(
      platform,
      'demuxer-cache-duration',
    );
    final dropped = await _nativeProperty(platform, 'frame-drop-count');
    final decoder = await _nativeProperty(platform, 'video-codec');
    final hwdec = await _nativeProperty(platform, 'hwdec-current');
    final vo = await _nativeProperty(platform, 'current-vo');
    final audio = await _nativeProperty(platform, 'aid');
    final subtitle = await _nativeProperty(platform, 'sid');

    return PlaybackDiagnostics(
      backend: 'media_kit/libmpv',
      decoder: _clean(decoder),
      renderer: _clean(vo),
      hardwareAcceleration: _clean(hwdec),
      resolution: width.isEmpty || height.isEmpty
          ? 'unknown'
          : '${width}x$height',
      fps: _clean(fps),
      bitrate: _bitrate(videoBitrate, audioBitrate),
      cache: cacheUsed.isEmpty ? 'unknown' : '$cacheUsed bytes',
      buffer: demuxerCache.isEmpty ? 'unknown' : '${demuxerCache}s',
      droppedFrames: _clean(dropped),
      audioTrack: _clean(audio),
      subtitleTrack: _clean(subtitle),
    );
  }

  @override
  Future<String?> takeScreenshot() async {
    final platform = _player.platform;
    if (platform is! NativePlayer) return null;
    final directory = await getApplicationDocumentsDirectory();
    final screenshots = Directory('${directory.path}/screenshots');
    if (!screenshots.existsSync()) {
      screenshots.createSync(recursive: true);
    }
    final path =
        '${screenshots.path}/nivio-${DateTime.now().millisecondsSinceEpoch}.png';
    await platform.command(['screenshot-to-file', path, 'video']);
    return File(path).existsSync() ? path : null;
  }

  Future<void> _configureNativeDefaults(PlaybackRequest request) async {
    final platform = _player.platform;
    if (platform is! NativePlayer) return;
    await platform.setProperty('hwdec', 'auto');
    await platform.setProperty('volume-max', '200');
    await platform.setProperty('cache', 'yes');
    await platform.setProperty('demuxer-readahead-secs', '20');
    await _configureHttpOptions(platform, request);
    unawaited(_dumpNativeState('before-open'));
  }

  Future<void> _configureHttpOptions(
    NativePlayer platform,
    PlaybackRequest request,
  ) async {
    final headers = request.httpHeaders;
    if (headers.isEmpty) {
      _mpvLog('HTTP headers: none');
      return;
    }
    final userAgent = headers[_headerKey(headers, 'User-Agent')];
    final referer =
        headers[_headerKey(headers, 'Referer')] ??
        headers[_headerKey(headers, 'Referrer')];
    if (userAgent != null && userAgent.isNotEmpty) {
      await platform.setProperty('user-agent', userAgent);
    }
    if (referer != null && referer.isNotEmpty) {
      await platform.setProperty('referrer', referer);
    }
    final headerFields = headers.entries
        .where((entry) {
          final key = entry.key.toLowerCase();
          return key != 'user-agent' && key != 'referer' && key != 'referrer';
        })
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(',');
    if (headerFields.isNotEmpty) {
      await platform.setProperty('http-header-fields', headerFields);
    }
    _mpvLog(
      'HTTP headers: user-agent=${userAgent ?? 'none'} '
      'referer=${referer ?? 'none'} fields=${headerFields.isEmpty ? 'none' : headerFields}',
    );
  }

  Future<void> _dumpNativeState(String label) async {
    final platform = _player.platform;
    if (platform is! NativePlayer) return;
    final properties = {
      'path': await _nativeProperty(platform, 'path'),
      'stream-open-filename': await _nativeProperty(
        platform,
        'stream-open-filename',
      ),
      'demuxer-cache-state': await _nativeProperty(
        platform,
        'demuxer-cache-state',
      ),
      'video-codec': await _nativeProperty(platform, 'video-codec'),
      'hwdec-current': await _nativeProperty(platform, 'hwdec-current'),
      'current-vo': await _nativeProperty(platform, 'current-vo'),
      'width': await _nativeProperty(platform, 'width'),
      'height': await _nativeProperty(platform, 'height'),
    };
    _mpvLog('State[$label]: $properties');
  }

  Future<String> _nativeProperty(NativePlayer platform, String name) async {
    try {
      return (await platform.getProperty(name)).trim();
    } catch (_) {
      return '';
    }
  }

  static String _clean(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'no' || trimmed == '0') return 'unknown';
    return trimmed;
  }

  static String _bitrate(String video, String audio) {
    final parts = <String>[
      if (video.trim().isNotEmpty) 'video ${video.trim()}',
      if (audio.trim().isNotEmpty) 'audio ${audio.trim()}',
    ];
    return parts.isEmpty ? 'unknown' : parts.join(', ');
  }

  static String _headerKey(Map<String, String> headers, String key) {
    return headers.keys.firstWhere(
      (candidate) => candidate.toLowerCase() == key.toLowerCase(),
      orElse: () => key,
    );
  }

  static void _mpvLog(String message) {
    PlaybackRuntimeDiagnostics.mpvLog(message);
  }

  void _update({
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
    if (_disposed) return;
    _state.value = _state.value.copyWith(
      status: status,
      isPlaying: isPlaying,
      position: position,
      duration: duration,
      bufferedPosition: bufferedPosition,
      volume: volume,
      isMuted: isMuted,
      playbackSpeed: playbackSpeed,
      repeatMode: repeatMode,
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
      selectedAudioTrackId: selectedAudioTrackId,
      selectedSubtitleTrackId: selectedSubtitleTrackId,
      errorMessage: errorMessage,
      clearError: clearError,
    );
  }

  PlaybackTrackOption _audioOption(AudioTrack track) {
    return PlaybackTrackOption(
      id: track.id,
      label: _trackLabel(
        track.id,
        track.title,
        track.language,
        fallbackPrefix: 'Audio',
      ),
      language: track.language,
    );
  }

  PlaybackTrackOption _subtitleOption(SubtitleTrack track) {
    return PlaybackTrackOption(
      id: track.id,
      label: _trackLabel(
        track.id,
        track.title,
        track.language,
        fallbackPrefix: 'Subtitle',
      ),
      language: track.language,
    );
  }

  String _trackLabel(
    String id,
    String? title,
    String? language, {
    required String fallbackPrefix,
  }) {
    if (id == 'auto') return 'Auto';
    if (id == 'no') return 'Off';
    final parts = <String>[
      if (title != null && title.trim().isNotEmpty) title.trim(),
      if (language != null && language.trim().isNotEmpty) language.trim(),
    ];
    return parts.isEmpty ? '$fallbackPrefix $id' : parts.join(' · ');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final disposeClock = Stopwatch()..start();
    PlaybackRuntimeDiagnostics.mpvLog(
      'MediaKitPlaybackEngine#$debugInstanceId disposing',
      clock: disposeClock,
    );
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    PlaybackRuntimeDiagnostics.mediaPlayersDisposed++;
    PlaybackRuntimeDiagnostics.videoControllersDisposed++;
    _mpvLog(
      'Texture Released active=${PlaybackRuntimeDiagnostics.textureCount}',
    );
    _mpvLog(
      'NativeVideoController Destroyed active=${PlaybackRuntimeDiagnostics.textureCount}',
    );
    _mpvLog(
      'VideoOutput Destroyed active=${PlaybackRuntimeDiagnostics.textureCount}',
    );
    _mpvLog(
      'Player Disposed active=${PlaybackRuntimeDiagnostics.mediaPlayersAlive}',
    );
    PlaybackRuntimeDiagnostics.mediaKitEnginesDisposed++;
    PlaybackRuntimeDiagnostics.mpvLog(
      'MediaKitPlaybackEngine#$debugInstanceId shutdown complete '
      '${PlaybackRuntimeDiagnostics.lifecycleSummary()}',
      clock: disposeClock,
    );
    PlaybackRuntimeDiagnostics.snapshot('after media_kit player dispose');
    _state.dispose();
  }
}
