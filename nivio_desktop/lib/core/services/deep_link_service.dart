import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../features/player/models/playback_request.dart';

sealed class DesktopDeepLink {
  const DesktopDeepLink();
}

class OpenMediaDeepLink extends DesktopDeepLink {
  const OpenMediaDeepLink({required this.mediaType, required this.mediaId});

  final String mediaType;
  final int mediaId;
}

class PlayMediaDeepLink extends DesktopDeepLink {
  const PlayMediaDeepLink({required this.request});

  final PlaybackRequest request;
}

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final ValueNotifier<DesktopDeepLink?> latest = ValueNotifier(null);
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final appLinks = AppLinks();
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handle(initial);
      _subscription = appLinks.uriLinkStream.listen(_handle);
    } catch (error) {
      debugPrint('Deep link initialization failed: $error');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void handleForTest(Uri uri) => _handle(uri);

  void _handle(Uri uri) {
    final link = _parse(uri);
    if (link == null) return;
    latest.value = link;
  }

  DesktopDeepLink? _parse(Uri uri) {
    if (uri.scheme != 'nivio' && uri.scheme != 'https') return null;
    final segments = uri.pathSegments;
    final host = uri.host.toLowerCase();
    final action = host == 'play' || segments.contains('play')
        ? 'play'
        : 'open';

    final mediaIndex = segments.indexOf('media');
    final idText = mediaIndex >= 0 && mediaIndex + 1 < segments.length
        ? segments[mediaIndex + 1]
        : uri.queryParameters['id'];
    final mediaId = int.tryParse(idText ?? '');
    if (mediaId == null) return null;

    final type = _mediaType(uri.queryParameters['type']);
    if (action == 'play' || uri.queryParameters['play'] == 'true') {
      return PlayMediaDeepLink(
        request: PlaybackRequest(
          mediaId: '$type:$mediaId',
          title: uri.queryParameters['title'] ?? 'Nivio',
          mediaType: _playbackType(type),
          season: int.tryParse(uri.queryParameters['season'] ?? ''),
          episode: int.tryParse(uri.queryParameters['episode'] ?? ''),
          startPosition: Duration(
            seconds:
                int.tryParse(
                  uri.queryParameters['position'] ??
                      uri.queryParameters['t'] ??
                      '',
                ) ??
                0,
          ),
        ),
      );
    }

    return OpenMediaDeepLink(mediaType: type, mediaId: mediaId);
  }

  static String _mediaType(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'tv' || 'show' || 'series' => 'tv',
      'anime' => 'anime',
      'movie' || null || '' => 'movie',
      final other => other,
    };
  }

  static PlaybackMediaType _playbackType(String value) {
    return switch (value) {
      'movie' => PlaybackMediaType.movie,
      'tv' => PlaybackMediaType.tv,
      'anime' => PlaybackMediaType.anime,
      _ => PlaybackMediaType.unknown,
    };
  }
}
