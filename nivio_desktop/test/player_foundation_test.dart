import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivio_desktop/features/player/models/playback_request.dart';
import 'package:nivio_desktop/features/player/models/playback_state.dart';
import 'package:nivio_desktop/features/player/playback_engine.dart';
import 'package:nivio_desktop/features/player/player_controller.dart';
import 'package:nivio_desktop/features/player/player_screen.dart';
import 'package:nivio_desktop/features/player/services/stream_resolver.dart';
import 'package:nivio_desktop/shared/models/stream_result.dart';

class FakePlaybackEngine implements PlaybackEngine {
  final ValueNotifier<PlaybackState> notifier = ValueNotifier(
    const PlaybackState(),
  );

  PlaybackRequest? loadedRequest;
  int loadCount = 0;
  Duration? soughtPosition;
  double? requestedVolume;
  int playCount = 0;
  int pauseCount = 0;
  int retryCount = 0;
  int stopCount = 0;
  int disposeCount = 0;
  String? selectedAudioTrackId;
  String? selectedSubtitleTrackId;
  double? selectedSpeed;
  PlaybackRepeatMode? selectedRepeatMode;
  SubtitleStyle? selectedSubtitleStyle;
  bool? selectedDebanding;

  @override
  ValueListenable<PlaybackState> get state => notifier;

  @override
  Future<void> load(PlaybackRequest request) async {
    loadCount++;
    loadedRequest = request;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
  }

  @override
  Future<void> play() async {
    playCount++;
  }

  @override
  Future<void> retry() async {
    retryCount++;
  }

  @override
  Future<void> seek(Duration position) async {
    soughtPosition = position;
  }

  @override
  Future<void> setVolume(double volume) async {
    requestedVolume = volume;
    notifier.value = notifier.value.copyWith(
      volume: volume,
      isMuted: volume == 0,
    );
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    selectedSpeed = speed;
    notifier.value = notifier.value.copyWith(playbackSpeed: speed);
  }

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode mode) async {
    selectedRepeatMode = mode;
    notifier.value = notifier.value.copyWith(repeatMode: mode);
  }

  @override
  Future<void> selectAudioTrack(String trackId) async {
    selectedAudioTrackId = trackId;
    notifier.value = notifier.value.copyWith(selectedAudioTrackId: trackId);
  }

  @override
  Future<void> selectSubtitleTrack(
    String trackId, {
    String? externalUrl,
  }) async {
    selectedSubtitleTrackId = trackId;
    notifier.value = notifier.value.copyWith(selectedSubtitleTrackId: trackId);
  }

  @override
  Future<void> setSubtitleDelay(Duration delay) async {}

  @override
  Future<void> setSubtitleStyle(SubtitleStyle style) async {
    selectedSubtitleStyle = style;
  }

  @override
  Future<void> setDebanding(bool enabled) async {
    selectedDebanding = enabled;
  }

  @override
  Future<PlaybackDiagnostics> diagnostics() async =>
      const PlaybackDiagnostics(backend: 'fake');

  @override
  Future<String?> takeScreenshot() async => null;

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

const movieRequest = PlaybackRequest(
  mediaId: 'movie:550',
  title: 'Foundation Test',
  mediaType: PlaybackMediaType.movie,
  source: 'https://example.com/video.mp4',
);

