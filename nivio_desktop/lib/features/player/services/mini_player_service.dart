import 'package:flutter/foundation.dart';

import '../../../core/interfaces/watch_history_repository.dart';
import '../models/playback_request.dart';
import '../playback_engine.dart';
import 'stream_resolver.dart';

class MiniPlayerSession {
  const MiniPlayerSession({
    required this.request,
    required this.engine,
    required this.sourceOptions,
    this.watchHistoryRepository,
  });

  final PlaybackRequest request;
  final PlaybackEngine engine;
  final List<PlaybackSourceOption> sourceOptions;
  final WatchHistoryRepository? watchHistoryRepository;
}

class MiniPlayerService extends ChangeNotifier {
  MiniPlayerService._();

  static final MiniPlayerService instance = MiniPlayerService._();

  MiniPlayerSession? _session;

  MiniPlayerSession? get session => _session;
  bool get isActive => _session != null;

  void activate(MiniPlayerSession session) {
    final previous = _session;
    if (previous != null && !identical(previous.engine, session.engine)) {
      previous.engine.dispose();
    }
    _session = session;
    notifyListeners();
  }

  Future<void> deactivate({bool disposeEngine = true}) async {
    final previous = _session;
    if (previous == null) return;
    _session = null;
    notifyListeners();
    if (disposeEngine) {
      await previous.engine.dispose();
    }
  }

  MiniPlayerSession? reclaimIfMatches(PlaybackRequest request) {
    final current = _session;
    if (current == null || !_sameTarget(current.request, request)) return null;
    _session = null;
    notifyListeners();
    return current;
  }

  bool matches(PlaybackRequest request) {
    final current = _session;
    return current != null && _sameTarget(current.request, request);
  }

  static bool _sameTarget(PlaybackRequest a, PlaybackRequest b) {
    return a.mediaId == b.mediaId &&
        a.mediaType == b.mediaType &&
        a.season == b.season &&
        a.episode == b.episode;
  }
}
