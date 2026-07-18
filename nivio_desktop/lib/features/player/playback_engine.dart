import 'package:flutter/foundation.dart';

import 'models/playback_request.dart';
import 'models/playback_state.dart';

typedef PlaybackEngineFactory = PlaybackEngine Function();

/// Backend-neutral playback contract used by the Desktop player UI.
abstract interface class PlaybackEngine {
  ValueListenable<PlaybackState> get state;

  Future<void> load(PlaybackRequest request);
  Future<void> retry();
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setPlaybackSpeed(double speed);
  Future<void> setRepeatMode(PlaybackRepeatMode mode);
  Future<void> selectAudioTrack(String trackId);
  Future<void> selectSubtitleTrack(String trackId, {String? externalUrl});
  Future<void> setSubtitleDelay(Duration delay);
  Future<void> setSubtitleStyle(SubtitleStyle style);
  Future<void> setDebanding(bool enabled);
  Future<PlaybackDiagnostics> diagnostics();
  Future<String?> takeScreenshot();
  Future<void> dispose();
}