void main() {
  group('PlaybackRequest', () {
    test('retains Android-compatible playback context', () {
      const request = PlaybackRequest(
        mediaId: 'tv:42',
        title: 'Episode',
        mediaType: PlaybackMediaType.tv,
        source: 'https://example.com/episode.m3u8',
        season: 2,
        episode: 5,
        providerIndex: 3,
        watchPartyCode: 'PARTY1',
        watchPartyRole: 'host',
        startPosition: Duration(minutes: 4),
      );

      expect(request.hasPlayableSource, isTrue);
      expect(request.season, 2);
      expect(request.episode, 5);
      expect(request.providerIndex, 3);
      expect(request.watchPartyCode, 'PARTY1');
      expect(request.startPosition, const Duration(minutes: 4));
    });
  });

  group('DesktopPlayerController', () {
    late FakePlaybackEngine engine;
    late DesktopPlayerController controller;

    setUp(() {
      engine = FakePlaybackEngine();
      controller = DesktopPlayerController(
        engine: engine,
        request: movieRequest,
      );
    });

    test('initializes the engine with its request', () async {
      await controller.initialize();

      expect(engine.loadedRequest, same(movieRequest));
    });

    test('toggles playback from current state', () async {
      await controller.togglePlayPause();
      expect(engine.playCount, 1);

      engine.notifier.value = engine.notifier.value.copyWith(isPlaying: true);
      await controller.togglePlayPause();
      expect(engine.pauseCount, 1);
    });

    test('clamps relative seek to media bounds', () async {
      engine.notifier.value = const PlaybackState(
        status: PlaybackStatus.ready,
        position: Duration(seconds: 5),
        duration: Duration(seconds: 30),
      );

      await controller.seekBy(const Duration(seconds: -10));
      expect(engine.soughtPosition, Duration.zero);

      await controller.seekBy(const Duration(seconds: 60));
      expect(engine.soughtPosition, const Duration(seconds: 30));
    });

    test('clamps volume and restores it after mute', () async {
      engine.notifier.value = engine.notifier.value.copyWith(volume: 0.7);

      await controller.toggleMute();
      expect(engine.requestedVolume, 0);

      await controller.toggleMute();
      expect(engine.requestedVolume, 0.7);

      await controller.setVolume(2);
      expect(engine.requestedVolume, 2);
    });

    test('does not seek live playback', () async {
      final liveController = DesktopPlayerController(
        engine: engine,
        request: movieRequest.copyWith(isLive: true),
      );

      await liveController.seekBy(const Duration(seconds: 10));

      expect(engine.soughtPosition, isNull);
    });
  });

  testWidgets('player exposes retry and back actions for playback errors', (
    tester,
  ) async {
    final engine = FakePlaybackEngine();
    var closed = false;
    engine.notifier.value = const PlaybackState(
      status: PlaybackStatus.error,
      errorMessage: 'Stream unavailable',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerScreen(
          request: movieRequest,
          engine: engine,
          surfaceBuilder: (_, _) => const ColoredBox(color: Colors.black),
          onClose: () => closed = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Playback unavailable'), findsOneWidget);
    expect(find.text('Stream unavailable'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(engine.retryCount, 1);

    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(closed, isTrue);
    expect(engine.stopCount, 1);
  });

  testWidgets('native player shows one server control in the top bar', (
    tester,
  ) async {
    final engine = FakePlaybackEngine();
    engine.notifier.value = const PlaybackState(
      status: PlaybackStatus.ready,
      duration: Duration(minutes: 24),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerScreen(
          request: movieRequest,
          engine: engine,
          surfaceBuilder: (_, _) => const ColoredBox(color: Colors.black),
          onClose: () {},
          sourceOptions: const [
            PlaybackSourceOption(index: 0, provider: 'Nivio', server: 'Nivio'),
            PlaybackSourceOption(index: 1, provider: 'VidUp', server: 'VidUp'),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Server'), findsOneWidget);
    expect(find.byTooltip('Change server'), findsNothing);
  });

  testWidgets('player reloads request updates without disposing its engine', (
    tester,
  ) async {
    final engine = FakePlaybackEngine();
    final nextRequest = movieRequest.copyWith(
      providerIndex: 1,
      source: 'https://example.com/backup.mp4',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerScreen(
          request: movieRequest,
          engine: engine,
          surfaceBuilder: (_, _) => const ColoredBox(color: Colors.black),
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    expect(engine.loadedRequest, movieRequest);
    expect(engine.loadCount, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerScreen(
          request: nextRequest,
          engine: engine,
          surfaceBuilder: (_, _) => const ColoredBox(color: Colors.black),
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    expect(engine.loadedRequest, nextRequest);
    expect(engine.loadCount, 2);
    expect(engine.disposeCount, 0);
  });

  testWidgets('iframe playback delegates app controls to WebView bridge', (
    tester,
  ) async {
    final engine = FakePlaybackEngine();
    final iframeRequest = movieRequest.copyWith(
      source: 'https://vidup.example/embed/movie',
      streamResult: StreamResult(
        url: 'https://vidup.example/embed/movie',
        quality: 'auto',
        provider: 'VidUp',
        providerIndex: 1,
        isDirect: false,
        isIframe: true,
      ),
      providerIndex: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerScreen(
          request: iframeRequest,
          engine: engine,
          surfaceBuilder: (_, _) => const ColoredBox(color: Colors.black),
          onClose: () {},
          sourceOptions: const [
            PlaybackSourceOption(
              index: 0,
              provider: 'Direct',
              server: 'Direct',
            ),
            PlaybackSourceOption(index: 1, provider: 'VidUp', server: 'VidUp'),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Server'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.text('Server'), findsNothing);
    expect(find.text('Select Server'), findsNothing);

    await tester.tap(find.byTooltip('Server'));
    await tester.pump();

    expect(find.text('Select Server'), findsOneWidget);
  });

  testWidgets('ready iframe playback does not show Flutter escape top bar', (
    tester,
  ) async {
    final engine = FakePlaybackEngine();
    engine.notifier.value = const PlaybackState(status: PlaybackStatus.ready);
    final iframeRequest = movieRequest.copyWith(
      source: 'https://vidup.example/embed/movie',
      streamResult: StreamResult(
        url: 'https://vidup.example/embed/movie',
        quality: 'auto',
        provider: 'VidUp',
        providerIndex: 1,
        isDirect: false,
        isIframe: true,
      ),
      providerIndex: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerScreen(
          request: iframeRequest,
          engine: engine,
          surfaceBuilder: (_, _) => const ColoredBox(color: Colors.black),
          onClose: () {},
          sourceOptions: const [
            PlaybackSourceOption(index: 0, provider: 'Nivio', server: 'Nivio'),
            PlaybackSourceOption(index: 1, provider: 'VidUp', server: 'VidUp'),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byTooltip('Server'), findsNothing);
    expect(find.textContaining('Ready'), findsNothing);
  });

  testWidgets('iframe playback error automatically switches to next source', (
    tester,
  ) async {
    final engine = FakePlaybackEngine();
    PlaybackRequest? switchedRequest;
    final iframeRequest = movieRequest.copyWith(
      source: 'https://vidlink.example/embed/movie',
      streamResult: StreamResult(
        url: 'https://vidlink.example/embed/movie',
        quality: 'auto',
        provider: 'VidLink',
        providerIndex: 2,
        isDirect: false,
        isIframe: true,
      ),
      providerIndex: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerScreen(
          request: iframeRequest,
          engine: engine,
          surfaceBuilder: (_, _) => const ColoredBox(color: Colors.black),
          onClose: () {},
          onSourceSwitch: (request) => switchedRequest = request,
          sourceOptions: const [
            PlaybackSourceOption(index: 0, provider: 'Nivio', server: 'Nivio'),
            PlaybackSourceOption(index: 1, provider: 'VidUp', server: 'VidUp'),
            PlaybackSourceOption(
              index: 2,
              provider: 'VidLink',
              server: 'VidLink',
            ),
            PlaybackSourceOption(
              index: 3,
              provider: 'VidCore',
              server: 'VidCore',
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    engine.notifier.value = const PlaybackState(
      status: PlaybackStatus.error,
      errorMessage: 'Embedded provider reported no stream.',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(switchedRequest?.providerIndex, 3);
    expect(switchedRequest?.source, isNull);
    expect(switchedRequest?.streamResult, isNull);
  });
}
