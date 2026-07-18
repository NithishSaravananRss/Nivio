import 'package:flutter/material.dart';

import '../shared/layout/desktop_scaffold.dart';
import '../shared/theme/theme.dart';
import '../core/interfaces/search_repository.dart';
import '../core/interfaces/home_repository.dart';
import '../features/player/services/stream_resolver.dart';
import '../features/player/playback_engine.dart';
import '../core/interfaces/watch_history_repository.dart';

/// Root widget for the Nivio Linux desktop application.
class NivioDesktopApp extends StatelessWidget {
  final SearchRepository? searchRepository;
  final HomeRepository? homeRepository;
  final StreamResolver? streamResolver;
  final PlaybackEngineFactory? playbackEngineFactory;
  final WatchHistoryRepository? watchHistoryRepository;

  const NivioDesktopApp({
    super.key,
    this.searchRepository,
    this.homeRepository,
    this.streamResolver,
    this.playbackEngineFactory,
    this.watchHistoryRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nivio Desktop',
      debugShowCheckedModeBanner: false,
      theme: buildNivioDesktopTheme(),
      home: DesktopScaffold(
        searchRepository: searchRepository,
        homeRepository: homeRepository,
        streamResolver: streamResolver,
        playbackEngineFactory: playbackEngineFactory,
        watchHistoryRepository: watchHistoryRepository,
      ),
    );
  }
}
