import 'dart:io';

import 'package:flutter/foundation.dart';

final class PlaybackRuntimeDiagnostics {
  PlaybackRuntimeDiagnostics._();

  static const bool _profileEnabled = bool.fromEnvironment(
    'NIVIO_PROFILE_PLAYBACK',
  );

  static bool get enabled => kDebugMode || _profileEnabled;

  static int webViewsCreated = 0;
  static int webViewsDestroyed = 0;
  static int webViewReuseCount = 0;
  static int mediaPlayersCreated = 0;
  static int mediaPlayersDisposed = 0;
  static int videoControllersCreated = 0;
  static int videoControllersDisposed = 0;
  static int playerScreensCreated = 0;
  static int playerScreensDisposed = 0;
  static int adaptiveEnginesCreated = 0;
  static int adaptiveEnginesDisposed = 0;
  static int webEnginesCreated = 0;
  static int webEnginesDisposed = 0;
  static int mediaKitEnginesCreated = 0;
  static int mediaKitEnginesDisposed = 0;

  static int get webViewsAlive => webViewsCreated - webViewsDestroyed;
  static int get mediaPlayersAlive =>
      mediaPlayersCreated - mediaPlayersDisposed;
  static int get textureCount =>
      videoControllersCreated - videoControllersDisposed;

  static void webLog(String message, {Stopwatch? clock}) {
    _log('web', message, clock: clock);
  }

  static void mpvLog(String message, {Stopwatch? clock}) {
    _log('mpv', message, clock: clock);
  }

  static void lifecycleLog(String message, {Stopwatch? clock}) {
    _log('runtime', message, clock: clock);
  }

  static void uiLog(String message, {Stopwatch? clock}) {
    _log('UI', message, clock: clock);
  }

  static void controllerLog(String message, {Stopwatch? clock}) {
    _log('Controller', message, clock: clock);
  }

  static void engineLog(String message, {Stopwatch? clock}) {
    _log('Engine', message, clock: clock);
  }

  static void overlayLog(String message, {Stopwatch? clock}) {
    _log('Overlay', message, clock: clock);
  }

  static void gtkLog(String message, {Stopwatch? clock}) {
    _log('GTK', message, clock: clock);
  }

  static void streamLog(String message, {Stopwatch? clock}) {
    _log('stream', message, clock: clock);
  }

  static void providerLog(String provider, String message) {
    _log('anime', '[$provider] $message');
  }

  static void snapshot(String label, {Stopwatch? clock}) {
    _log(
      'runtime',
      '$label rss=${_rss()} webViewsAlive=$webViewsAlive '
          'mediaPlayersAlive=$mediaPlayersAlive textureCount=$textureCount',
      clock: clock,
    );
  }

  static String memorySummary() {
    return 'rss=${_rss()}, webViewsAlive=$webViewsAlive, '
        'mediaPlayersAlive=$mediaPlayersAlive, textureCount=$textureCount';
  }

  static String lifecycleSummary() {
    return 'playerScreens=$playerScreensCreated/$playerScreensDisposed '
        'adaptiveEngines=$adaptiveEnginesCreated/$adaptiveEnginesDisposed '
        'webEngines=$webEnginesCreated/$webEnginesDisposed '
        'mediaKitEngines=$mediaKitEnginesCreated/$mediaKitEnginesDisposed '
        'webViews=$webViewsCreated/$webViewsDestroyed reused=$webViewReuseCount '
        'mediaPlayers=$mediaPlayersCreated/$mediaPlayersDisposed '
        'videoControllers=$videoControllersCreated/$videoControllersDisposed';
  }

  static void _log(String area, String message, {Stopwatch? clock}) {
    if (!enabled) return;
    final elapsed = clock == null ? '' : ' +${clock.elapsedMilliseconds}ms';
    // Keep lifecycle diagnostics visible in `flutter run`.
    // ignore: avoid_print
    print('[playback:$area]$elapsed $message');
  }

  static String _rss() {
    try {
      return '${(ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(1)}MiB';
    } catch (_) {
      return 'unknown';
    }
  }
}
