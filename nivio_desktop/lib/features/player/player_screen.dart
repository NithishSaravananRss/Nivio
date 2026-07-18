import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../shared/theme/index.dart';
import '../../core/interfaces/watch_history_repository.dart';
import '../../core/network/image/tmdb_image_builder.dart';
import '../../shared/models/watch_party_models.dart';
import '../../shared/models/skip_times_models.dart';
import '../../shared/models/stream_result.dart' as stream_models;
import 'adaptive_playback_engine.dart';
import 'media_kit_playback_engine.dart';
import 'models/playback_request.dart';
import 'models/playback_state.dart';
import 'playback_engine.dart';
import 'playback_surface.dart';
import 'player_controller.dart';
import 'web_playback_engine.dart';
import '../party/services/watch_party_service_supabase.dart';
import '../party/services/watch_party_session_manager.dart';
import 'services/m3u8_parser.dart';
import 'services/playback_runtime_diagnostics.dart';
import 'services/stream_resolver.dart';

typedef PlaybackSurfaceBuilder =
    Widget Function(BuildContext context, PlaybackEngine engine);

/// Foundation player surface. Stream resolution and application routing are
/// intentionally introduced in Phase 22.2.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.request,
    this.engine,
    this.surfaceBuilder,
    this.onClose,
    this.onNextEpisode,
    this.onSourceSwitch,
    this.sourceOptions = const [],
    this.watchHistoryRepository,
  });

  final PlaybackRequest request;
  final PlaybackEngine? engine;
  final PlaybackSurfaceBuilder? surfaceBuilder;
  final VoidCallback? onClose;
  final ValueChanged<PlaybackRequest>? onNextEpisode;
  final ValueChanged<PlaybackRequest>? onSourceSwitch;
  final List<PlaybackSourceOption> sourceOptions;
  final WatchHistoryRepository? watchHistoryRepository;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static int _nextInstanceId = 0;

  final int _instanceId = ++_nextInstanceId;
  late final bool _ownsEngine = widget.engine == null;
  late final PlaybackEngine _engine =
      widget.engine ??
      AdaptivePlaybackEngine(
        webFactory: () => WebPlaybackEngine(
          onPointerActivity: _showControlsFromPlaybackSurface,
          onBackRequested: _close,
          onServerRequested: _openWebServerDrawer,
          onEpisodesRequested: widget.request.totalEpisodes == null
              ? null
              : _showEpisodeSelector,
        ),
      );
  late final DesktopPlayerController _controller = DesktopPlayerController(
    engine: _engine,
    request: widget.request,
    watchHistoryRepository: widget.watchHistoryRepository,
  );
  final List<_QualityOption> _qualityOptions = [];
  bool _qualityDiscoveryComplete = false;
  bool _autoplayNextEpisode = true;
  bool _nextEpisodeStarted = false;
  bool _preferredQualityApplied = false;
  Duration _subtitleDelay = Duration.zero;
  bool _controlsVisible = true;
  bool _closeInFlight = false;
  bool _debandingEnabled = false;
  bool _sourceSwitchInFlight = false;
  bool _subtitleBackgroundEnabled = false;
  bool _subtitleOutlineEnabled = false;
  double _subtitleScale = 1;
  BoxFit _displayFit = BoxFit.contain;
  _PlayerDrawer _drawer = _PlayerDrawer.none;
  _WebOverlayDrawer _webDrawer = _WebOverlayDrawer.none;
  int _webOverlayGeneration = 0;
  Timer? _hideControlsTimer;
  Timer? _volumeOverlayTimer;
  Timer? _embeddedProviderFallbackTimer;
  Timer? _watchPartyHostSyncTimer;
  int? _handledEmbeddedErrorProviderIndex;
  double? _volumeOverlayValue;
  WatchPartyServiceSupabase? _watchPartyService;
  WatchPartySession? _watchPartySession;
  WatchPartyPlaybackState? _pendingWatchPartyPlayback;
  StreamSubscription<WatchPartyPlaybackState>? _watchPartyPlaybackSub;
  StreamSubscription<WatchPartySession?>? _watchPartySessionSub;
  StreamSubscription<WatchPartyChatMessage>? _watchPartyChatSub;
  StreamSubscription<WatchPartyReaction>? _watchPartyReactionSub;
  StreamSubscription<String>? _watchPartyErrorSub;
  DateTime? _lastWatchPartyBroadcastAt;
  String? _lastEmbeddedLayoutSnapshotKey;
  bool _isApplyingWatchPartyState = false;
  bool _isPartyRouteSyncInFlight = false;
  String? _watchPartyStatusMessage;
  Rect? _embeddedTopBarRect;
  Rect? _embeddedSurfaceRect;
  final List<WatchPartyChatMessage> _watchPartyMessages = [];
  final List<WatchPartyReaction> _watchPartyReactions = [];

  static const Duration _watchPartyProgressInterval = Duration(
    milliseconds: 1800,
  );
  static const Duration _watchPartyPeriodicSyncInterval = Duration(seconds: 3);
  static const int _watchPartyDriftThresholdMs = 1200;

  @override
  void initState() {
    super.initState();
    _configureEmbeddedWebAppControls();
    PlaybackRuntimeDiagnostics.playerScreensCreated++;
    PlaybackRuntimeDiagnostics.uiLog(
      'PlayerScreen#$_instanceId init mounted=$mounted '
      'ownsEngine=$_ownsEngine request=${widget.request.mediaId} '
      'type=${widget.request.mediaTypeName} '
      '${PlaybackRuntimeDiagnostics.lifecycleSummary()}',
    );
    _qualityOptions.addAll(_qualityOptionsFromResult(widget.request));
    unawaited(_initializeController());
    unawaited(_discoverHlsQualities());
    unawaited(_initializeWatchParty());
    _engine.state.addListener(_onPlaybackChanged);
    _scheduleControlsHide();
  }

  void _configureEmbeddedWebAppControls() {
    final onEpisodes = widget.request.totalEpisodes == null
        ? null
        : _showEpisodeSelector;
    final sourceOptions = widget.sourceOptions
        .map(
          (option) => <String, Object?>{
            'index': option.index,
            'provider': option.provider,
            'server': option.server,
            'group': option.group,
            'label': option.label,
            'selected': option.index == _controller.request.providerIndex,
          },
        )
        .toList(growable: false);
    final engine = _engine;
    if (engine is AdaptivePlaybackEngine) {
      engine.configureWebAppControls(
        onPointerActivity: _showControlsFromPlaybackSurface,
        onBackRequested: _close,
        onServerRequested: _openWebServerDrawer,
        onEpisodesRequested: onEpisodes,
        onSourceIndexRequested: _selectEmbeddedWebSourceByIndex,
        sourceOptions: sourceOptions,
        selectedSourceIndex: _controller.request.providerIndex,
        providerLabel: _providerLabel,
        serverLabel: _serverLabel ?? widget.request.streamResult?.providerGroup,
      );
    } else if (engine is WebPlaybackEngine) {
      engine.configureAppControls(
        onPointerActivity: _showControlsFromPlaybackSurface,
        onBackRequested: _close,
        onServerRequested: _openWebServerDrawer,
        onEpisodesRequested: onEpisodes,
        onSourceIndexRequested: _selectEmbeddedWebSourceByIndex,
        sourceOptions: sourceOptions,
        selectedSourceIndex: _controller.request.providerIndex,
        providerLabel: _providerLabel,
        serverLabel: _serverLabel ?? widget.request.streamResult?.providerGroup,
      );
    }
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configureEmbeddedWebAppControls();
    final wasEmbeddedWeb = _requestUsesEmbeddedWebPlayback(oldWidget.request);
    final isEmbeddedWeb = _requestUsesEmbeddedWebPlayback(widget.request);
    PlaybackRuntimeDiagnostics.uiLog(
      'PlayerScreen didUpdateWidget mounted=$mounted '
      'sameRequest=${_samePlaybackRequest(oldWidget.request, widget.request)} '
      'oldProvider=${oldWidget.request.providerIndex ?? 'auto'} '
      'newProvider=${widget.request.providerIndex ?? 'auto'} '
      'wasEmbeddedWeb=$wasEmbeddedWeb isEmbeddedWeb=$isEmbeddedWeb '
      'iframeControls=androidContract',
    );
    if (_samePlaybackRequest(oldWidget.request, widget.request)) return;

    if (isEmbeddedWeb) {
      _destroySharedOverlayForWebTransition(
        reason: wasEmbeddedWeb
            ? 'WebView -> WebView request transition'
            : 'MediaKit -> WebView request transition',
      );
    } else if (wasEmbeddedWeb && !isEmbeddedWeb) {
      _destroySharedOverlayForWebTransition(
        reason: 'WebView -> MediaKit request transition',
      );
    }

    _sourceSwitchInFlight = false;
    _handledEmbeddedErrorProviderIndex = null;
    _embeddedProviderFallbackTimer?.cancel();
    _nextEpisodeStarted = false;
    _preferredQualityApplied = false;
    _qualityDiscoveryComplete = false;
    _qualityOptions
      ..clear()
      ..addAll(_qualityOptionsFromResult(widget.request));

    unawaited(_loadUpdatedRequest(widget.request));
    unawaited(_discoverHlsQualities());
  }

  bool _samePlaybackRequest(PlaybackRequest a, PlaybackRequest b) {
    return a.mediaId == b.mediaId &&
        a.mediaType == b.mediaType &&
        a.season == b.season &&
        a.episode == b.episode &&
        a.providerIndex == b.providerIndex &&
        a.preferredQuality == b.preferredQuality &&
        a.preferredAudioTrack == b.preferredAudioTrack &&
        a.preferredSubtitleTrack == b.preferredSubtitleTrack &&
        a.source == b.source &&
        a.streamResult?.url == b.streamResult?.url;
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
    if (!mounted || _controller.debugDisposed) return;
    _applyPreferredQuality();
    if (_pendingWatchPartyPlayback != null) {
      final pending = _pendingWatchPartyPlayback!;
      _pendingWatchPartyPlayback = null;
      unawaited(_applyWatchPartyPlayback(pending));
    }
    unawaited(_broadcastWatchPartyPlayback(force: true));
  }

  Future<void> _loadUpdatedRequest(PlaybackRequest request) async {
    await _controller.loadRequest(request);
    if (!mounted || !_samePlaybackRequest(widget.request, request)) return;
    _applyPreferredQuality();
    unawaited(_broadcastWatchPartyPlayback(force: true));
  }

  Future<void> _initializeWatchParty() async {
    if (!_hasWatchPartyContext) return;

    final service = await WatchPartySessionManager.instance.ensureService();
    if (!mounted || service == null) {
      _showWatchPartyStatus('Watch Party unavailable.');
      return;
    }

    _watchPartyService = service;
    _watchPartyPlaybackSub ??= service.playbackStream.listen((playback) {
      unawaited(_applyWatchPartyPlayback(playback));
    });
    _watchPartySessionSub ??= service.sessionStream.listen((session) {
      if (!mounted) return;
      setState(() => _watchPartySession = session);
      _updateWatchPartyHostSyncTimer();
    });
    _watchPartyChatSub ??= service.chatStream.listen((message) {
      if (!mounted) return;
      setState(() {
        _watchPartyMessages.add(message);
        if (_watchPartyMessages.length > 8) _watchPartyMessages.removeAt(0);
      });
    });
    _watchPartyReactionSub ??= service.reactionStream.listen((reaction) {
      if (!mounted) return;
      setState(() {
        _watchPartyReactions.add(reaction);
        if (_watchPartyReactions.length > 8) {
          _watchPartyReactions.removeAt(0);
        }
      });
    });
    _watchPartyErrorSub ??= service.errorStream.listen((message) {
      if (!mounted || message.trim().isEmpty) return;
      _showWatchPartyStatus(message.trim());
    });

    final role = WatchPartyRoleX.fromQuery(widget.request.watchPartyRole);
    final code = (widget.request.watchPartyCode ?? '').trim().toUpperCase();
    if (role == null || code.isEmpty) return;

    final existingCode = service.currentSession?.sessionCode.toUpperCase();
    var ok = true;
    if (existingCode != code) {
      if (role == WatchPartyRole.host) {
        ok = await service.createSession(preferredCode: code) != null;
      } else {
        ok = await service.joinSession(code);
      }
    }

    if (!mounted) return;
    if (!ok) {
      _showWatchPartyStatus('Unable to connect to watch party.');
      return;
    }

    setState(() => _watchPartySession = service.currentSession);
    _updateWatchPartyHostSyncTimer();
    if (service.isHost) {
      _scheduleWatchPartyBootstrapSyncs();
    } else {
      unawaited(service.requestStateSync(reason: 'player_opened'));
    }
  }

  bool get _hasWatchPartyContext {
    return (widget.request.watchPartyCode ?? '').trim().isNotEmpty &&
        WatchPartyRoleX.fromQuery(widget.request.watchPartyRole) != null;
  }

  bool get _hasActiveWatchPartySession =>
      _watchPartyService?.isInSession == true;

  bool get _canControlPartyPlayback {
    final service = _watchPartyService;
    if (!_hasActiveWatchPartySession || service == null) return true;
    return service.canControlPlayback;
  }

  String get _partyConnectionLabel {
    final service = _watchPartyService;
    if (!_hasWatchPartyContext) return '';
    if (service == null) return 'Connecting';
    if (!service.isInSession) return 'Disconnected';
    return 'Connected';
  }

  String get _partyControllerLabel {
    final service = _watchPartyService;
    final session = _watchPartySession;
    if (service == null || session == null) return 'Unknown';
    if (session.controllerId == null || session.controllerId!.isEmpty) {
      return 'Host';
    }
    for (final participant in session.participants) {
      if (participant.id == session.controllerId) return participant.name;
    }
    return 'Delegated';
  }

  void _showWatchPartyStatus(String message) {
    if (!mounted) return;
    setState(() => _watchPartyStatusMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _watchPartyStatusMessage != message) return;
      setState(() => _watchPartyStatusMessage = null);
    });
  }

  bool _ensurePartyCanControl() {
    if (_canControlPartyPlayback) return true;
    _showWatchPartyStatus(
      'Only the host or delegated controller can control playback.',
    );
    return false;
  }

  Future<void> _sendWatchPartyChat(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _watchPartyService?.sendChatMessage(trimmed);
  }

  Future<void> _sendWatchPartyReaction(String emoji) async {
    await _watchPartyService?.sendReaction(emoji);
  }

  Future<void> _leaveOrEndWatchParty() async {
    final service = _watchPartyService;
    if (service == null) return;
    if (service.isHost) {
      await service.endSession();
      _showWatchPartyStatus('Watch party ended');
    } else {
      await service.leaveSession();
      _showWatchPartyStatus('Left watch party');
    }
    if (!mounted) return;
    setState(() => _watchPartySession = null);
    _watchPartyHostSyncTimer?.cancel();
    _watchPartyHostSyncTimer = null;
  }

  void _scheduleWatchPartyBootstrapSyncs() {
    if (_watchPartyService?.isInSession != true ||
        _watchPartyService?.canControlPlayback != true) {
      return;
    }
    unawaited(_broadcastWatchPartyPlayback(force: true));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) unawaited(_broadcastWatchPartyPlayback(force: true));
    });
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) unawaited(_broadcastWatchPartyPlayback(force: true));
    });
  }

  void _updateWatchPartyHostSyncTimer() {
    final service = _watchPartyService;
    final shouldSync =
        service?.isInSession == true && service?.canControlPlayback == true;
    if (!shouldSync) {
      _watchPartyHostSyncTimer?.cancel();
      _watchPartyHostSyncTimer = null;
      return;
    }
    if (_watchPartyHostSyncTimer != null) return;
    _watchPartyHostSyncTimer = Timer.periodic(
      _watchPartyPeriodicSyncInterval,
      (_) => unawaited(_broadcastWatchPartyPlayback(force: true)),
    );
  }

  Future<void> _broadcastWatchPartyPlayback({required bool force}) async {
    final service = _watchPartyService;
    if (service == null ||
        !service.canControlPlayback ||
        _isApplyingWatchPartyState ||
        !service.isInSession) {
      return;
    }

    final state = _engine.state.value;
    if (state.status == PlaybackStatus.idle ||
        state.status == PlaybackStatus.loading ||
        state.status == PlaybackStatus.error) {
      return;
    }

    final now = DateTime.now();
    if (!force &&
        _lastWatchPartyBroadcastAt != null &&
        now.difference(_lastWatchPartyBroadcastAt!) <
            _watchPartyProgressInterval) {
      return;
    }

    final mediaId = _watchPartyMediaId;
    if (mediaId == null) return;

    await service.syncPlayback(
      mediaId: mediaId,
      mediaType: _watchPartyMediaType,
      providerIndex: _controller.request.providerIndex,
      season: _controller.request.season ?? 1,
      episode: _controller.request.episode ?? 1,
      positionMs: state.position.inMilliseconds,
      isPlaying: state.isPlaying,
    );
    _lastWatchPartyBroadcastAt = now;
  }

  int? get _watchPartyMediaId {
    final numeric = _controller.request.numericMediaId;
    if (numeric != null && numeric > 0) return numeric;
    return widget.request.numericMediaId;
  }

  String get _watchPartyMediaType {
    final type = _controller.request.mediaTypeName.trim();
    if (type.isNotEmpty && type != 'unknown') return type;
    return widget.request.mediaTypeName;
  }

  Future<void> _applyWatchPartyPlayback(
    WatchPartyPlaybackState playback,
  ) async {
    final service = _watchPartyService;
    if (!mounted || service == null || playback.hostId == service.userId) {
      return;
    }

    final localMediaId = _watchPartyMediaId;
    final localSeason = _controller.request.season ?? 1;
    final localEpisode = _controller.request.episode ?? 1;
    final localProvider = _controller.request.providerIndex;
    final mediaChanged =
        localMediaId != playback.mediaId ||
        _watchPartyMediaType != playback.mediaType;
    final episodeChanged =
        localSeason != playback.season || localEpisode != playback.episode;
    final providerChanged =
        playback.providerIndex != null &&
        localProvider != playback.providerIndex;

    if (mediaChanged || episodeChanged || providerChanged) {
      _syncRouteToWatchPartyPlayback(playback);
      return;
    }

    final currentState = _engine.state.value;
    if (currentState.duration == Duration.zero &&
        currentState.status == PlaybackStatus.loading) {
      _pendingWatchPartyPlayback = playback;
      return;
    }
    if (_isApplyingWatchPartyState) return;

    _isApplyingWatchPartyState = true;
    try {
      final expectedMs = playback.expectedPositionMs;
      final currentMs = currentState.position.inMilliseconds;
      final driftMs = (currentMs - expectedMs).abs();
      if (driftMs > _watchPartyDriftThresholdMs) {
        await _engine.seek(Duration(milliseconds: math.max(0, expectedMs)));
      }

      final localIsPlaying = _engine.state.value.isPlaying;
      if (playback.isPlaying && !localIsPlaying) {
        await _engine.play();
      } else if (!playback.isPlaying && localIsPlaying) {
        await _engine.pause();
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 350), () {
        _isApplyingWatchPartyState = false;
      });
    }
  }

  void _syncRouteToWatchPartyPlayback(WatchPartyPlaybackState playback) {
    if (_isPartyRouteSyncInFlight || !mounted) return;
    _isPartyRouteSyncInFlight = true;

    final callback = widget.onSourceSwitch ?? widget.onNextEpisode;
    if (callback == null) return;
    unawaited(_controller.stop());
    callback(
      _controller.request.copyWith(
        mediaId: '${playback.mediaType}:${playback.mediaId}',
        title: playback.mediaId == _watchPartyMediaId
            ? _controller.request.title
            : 'Media ${playback.mediaId}',
        mediaType: _playbackMediaTypeFromName(playback.mediaType),
        season: playback.season,
        episode: playback.episode,
        providerIndex: playback.providerIndex,
        watchPartyCode: widget.request.watchPartyCode,
        watchPartyRole: widget.request.watchPartyRole,
        startPosition: Duration(milliseconds: playback.expectedPositionMs),
        clearSource: true,
        clearStreamResult: true,
        clearPreferredQuality: true,
      ),
    );
  }

  PlaybackMediaType _playbackMediaTypeFromName(String type) {
    return switch (type.trim().toLowerCase()) {
      'movie' => PlaybackMediaType.movie,
      'tv' => PlaybackMediaType.tv,
      'anime' => PlaybackMediaType.anime,
      'live' || 'livetv' || 'live_tv' => PlaybackMediaType.liveTv,
      _ => PlaybackMediaType.unknown,
    };
  }

  @override
  void dispose() {
    PlaybackRuntimeDiagnostics.uiLog(
      'PlayerScreen#$_instanceId dispose start mounted=$mounted '
      'ownsEngine=$_ownsEngine '
      'controllerDisposed=${_controller.debugDisposed} '
      'engineDisposed=${_engineDisposedLabel()}',
    );
    _engine.state.removeListener(_onPlaybackChanged);
    _hideControlsTimer?.cancel();
    _volumeOverlayTimer?.cancel();
    _embeddedProviderFallbackTimer?.cancel();
    _watchPartyHostSyncTimer?.cancel();
    unawaited(_watchPartyPlaybackSub?.cancel());
    unawaited(_watchPartySessionSub?.cancel());
    unawaited(_watchPartyChatSub?.cancel());
    unawaited(_watchPartyReactionSub?.cancel());
    unawaited(_watchPartyErrorSub?.cancel());
    if (_ownsEngine) {
      unawaited(_controller.close());
    } else {
      unawaited(_controller.detachUi());
    }
    PlaybackRuntimeDiagnostics.playerScreensDisposed++;
    super.dispose();
    PlaybackRuntimeDiagnostics.uiLog(
      'PlayerScreen#$_instanceId dispose complete '
      '${PlaybackRuntimeDiagnostics.lifecycleSummary()}',
    );
  }

  void _onPlaybackChanged() {
    final state = _engine.state.value;
    unawaited(_broadcastWatchPartyPlayback(force: false));
    if (_pendingWatchPartyPlayback != null &&
        state.status != PlaybackStatus.loading &&
        state.status != PlaybackStatus.idle &&
        state.status != PlaybackStatus.error) {
      final pending = _pendingWatchPartyPlayback!;
      _pendingWatchPartyPlayback = null;
      unawaited(_applyWatchPartyPlayback(pending));
    }
    if (state.status == PlaybackStatus.completed && _autoplayNextEpisode) {
      _startNextEpisode();
      return;
    }
    if (!_autoplayNextEpisode ||
        _nextEpisodeStarted ||
        !_hasNextEpisode ||
        widget.request.isLive ||
        state.duration <= Duration.zero) {
      return;
    }
    final remaining = state.duration - state.position;
    if (remaining <= Duration.zero || remaining > const Duration(seconds: 1)) {
      return;
    }
    _startNextEpisode();
  }

  void _close() {
    if (_closeInFlight) return;
    _closeInFlight = true;
    unawaited(_closeAfterStoppingPlayback());
  }

  Future<void> _closeAfterStoppingPlayback() async {
    await _controller.stop();
    if (!mounted) return;
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      await Navigator.of(context).maybePop();
    }
  }

  void _selectEmbeddedWebSourceByIndex(int index) {
    PlaybackRuntimeDiagnostics.overlayLog(
      'WebView DOM server source requested index=$index '
      'sourceCount=${widget.sourceOptions.length}',
    );
    for (final option in widget.sourceOptions) {
      if (option.index == index) {
        unawaited(_switchSource(option));
        return;
      }
    }
  }

  void _toggleControls() {
    if (_drawer != _PlayerDrawer.none) {
      setState(() => _drawer = _PlayerDrawer.none);
      _scheduleControlsHide();
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleControlsHide();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleControlsHide();
  }

  void _showControlsFromPlaybackSurface() {
    if (!mounted) return;
    _showControls();
  }

  void _scheduleControlsHide() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _drawer != _PlayerDrawer.none) return;
      if (_engine.state.value.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _openDrawer(_PlayerDrawer drawer) {
    PlaybackRuntimeDiagnostics.uiLog(
      '${drawer == _PlayerDrawer.server ? 'Server' : 'Settings'} button pressed',
    );
    _logInteractionSnapshot('before drawer open request=$drawer');
    setState(() {
      _controlsVisible = true;
      _drawer = _drawer == drawer ? _PlayerDrawer.none : drawer;
    });
    PlaybackRuntimeDiagnostics.uiLog(
      'Drawer opening requested=$drawer actual=$_drawer mounted=$mounted',
    );
    _logInteractionSnapshot('after drawer open request=$drawer');
    _hideControlsTimer?.cancel();
  }

  void _openWebServerDrawer() {
    PlaybackRuntimeDiagnostics.uiLog(
      'WebView Server button pressed owner=PlayerScreen#$_instanceId '
      'mounted=$mounted contextMounted=${context.mounted} '
      'requestProvider=${widget.request.providerIndex ?? 'auto'} '
      'controllerProvider=${_controller.request.providerIndex ?? 'auto'} '
      'playback=${_engine.state.value.status.name}',
    );
    _logInteractionSnapshot('before web drawer open');
    setState(() {
      _controlsVisible = true;
      _drawer = _PlayerDrawer.none;
      _webDrawer = _WebOverlayDrawer.none;
      _webOverlayGeneration++;
    });
    PlaybackRuntimeDiagnostics.overlayLog(
      'WebView-specific server drawer delegated to DOM overlay actual=$_webDrawer '
      'generation=$_webOverlayGeneration sharedDrawer=$_drawer',
    );
    _logInteractionSnapshot('after web drawer open');
    _hideControlsTimer?.cancel();
  }

  void _toggleEmbeddedWebServerDrawer() {
    PlaybackRuntimeDiagnostics.uiLog(
      'Flutter embedded WebView server button pressed '
      'owner=PlayerScreen#$_instanceId current=$_webDrawer',
    );
    setState(() {
      _controlsVisible = true;
      _drawer = _PlayerDrawer.none;
      _webDrawer = _webDrawer == _WebOverlayDrawer.server
          ? _WebOverlayDrawer.none
          : _WebOverlayDrawer.server;
      _webOverlayGeneration++;
    });
    _hideControlsTimer?.cancel();
  }

  void _destroySharedOverlayForWebTransition({required String reason}) {
    PlaybackRuntimeDiagnostics.overlayLog(
      'Experiment destroying shared overlay before WebView contract '
      'reason=$reason sharedDrawer=$_drawer webDrawer=$_webDrawer '
      'generation=$_webOverlayGeneration',
    );
    _drawer = _PlayerDrawer.none;
    _webDrawer = _WebOverlayDrawer.none;
    _webOverlayGeneration++;
    _lastEmbeddedLayoutSnapshotKey = null;
    PlaybackRuntimeDiagnostics.overlayLog(
      'Experiment created fresh WebView overlay generation=$_webOverlayGeneration',
    );
  }

  String _focusOwnerLabel() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return 'none';
    final label = focus.debugLabel;
    final widgetType = focus.context?.widget.runtimeType.toString();
    return label == null || label.isEmpty
        ? widgetType ?? focus.runtimeType.toString()
        : '$label/$widgetType';
  }

  String _engineDisposedLabel() {
    final engine = _engine;
    if (engine is AdaptivePlaybackEngine) {
      return '${engine.debugSessionIdentity} disposed=${engine.debugDisposed}';
    }
    if (engine is WebPlaybackEngine) {
      return 'web#${engine.debugInstanceId} disposed=${engine.debugDisposed} '
          'generation=${engine.debugSurfaceGeneration}';
    }
    if (engine is MediaKitPlaybackEngine) {
      return 'mediaKit#${engine.debugInstanceId} disposed=${engine.debugDisposed}';
    }
    return 'unknownBackend=${engine.runtimeType}';
  }

  void _logInteractionSnapshot(String label, {PlaybackState? playback}) {
    final state = playback ?? _engine.state.value;
    final isWeb = _usesEmbeddedWebPlayback;
    PlaybackRuntimeDiagnostics.uiLog(
      '$label PlayerScreen#$_instanceId mounted=$mounted drawer=$_drawer '
      'webDrawer=$_webDrawer webOverlayGeneration=$_webOverlayGeneration '
      'controlsVisible=$_controlsVisible sourceSwitchInFlight=$_sourceSwitchInFlight '
      'playback=${state.status.name} focusOwner=${_focusOwnerLabel()} '
      'controllerDisposed=${_controller.debugDisposed} ${_engineDisposedLabel()}',
    );
    PlaybackRuntimeDiagnostics.overlayLog(
      '$label IgnorePointer active=${!_controlsVisible && !isWeb} '
      'AbsorbPointer active=false ModalBarrier present=false '
      'drawerMounted=${_drawer != _PlayerDrawer.none} '
      'webDrawerMounted=${_webDrawer != _WebOverlayDrawer.none} '
      'serverButtonOnPressed=true settingsButtonOnPressed=${!isWeb} '
      'embeddedTopBarRect=$_embeddedTopBarRect '
      'embeddedWebViewInputExclusionRect=$_embeddedSurfaceRect',
    );
    PlaybackRuntimeDiagnostics.webLog(
      '$label WebView owns playback=$isWeb '
      'webViewRecreated=${PlaybackRuntimeDiagnostics.webViewsCreated} created/'
      '${PlaybackRuntimeDiagnostics.webViewsDestroyed} destroyed '
      'reused=${PlaybackRuntimeDiagnostics.webViewReuseCount}',
    );
  }

  void _changeDisplayFit(BoxFit fit) {
    setState(() => _displayFit = fit);
  }

  void _changeVolume(double delta) {
    final next = (_engine.state.value.volume + delta).clamp(0.0, 2.0);
    unawaited(_controller.setVolume(next));
    setState(() => _volumeOverlayValue = next);
    _volumeOverlayTimer?.cancel();
    _volumeOverlayTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _volumeOverlayValue = null);
    });
  }

  bool get _hasNextEpisode {
    if (widget.request.mediaType != PlaybackMediaType.tv &&
        widget.request.mediaType != PlaybackMediaType.anime) {
      return false;
    }
    final episode = widget.request.episode ?? 1;
    final totalEpisodes = widget.request.totalEpisodes;
    if (totalEpisodes == null) return true;
    if (episode < totalEpisodes) return true;
    return (widget.request.season ?? 1) < widget.request.totalSeasons;
  }

  bool get _usesEmbeddedWebPlayback {
    final result =
        _controller.request.streamResult ?? widget.request.streamResult;
    if (result?.isIframe == true) return true;
    final source = _controller.request.source?.toLowerCase() ?? '';
    return source.contains('youtube.com/watch') ||
        source.contains('youtube.com/embed') ||
        source.contains('youtu.be/') ||
        source.contains('vidup.') ||
        source.contains('vidlink.') ||
        source.contains('vidcore.') ||
        source.contains('vidplus.');
  }

  bool _requestUsesEmbeddedWebPlayback(PlaybackRequest request) {
    if (request.streamResult?.isIframe == true) return true;
    final source = request.source?.toLowerCase() ?? '';
    return source.contains('youtube.com/watch') ||
        source.contains('youtube.com/embed') ||
        source.contains('youtu.be/') ||
        source.contains('vidup.') ||
        source.contains('vidlink.') ||
        source.contains('vidcore.') ||
        source.contains('vidplus.');
  }

  PlaybackRequest? _nextEpisodeRequest() {
    if (!_hasNextEpisode) return null;
    final currentRequest = _controller.request;
    final season = currentRequest.season ?? 1;
    final episode = currentRequest.episode ?? 1;
    final totalEpisodes = currentRequest.totalEpisodes;
    final nextSeason = totalEpisodes != null && episode >= totalEpisodes
        ? season + 1
        : season;
    final nextEpisode = totalEpisodes != null && episode >= totalEpisodes
        ? 1
        : episode + 1;
    return currentRequest.copyWith(
      source: '',
      season: nextSeason,
      episode: nextEpisode,
      startPosition: Duration.zero,
      streamResult: null,
      clearSource: true,
      clearStreamResult: true,
    );
  }

  void _startNextEpisode() {
    if (!_ensurePartyCanControl()) return;
    if (_nextEpisodeStarted || _sourceSwitchInFlight) return;
    final next = _nextEpisodeRequest();
    final onNextEpisode = widget.onNextEpisode;
    if (next == null || onNextEpisode == null) return;
    _nextEpisodeStarted = true;
    _sourceSwitchInFlight = true;
    unawaited(_controller.stop());
    onNextEpisode(next);
  }

  Future<void> _switchSource(PlaybackSourceOption option) async {
    PlaybackRuntimeDiagnostics.uiLog(
      'Drawer source option selected index=${option.index} '
      'provider=${option.provider} server=${option.server} '
      'group=${option.group ?? 'none'} iframeOnly=${option.iframeOnly} '
      'owner=PlayerScreen#$_instanceId mounted=$mounted drawer=$_drawer '
      'webGeneration=$_webOverlayGeneration '
      'requestProvider=${widget.request.providerIndex ?? 'auto'} '
      'controllerProvider=${_controller.request.providerIndex ?? 'auto'}',
    );
    _logInteractionSnapshot('before _switchSource');
    if (!_ensurePartyCanControl()) return;
    if (_sourceSwitchInFlight) return;
    final callback = widget.onSourceSwitch ?? widget.onNextEpisode;
    if (callback == null) {
      PlaybackRuntimeDiagnostics.uiLog(
        'Source switch aborted: no callback owner=PlayerScreen#$_instanceId '
        'option=${option.index}',
      );
      return;
    }
    setState(() => _sourceSwitchInFlight = true);
    PlaybackRuntimeDiagnostics.controllerLog(
      'Switch provider started current=${_controller.request.providerIndex ?? 'auto'} '
      'next=${option.index} owner=PlayerScreen#$_instanceId',
    );
    PlaybackRuntimeDiagnostics.lifecycleLog(
      'Provider switch before stop PlayerScreen#$_instanceId '
      '${_engineDisposedLabel()} '
      '${PlaybackRuntimeDiagnostics.lifecycleSummary()}',
    );
    try {
      final nextRequest = _controller.request.copyWith(
        providerIndex: option.index,
        clearSource: true,
        clearStreamResult: true,
        startPosition: _engine.state.value.position,
      );
      PlaybackRuntimeDiagnostics.controllerLog(
        'Switch provider next request prepared owner=PlayerScreen#$_instanceId '
        'next=${option.index} source=${nextRequest.source ?? 'none'} '
        'streamResult=${nextRequest.streamResult?.provider ?? 'none'} '
        'positionMs=${nextRequest.startPosition.inMilliseconds}',
      );
      await _controller.prepareForSourceSwitch(nextRequest);
      await _controller.stop();
      if (!mounted) return;
      PlaybackRuntimeDiagnostics.uiLog(
        'Source switch callback dispatch mounted=$mounted next=${option.index} '
        'callback=${callback == widget.onSourceSwitch ? 'onSourceSwitch' : 'onNextEpisode'} '
        'owner=PlayerScreen#$_instanceId '
        '${PlaybackRuntimeDiagnostics.lifecycleSummary()}',
      );
      callback(nextRequest);
    } finally {
      if (mounted) setState(() => _sourceSwitchInFlight = false);
      _logInteractionSnapshot('after _switchSource finally');
    }
  }

  Future<void> _switchQuality(_QualityOption option) async {
    if (!_ensurePartyCanControl()) return;
    await _controller.switchQuality(option.quality, option.url);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _switchStreamAudio(String audio) async {
    if (!_ensurePartyCanControl()) return;
    if (_sourceSwitchInFlight) return;
    final normalized = audio.trim();
    if (normalized.isEmpty) return;
    final current =
        (_controller.request.preferredAudioTrack ??
                widget.request.streamResult?.selectedAudio ??
                '')
            .trim();
    if (normalized.toLowerCase() == current.toLowerCase()) return;
    final callback = widget.onSourceSwitch ?? widget.onNextEpisode;
    if (callback == null) return;
    setState(() {
      _sourceSwitchInFlight = true;
      _drawer = _PlayerDrawer.none;
    });
    try {
      final nextRequest = _controller.request.copyWith(
        preferredAudioTrack: normalized,
        clearPreferredQuality: true,
        clearSource: true,
        clearStreamResult: true,
        startPosition: _engine.state.value.position,
      );
      await _controller.prepareForSourceSwitch(nextRequest);
      await _controller.stop();
      if (!mounted) return;
      callback(nextRequest);
    } finally {
      if (mounted) setState(() => _sourceSwitchInFlight = false);
    }
  }

  void _playEpisode(int episode) {
    if (!_ensurePartyCanControl()) return;
    if (_sourceSwitchInFlight) return;
    final callback = widget.onSourceSwitch ?? widget.onNextEpisode;
    final currentRequest = _controller.request;
    if (callback == null || episode == currentRequest.episode) return;
    _sourceSwitchInFlight = true;
    unawaited(_controller.stop());
    callback(
      currentRequest.copyWith(
        episode: episode,
        clearSource: true,
        clearStreamResult: true,
        startPosition: Duration.zero,
      ),
    );
  }

  Future<void> _showEpisodeSelector() async {
    final total = widget.request.totalEpisodes;
    if (total == null || total <= 0) return;
    final selected = await showDialog<int>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _EpisodePickerDialog(
        totalEpisodes: total,
        currentEpisode: widget.request.episode ?? 1,
      ),
    );
    if (selected != null) _playEpisode(selected);
  }

  Future<void> _loadCustomSubtitle() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Subtitle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subtitle URL or local path',
            hintText: 'https://example.com/sub.vtt or /path/sub.srt',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    final url = value.startsWith('http') || value.startsWith('file://')
        ? value
        : 'file://$value';
    final label = url.split('/').last;
    unawaited(
      _controller.selectSubtitleTrack('external:Custom:$url', externalUrl: url),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loaded subtitle: $label')));
    }
  }

  void _changeSubtitleDelay(Duration delta) {
    setState(() => _subtitleDelay += delta);
    unawaited(_controller.setSubtitleDelay(_subtitleDelay));
  }

  void _applySubtitleStyle({double? scale, bool? background, bool? outline}) {
    final nextScale = scale ?? _subtitleScale;
    final nextBackground = background ?? _subtitleBackgroundEnabled;
    final nextOutline = outline ?? _subtitleOutlineEnabled;
    setState(() {
      _subtitleScale = nextScale;
      _subtitleBackgroundEnabled = nextBackground;
      _subtitleOutlineEnabled = nextOutline;
    });
    unawaited(
      _controller.setSubtitleStyle(
        SubtitleStyle(
          scale: nextScale,
          background: nextBackground,
          outline: nextOutline,
        ),
      ),
    );
  }

  void _setDebanding(bool enabled) {
    setState(() => _debandingEnabled = enabled);
    unawaited(_controller.setDebanding(enabled));
  }

  Future<void> _showDiagnosticsPanel() async {
    final diagnostics = await _controller.diagnostics();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Playback Diagnostics'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DiagnosticsRow(label: 'Provider', value: _providerLabel),
                _DiagnosticsRow(
                  label: 'Server',
                  value: _serverLabel ?? 'unknown',
                ),
                _DiagnosticsRow(label: 'Stream type', value: _streamTypeLabel),
                for (final row in diagnostics.toRows().entries)
                  _DiagnosticsRow(label: row.key, value: row.value),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _takeScreenshot() async {
    try {
      final path = await _controller.takeScreenshot();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? 'Screenshot unavailable' : 'Screenshot saved: $path',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Screenshot failed: $error')));
    }
  }

  String get _providerLabel =>
      widget.request.streamResult?.provider ??
      widget.request.streamResult?.providerGroup ??
      'Unknown';

  String? get _serverLabel => widget.request.streamResult?.serverName;

  String get _streamTypeLabel {
    final result = widget.request.streamResult;
    if (result?.isIframe == true) return 'iframe';
    if (result?.isM3U8 == true) return 'HLS';
    final source = result?.url ?? widget.request.source ?? '';
    if (source.toLowerCase().contains('.m3u8')) return 'HLS';
    if (source.startsWith('file:') || source.startsWith('/')) return 'local';
    if (source.isEmpty) return 'unknown';
    return 'direct';
  }

  List<_QualityOption> _qualityOptionsFromResult(PlaybackRequest request) {
    final result = request.streamResult;
    final options = <_QualityOption>[
      _QualityOption(
        quality: 'auto',
        url: result?.url ?? request.source ?? '',
        label: 'Auto',
      ),
    ];
    for (final source
        in result?.sources ?? const <stream_models.StreamSource>[]) {
      if (source.url.trim().isEmpty) continue;
      final quality = source.quality.trim().isEmpty ? 'auto' : source.quality;
      if (options.any((option) => option.url == source.url)) continue;
      options.add(
        _QualityOption(quality: quality, url: source.url, label: quality),
      );
    }
    return options;
  }

  Future<void> _discoverHlsQualities() async {
    final result = widget.request.streamResult;
    final source = result?.url ?? widget.request.source;
    if (source == null ||
        source.trim().isEmpty ||
        !(result?.isM3U8 ?? source.toLowerCase().contains('.m3u8'))) {
      if (mounted) setState(() => _qualityDiscoveryComplete = true);
      _applyPreferredQuality();
      return;
    }
    final parsed = await M3u8Parser.parseVideoResolutions(
      source,
      widget.request.httpHeaders,
    );
    if (!mounted) return;
    setState(() {
      for (final item in parsed) {
        if (_qualityOptions.any((option) => option.url == item.url)) continue;
        _qualityOptions.add(
          _QualityOption(
            quality: item.quality,
            url: item.url,
            label: item.quality,
          ),
        );
      }
      _qualityDiscoveryComplete = true;
    });
    _applyPreferredQuality();
  }

  void _applyPreferredQuality() {
    if (_preferredQualityApplied) return;
    final preferred = _controller.request.preferredQuality;
    if (preferred == null || preferred.isEmpty || preferred == 'auto') return;
    for (final option in _qualityOptions) {
      if (option.quality == preferred) {
        _preferredQualityApplied = true;
        unawaited(_controller.switchQuality(option.quality, option.url));
        return;
      }
    }
  }

  Widget _buildVideoControls(VideoState videoState) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.mediaPlay) {
          if (!_ensurePartyCanControl()) return KeyEventResult.handled;
          unawaited(_engine.play());
        } else if (key == LogicalKeyboardKey.mediaPause) {
          if (!_ensurePartyCanControl()) return KeyEventResult.handled;
          unawaited(_engine.pause());
        } else if (key == LogicalKeyboardKey.mediaPlayPause ||
            key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.keyK) {
          if (!_ensurePartyCanControl()) return KeyEventResult.handled;
          unawaited(_controller.togglePlayPause());
        } else if (key == LogicalKeyboardKey.keyJ ||
            key == LogicalKeyboardKey.arrowLeft) {
          if (!_ensurePartyCanControl()) return KeyEventResult.handled;
          unawaited(_controller.seekBy(const Duration(seconds: -10)));
        } else if (key == LogicalKeyboardKey.keyL ||
            key == LogicalKeyboardKey.arrowRight) {
          if (!_ensurePartyCanControl()) return KeyEventResult.handled;
          unawaited(_controller.seekBy(const Duration(seconds: 10)));
        } else if (key == LogicalKeyboardKey.keyM) {
          unawaited(_controller.toggleMute());
        } else if (key == LogicalKeyboardKey.period) {
          unawaited(
            _controller.setPlaybackSpeed(
              (_engine.state.value.playbackSpeed + 0.25).clamp(0.25, 2.0),
            ),
          );
        } else if (key == LogicalKeyboardKey.comma) {
          unawaited(
            _controller.setPlaybackSpeed(
              (_engine.state.value.playbackSpeed - 0.25).clamp(0.25, 2.0),
            ),
          );
        } else if (key == LogicalKeyboardKey.arrowUp) {
          _changeVolume(0.05);
        } else if (key == LogicalKeyboardKey.arrowDown) {
          _changeVolume(-0.05);
        } else if (key == LogicalKeyboardKey.keyF) {
          unawaited(videoState.toggleFullscreen());
        } else if (key == LogicalKeyboardKey.escape) {
          if (videoState.isFullscreen()) {
            unawaited(videoState.exitFullscreen());
          } else {
            _close();
          }
        } else {
          return KeyEventResult.ignored;
        }
        _showControls();
        return KeyEventResult.handled;
      },
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildSurface(BuildContext context) {
    final surfaceBuilder = widget.surfaceBuilder;
    PlaybackRuntimeDiagnostics.uiLog(
      'PlayerScreen#$_instanceId buildSurface request '
      'surfaceBuilder=${surfaceBuilder != null} '
      'usesEmbeddedWeb=$_usesEmbeddedWebPlayback '
      'requestProvider=${widget.request.providerIndex ?? 'auto'} '
      'controllerProvider=${_controller.request.providerIndex ?? 'auto'} '
      '${_engineDisposedLabel()}',
    );
    if (surfaceBuilder != null) return surfaceBuilder(context, _engine);

    final engine = _engine;
    if (engine is PlaybackSurfaceEngine) {
      return engine.buildSurface(
        context: context,
        fit: _displayFit,
        controls: _buildVideoControls,
      );
    }
    if (engine is MediaKitPlaybackEngine) {
      return Video(
        controller: engine.videoController,
        fit: _displayFit,
        fill: Colors.black,
        controls: _buildVideoControls,
      );
    }

    return const ColoredBox(
      key: ValueKey('playback-surface-placeholder'),
      color: Colors.black,
    );
  }

  Widget _buildRightDrawer(PlaybackState playback, {bool inline = false}) {
    PlaybackRuntimeDiagnostics.overlayLog(
      'Drawer widget build drawer=$_drawer inline=$inline mounted=$mounted '
      'playback=${playback.status.name}',
    );
    return _RightPlayerDrawer(
      drawer: _drawer,
      playback: playback,
      qualities: _qualityOptions,
      selectedQuality:
          _controller.request.preferredQuality ??
          widget.request.streamResult?.quality ??
          'auto',
      qualityDiscoveryComplete: _qualityDiscoveryComplete,
      sourceOptions: widget.sourceOptions,
      selectedSourceIndex: _controller.request.providerIndex,
      providerLabel: _providerLabel,
      serverLabel: _serverLabel ?? widget.request.streamResult?.providerGroup,
      streamAudioOptions:
          widget.request.streamResult?.availableAudios ?? const [],
      selectedStreamAudio:
          _controller.request.preferredAudioTrack ??
          widget.request.streamResult?.selectedAudio ??
          '',
      externalSubtitles: widget.request.streamResult?.subtitles ?? const [],
      displayFit: _displayFit,
      debandingEnabled: _debandingEnabled,
      subtitleDelay: _subtitleDelay,
      subtitleScale: _subtitleScale,
      subtitleBackgroundEnabled: _subtitleBackgroundEnabled,
      subtitleOutlineEnabled: _subtitleOutlineEnabled,
      onClose: () => setState(() => _drawer = _PlayerDrawer.none),
      onSourceSelected: (option) {
        PlaybackRuntimeDiagnostics.overlayLog(
          'Drawer source tile tap received index=${option.index} '
          'server=${option.server}',
        );
        setState(() => _drawer = _PlayerDrawer.none);
        unawaited(_switchSource(option));
      },
      onQualitySelected: (option) => unawaited(_switchQuality(option)),
      onStreamAudioSelected: (audio) => unawaited(_switchStreamAudio(audio)),
      onAudioSelected: (trackId) =>
          unawaited(_controller.selectAudioTrack(trackId)),
      onSubtitleSelected: (trackId, externalUrl) => unawaited(
        _controller.selectSubtitleTrack(trackId, externalUrl: externalUrl),
      ),
      onLoadCustomSubtitle: _loadCustomSubtitle,
      onSubtitleDelayChanged: _changeSubtitleDelay,
      onSubtitleScaleChanged: (value) => _applySubtitleStyle(scale: value),
      onSubtitleBackgroundChanged: (value) =>
          _applySubtitleStyle(background: value),
      onSubtitleOutlineChanged: (value) => _applySubtitleStyle(outline: value),
      onDisplayFitChanged: _changeDisplayFit,
      onDebandingChanged: _setDebanding,
      onVolumeChanged: (value) => unawaited(_controller.setVolume(value)),
      onDiagnosticsPressed: () => unawaited(_showDiagnosticsPanel()),
      onScreenshotPressed: () => unawaited(_takeScreenshot()),
      onSpeedSelected: (speed) =>
          unawaited(_controller.setPlaybackSpeed(speed)),
      onRepeatPressed: () => unawaited(_controller.cycleRepeatMode()),
      autoplayNextEpisode: _autoplayNextEpisode,
      onAutoplayChanged: _hasNextEpisode
          ? (value) => setState(() => _autoplayNextEpisode = value)
          : null,
      inline: inline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          PlaybackRuntimeDiagnostics.uiLog(
            'Flutter root pointer down position=${event.position} '
            'buttons=${event.buttons}',
          );
          _logFlutterHitTest('root pointer down', event);
          _logInteractionSnapshot('root pointer down');
        },
        onPointerUp: (event) => PlaybackRuntimeDiagnostics.uiLog(
          'Flutter root pointer up position=${event.position}',
        ),
        child: ValueListenableBuilder<PlaybackState>(
          valueListenable: _engine.state,
          builder: (context, playback, _) {
            final usesEmbeddedWeb = _usesEmbeddedWebPlayback;
            PlaybackRuntimeDiagnostics.uiLog(
              'PlayerScreen#$_instanceId ValueListenable rebuild '
              'mounted=$mounted contextMounted=${context.mounted} '
              'playback=${playback.status.name} usesEmbeddedWeb=$usesEmbeddedWeb '
              'requestProvider=${widget.request.providerIndex ?? 'auto'} '
              'controllerProvider=${_controller.request.providerIndex ?? 'auto'} '
              'streamResultProvider=${widget.request.streamResult?.provider ?? 'none'} '
              'streamResultIframe=${widget.request.streamResult?.isIframe ?? false} '
              'sourceOptions=${widget.sourceOptions.length} '
              'sourceSwitchInFlight=$_sourceSwitchInFlight '
              'buttonShouldExist=${usesEmbeddedWeb && playback.status != PlaybackStatus.loading} '
              '${_engineDisposedLabel()}',
            );
            _maybeRecoverEmbeddedProviderError(playback);
            if (usesEmbeddedWeb) {
              return _buildEmbeddedWebLayout(playback);
            }

            if (playback.status == PlaybackStatus.error) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildSurface(context),
                  _PlayerErrorOverlay(
                    message: playback.errorMessage ?? 'Playback failed.',
                    canSwitchServer: widget.sourceOptions.length > 1,
                    onSwitchServer: _switchToNextSource,
                    onRetry: () => unawaited(_controller.retry()),
                    onClose: _close,
                  ),
                  _AndroidPlayerControls(
                    visible: true,
                    playback: playback,
                    request: widget.request,
                    providerLabel: _providerLabel,
                    serverLabel: _serverLabel,
                    onClose: _close,
                    onPlayPause: () => unawaited(_controller.togglePlayPause()),
                    onSeek: (position) => unawaited(_engine.seek(position)),
                    onSettings: () => _openDrawer(_PlayerDrawer.settings),
                    onServer: () => _openDrawer(_PlayerDrawer.server),
                    onEpisodes: widget.request.totalEpisodes == null
                        ? null
                        : _showEpisodeSelector,
                  ),
                  if (_drawer != _PlayerDrawer.none)
                    _buildRightDrawer(playback),
                ],
              );
            }

            return MouseRegion(
              onHover: (_) => _showControls(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                onDoubleTap: () {
                  if (!_ensurePartyCanControl()) return;
                  unawaited(_controller.seekBy(const Duration(seconds: 10)));
                  _showControls();
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildSurface(context),
                    if (_controlsVisible &&
                        playback.status != PlaybackStatus.error)
                      const ColoredBox(color: Color(0x66000000)),
                    if (playback.status == PlaybackStatus.loading)
                      _PlayerLoadingOverlay(
                        title: widget.request.title,
                        posterPath: widget.request.posterPath,
                        subtitle: _requestSubtitle,
                        message:
                            widget.request.streamResult?.provider ??
                            'Finding a playable source...',
                      ),
                    if (playback.status != PlaybackStatus.error)
                      _AndroidPlayerControls(
                        visible: _controlsVisible,
                        playback: playback,
                        request: widget.request,
                        providerLabel: _providerLabel,
                        serverLabel: _serverLabel,
                        onClose: _close,
                        onPlayPause: () {
                          if (!_ensurePartyCanControl()) return;
                          unawaited(_controller.togglePlayPause());
                          _showControls();
                        },
                        onSeek: (position) {
                          if (!_ensurePartyCanControl()) return;
                          unawaited(_engine.seek(position));
                          _showControls();
                        },
                        onSettings: () => _openDrawer(_PlayerDrawer.settings),
                        onServer: () => _openDrawer(_PlayerDrawer.server),
                        onEpisodes: widget.request.totalEpisodes == null
                            ? null
                            : _showEpisodeSelector,
                      ),
                    if (playback.status == PlaybackStatus.buffering)
                      const _PlayerBufferingOverlay(),
                    _SkipOverlay(
                      playback: playback,
                      skipTimes:
                          widget.request.streamResult?.skipTimes ?? const [],
                      onSkip: (target) {
                        if (!_ensurePartyCanControl()) return;
                        unawaited(_engine.seek(target));
                      },
                    ),
                    if (_hasNextEpisode && playback.duration > Duration.zero)
                      _NextEpisodeOverlay(
                        playback: playback,
                        autoplay: _autoplayNextEpisode,
                        onNext: _startNextEpisode,
                      ),
                    if (_hasWatchPartyContext)
                      _WatchPartyStatusOverlay(
                        session: _watchPartySession,
                        isHost: _watchPartyService?.isHost == true,
                        canControl: _canControlPartyPlayback,
                        connectionLabel: _partyConnectionLabel,
                        controllerLabel: _partyControllerLabel,
                        statusMessage: _watchPartyStatusMessage,
                        messages: _watchPartyMessages,
                        reactions: _watchPartyReactions,
                        onSendMessage: _sendWatchPartyChat,
                        onSendReaction: _sendWatchPartyReaction,
                        onLeaveOrEnd: _leaveOrEndWatchParty,
                      ),
                    if (_volumeOverlayValue != null)
                      _VolumeOverlay(value: _volumeOverlayValue!),
                    if (_drawer != _PlayerDrawer.none)
                      _buildRightDrawer(playback),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmbeddedWebLayout(PlaybackState playback) {
    final shouldInsertServerButton = playback.status != PlaybackStatus.loading;
    final shouldShowServerButton = shouldInsertServerButton;
    final showEmbeddedEscapeBar =
        playback.status != PlaybackStatus.ready &&
        playback.status != PlaybackStatus.completed;
    PlaybackRuntimeDiagnostics.overlayLog(
      'Embedded WebView layout rebuild owner=PlayerScreen#$_instanceId '
      'mounted=$mounted contextMounted=${context.mounted} '
      'playback=${playback.status.name} '
      'requestProvider=${widget.request.providerIndex ?? 'auto'} '
      'controllerProvider=${_controller.request.providerIndex ?? 'auto'} '
      'streamResultProvider=${widget.request.streamResult?.provider ?? 'none'} '
      'sourceOptions=${widget.sourceOptions.length} '
      'insertServerButton=$shouldInsertServerButton '
      'showServerButton=$shouldShowServerButton '
      'overlayGeneration=$_webOverlayGeneration '
      '${_engineDisposedLabel()}',
    );
    final snapshotKey =
        '${playback.status.name}|$_drawer|$_webDrawer|'
        '$_webOverlayGeneration|${widget.request.providerIndex}|'
        '${PlaybackRuntimeDiagnostics.webViewsCreated}|'
        '${PlaybackRuntimeDiagnostics.webViewsDestroyed}';
    if (_lastEmbeddedLayoutSnapshotKey != snapshotKey) {
      _lastEmbeddedLayoutSnapshotKey = snapshotKey;
      _logInteractionSnapshot('embedded layout build', playback: playback);
    }
    return MouseRegion(
      onEnter: (_) => _showControls(),
      onHover: (_) => _showControls(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: (_) => _showControls(),
        onPointerDown: (_) => _showControls(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            PlaybackRuntimeDiagnostics.overlayLog(
              'Embedded WebView stack layout constraints=${constraints.biggest} '
              'serverOverlayVisible=$shouldShowServerButton '
              'owner=PlayerScreen#$_instanceId generation=$_webOverlayGeneration',
            );
            return Column(
              children: [
                if (showEmbeddedEscapeBar)
                  _EmbeddedWebTopBar(
                    playback: playback,
                    title: widget.request.title,
                    providerLabel: _providerLabel,
                    serverLabel:
                        _serverLabel ??
                        widget.request.streamResult?.providerGroup,
                    canSwitchServer: widget.sourceOptions.isNotEmpty,
                    onBack: _close,
                    onServer: _toggleEmbeddedWebServerDrawer,
                    onRetry: playback.status == PlaybackStatus.error
                        ? () => unawaited(_controller.retry())
                        : null,
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _InteractionGeometryProbe(
                              label: 'embedded WebView surface',
                              onGeometryChanged: _recordEmbeddedSurfaceGeometry,
                              child: _buildSurface(context),
                            ),
                            if (playback.status == PlaybackStatus.loading)
                              const _EmbeddedWebStatusBanner(
                                message: 'Loading embedded player...',
                              ),
                            if (playback.status == PlaybackStatus.buffering)
                              const _EmbeddedWebStatusBanner(
                                message: 'Buffering...',
                              ),
                            if (playback.status == PlaybackStatus.error)
                              _PlayerErrorOverlay(
                                message:
                                    playback.errorMessage ??
                                    'Embedded playback failed.',
                                canSwitchServer:
                                    widget.sourceOptions.length > 1,
                                onSwitchServer: _switchToNextSource,
                                onRetry: () => unawaited(_controller.retry()),
                                onClose: _close,
                              ),
                          ],
                        ),
                      ),
                      if (_webDrawer == _WebOverlayDrawer.server)
                        _buildWebServerDrawer(
                          playback,
                          width: 350,
                          onClose: () => setState(() {
                            _webDrawer = _WebOverlayDrawer.none;
                            _webOverlayGeneration++;
                          }),
                          onSourceSelected: (option) {
                            setState(() {
                              _webDrawer = _WebOverlayDrawer.none;
                              _webOverlayGeneration++;
                            });
                            unawaited(_switchSource(option));
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? get _requestSubtitle {
    if (widget.request.mediaType == PlaybackMediaType.movie ||
        widget.request.isLive) {
      return null;
    }
    return 'S${widget.request.season ?? 1} E${widget.request.episode ?? 1}';
  }

  void _switchToNextSource() {
    if (widget.sourceOptions.isEmpty) return;
    final current = _controller.request.providerIndex ?? 0;
    final next = widget.sourceOptions.firstWhere(
      (option) => option.index > current,
      orElse: () => widget.sourceOptions.first,
    );
    unawaited(_switchSource(next));
  }

  void _logFlutterHitTest(String label, PointerEvent event) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    final path = result.path
        .take(12)
        .map((entry) => entry.target.runtimeType.toString())
        .join(' > ');
    PlaybackRuntimeDiagnostics.uiLog(
      '$label hitTest position=${event.position} path=$path',
    );
  }

  void _recordEmbeddedSurfaceGeometry(Rect rect) {
    if (_embeddedSurfaceRect == rect) return;
    _embeddedSurfaceRect = rect;
    PlaybackRuntimeDiagnostics.overlayLog(
      'Embedded WebView native input exclusion rect=$rect',
    );
  }

  PlaybackSourceOption? _nextSourceAfterCurrent() {
    if (widget.sourceOptions.isEmpty) return null;
    final current = _controller.request.providerIndex ?? 0;
    for (final option in widget.sourceOptions) {
      if (option.index > current) return option;
    }
    return null;
  }

  void _maybeRecoverEmbeddedProviderError(PlaybackState playback) {
    if (!_usesEmbeddedWebPlayback) return;
    if (playback.status != PlaybackStatus.error) return;
    if (_sourceSwitchInFlight) return;
    final current = _controller.request.providerIndex ?? 0;
    if (_handledEmbeddedErrorProviderIndex == current) return;
    final next = _nextSourceAfterCurrent();
    if (next == null) return;

    _handledEmbeddedErrorProviderIndex = current;
    PlaybackRuntimeDiagnostics.overlayLog(
      'Embedded provider error fallback scheduled owner=PlayerScreen#$_instanceId '
      'current=$current next=${next.index} playback=${playback.status.name} '
      'mounted=$mounted sourceSwitchInFlight=$_sourceSwitchInFlight '
      'webGeneration=$_webOverlayGeneration',
    );
    _embeddedProviderFallbackTimer?.cancel();
    _embeddedProviderFallbackTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _sourceSwitchInFlight) {
        PlaybackRuntimeDiagnostics.overlayLog(
          'Embedded provider error fallback suppressed owner=PlayerScreen#$_instanceId '
          'current=$current next=${next.index} mounted=$mounted '
          'sourceSwitchInFlight=$_sourceSwitchInFlight '
          'webGeneration=$_webOverlayGeneration',
        );
        return;
      }
      PlaybackRuntimeDiagnostics.overlayLog(
        'Embedded provider error fallback firing owner=PlayerScreen#$_instanceId '
        'current=$current next=${next.index} mounted=$mounted '
        'sourceSwitchInFlight=$_sourceSwitchInFlight '
        'webGeneration=$_webOverlayGeneration',
      );
      unawaited(_switchSource(next));
    });
  }

  Widget _buildWebServerDrawer(
    PlaybackState playback, {
    double width = 360,
    VoidCallback? onClose,
    ValueChanged<PlaybackSourceOption>? onSourceSelected,
  }) {
    final selectedSourceIndex = _controller.request.providerIndex;
    final hasSelectedSource = widget.sourceOptions.any(
      (option) => option.index == selectedSourceIndex,
    );
    final sourceSummary = widget.sourceOptions
        .map((option) => '${option.index}:${option.provider}/${option.server}')
        .join(', ');
    PlaybackRuntimeDiagnostics.overlayLog(
      'WebView-specific server drawer build generation=$_webOverlayGeneration '
      'playback=${playback.status.name} sharedDrawer=$_drawer width=$width '
      'sourceCount=${widget.sourceOptions.length} '
      'selectedSourceIndex=$selectedSourceIndex '
      'selectedSourceValid=$hasSelectedSource '
      'providerLabel=$_providerLabel serverLabel=${_serverLabel ?? widget.request.streamResult?.providerGroup} '
      'sources=[$sourceSummary]',
    );
    return _RenderDiagnosticsProbe(
      label: 'web drawer root generation=$_webOverlayGeneration',
      child: _EmbeddedWebServerDrawer(
        generation: _webOverlayGeneration,
        width: width,
        sourceOptions: widget.sourceOptions,
        selectedSourceIndex: selectedSourceIndex,
        providerLabel: _providerLabel,
        serverLabel: _serverLabel ?? widget.request.streamResult?.providerGroup,
        onClose: onClose ?? () => Navigator.of(context).maybePop(),
        onSourceSelected: (option) {
          PlaybackRuntimeDiagnostics.overlayLog(
            'WebView-specific server tile tap generation=$_webOverlayGeneration '
            'index=${option.index} server=${option.server}',
          );
          if (onSourceSelected != null) {
            onSourceSelected(option);
          } else {
            unawaited(_switchSource(option));
          }
        },
      ),
    );
  }
}

enum _PlayerDrawer { none, settings, server }

enum _WebOverlayDrawer { none, server }

class _InteractionGeometryProbe extends SingleChildRenderObjectWidget {
  const _InteractionGeometryProbe({
    required this.label,
    required this.onGeometryChanged,
    required super.child,
  });

  final String label;
  final ValueChanged<Rect> onGeometryChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _InteractionGeometryRenderBox(
      label: label,
      onGeometryChanged: onGeometryChanged,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _InteractionGeometryRenderBox renderObject,
  ) {
    renderObject
      ..label = label
      ..onGeometryChanged = onGeometryChanged;
  }
}

class _InteractionGeometryRenderBox extends RenderProxyBox {
  _InteractionGeometryRenderBox({
    required this._label,
    required this._onGeometryChanged,
  });

  String _label;
  ValueChanged<Rect> _onGeometryChanged;
  Rect? _lastRect;

  set label(String value) {
    if (_label == value) return;
    _label = value;
    _lastRect = null;
  }

  set onGeometryChanged(ValueChanged<Rect> value) {
    _onGeometryChanged = value;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (!attached) return;
    final transform = getTransformTo(null);
    final topLeft = MatrixUtils.transformPoint(transform, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      transform,
      Offset(size.width, size.height),
    );
    final rect = Rect.fromLTRB(
      math.min(topLeft.dx, bottomRight.dx),
      math.min(topLeft.dy, bottomRight.dy),
      math.max(topLeft.dx, bottomRight.dx),
      math.max(topLeft.dy, bottomRight.dy),
    );
    if (_lastRect == rect) return;
    _lastRect = rect;
    PlaybackRuntimeDiagnostics.overlayLog('$_label geometry rect=$rect');
    _onGeometryChanged(rect);
  }
}

class _RenderDiagnosticsProbe extends SingleChildRenderObjectWidget {
  const _RenderDiagnosticsProbe({required this.label, required super.child});

  final String label;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDiagnosticsRenderBox(label);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderDiagnosticsRenderBox renderObject,
  ) {
    renderObject.label = label;
  }
}

class _RenderDiagnosticsRenderBox extends RenderProxyBox {
  _RenderDiagnosticsRenderBox(this._label);

  String _label;
  String? _lastLayoutSnapshot;
  String? _lastPaintSnapshot;

  set label(String value) {
    if (_label == value) return;
    _label = value;
    _lastLayoutSnapshot = null;
    _lastPaintSnapshot = null;
  }

  @override
  void performLayout() {
    super.performLayout();
    final snapshot = 'constraints=$constraints size=$size';
    if (_lastLayoutSnapshot == snapshot) return;
    _lastLayoutSnapshot = snapshot;
    PlaybackRuntimeDiagnostics.overlayLog('$_label layout $snapshot');
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final snapshot = 'offset=$offset size=$size';
    if (_lastPaintSnapshot == snapshot) return;
    _lastPaintSnapshot = snapshot;
    PlaybackRuntimeDiagnostics.overlayLog('$_label paint $snapshot');
  }
}

class _QualityOption {
  const _QualityOption({
    required this.quality,
    required this.url,
    required this.label,
  });

  final String quality;
  final String url;
  final String label;
}

class _EmbeddedWebServerDrawer extends StatelessWidget {
  const _EmbeddedWebServerDrawer({
    required this.generation,
    required this.width,
    required this.sourceOptions,
    required this.selectedSourceIndex,
    required this.providerLabel,
    required this.onClose,
    required this.onSourceSelected,
    this.serverLabel,
  });

  final int generation;
  final double width;
  final List<PlaybackSourceOption> sourceOptions;
  final int? selectedSourceIndex;
  final String providerLabel;
  final String? serverLabel;
  final VoidCallback onClose;
  final ValueChanged<PlaybackSourceOption> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<PlaybackSourceOption>>{};
    for (final option in sourceOptions) {
      final key = option.group ?? _providerGroup(option.provider);
      grouped.putIfAbsent(key, () => []).add(option);
    }
    final usedFallback = grouped.isEmpty;
    if (grouped.isEmpty) {
      grouped[providerLabel] = [
        PlaybackSourceOption(
          index: selectedSourceIndex ?? 0,
          provider: providerLabel,
          server: serverLabel ?? providerLabel,
        ),
      ];
    }
    final tileCount = grouped.values.fold<int>(
      0,
      (total, options) => total + options.length,
    );
    final selectedVisible = grouped.values.any(
      (options) => options.any((option) => option.index == selectedSourceIndex),
    );
    final groupSummary = grouped.entries
        .map(
          (entry) =>
              '${entry.key}(${entry.value.map((option) => option.index).join('|')})',
        )
        .join(', ');
    PlaybackRuntimeDiagnostics.overlayLog(
      'WebView-specific drawer content build generation=$generation '
      'inputSourceCount=${sourceOptions.length} effectiveGroupCount=${grouped.length} '
      'effectiveTileCount=$tileCount usedFallback=$usedFallback '
      'selectedSourceIndex=$selectedSourceIndex selectedVisible=$selectedVisible '
      'groups=[$groupSummary]',
    );

    final listChildren = <Widget>[];
    for (final entry in grouped.entries) {
      if (entry.value.length > 1) {
        listChildren.add(
          _DrawerGroupTitle(
            entry.key,
            diagnosticLabel:
                'web drawer group generation=$generation title=${entry.key}',
          ),
        );
      }
      for (final option in entry.value) {
        final title = _serverTitle(option);
        final selected = option.index == selectedSourceIndex;
        listChildren.add(
          _DrawerOptionTile(
            title: title,
            selected: selected,
            diagnosticLabel:
                'web drawer tile generation=$generation '
                'index=${option.index} title=$title selected=$selected',
            onTap: () => onSourceSelected(option),
          ),
        );
      }
    }

    final panel = Material(
      color: const Color(0x99101010),
      child: _RenderDiagnosticsProbe(
        label: 'web drawer material child generation=$generation',
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: SafeArea(
            left: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RenderDiagnosticsProbe(
                  label: 'web drawer header generation=$generation',
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        const Icon(Icons.dns, color: Colors.white, size: 26),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Select Server',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: onClose,
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _RenderDiagnosticsProbe(
                    label:
                        'web drawer list generation=$generation tileCount=$tileCount',
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: listChildren,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return KeyedSubtree(
      key: ValueKey('embedded-web-server-drawer-$generation'),
      child: _RenderDiagnosticsProbe(
        label: 'web drawer keyed subtree generation=$generation',
        child: panel,
      ),
    );
  }

  String _providerGroup(String provider) {
    if (provider.startsWith('Animetsu')) return 'Animetsu';
    if (provider.startsWith('Miruro')) return 'Miruro';
    if (provider.startsWith('Animex')) return 'Animex';
    return provider;
  }

  String _serverTitle(PlaybackSourceOption option) {
    var server = option.server;
    for (final prefix in const ['Animetsu (', 'Miruro (', 'Animex (']) {
      if (server.startsWith(prefix) && server.endsWith(')')) {
        server = server.substring(prefix.length, server.length - 1);
      }
    }
    return server.isEmpty ? option.provider : server;
  }
}

class _EmbeddedWebTopBar extends StatelessWidget {
  const _EmbeddedWebTopBar({
    required this.playback,
    required this.title,
    required this.providerLabel,
    required this.canSwitchServer,
    required this.onBack,
    required this.onServer,
    this.serverLabel,
    this.onRetry,
  });

  final PlaybackState playback;
  final String title;
  final String providerLabel;
  final String? serverLabel;
  final bool canSwitchServer;
  final VoidCallback onBack;
  final VoidCallback onServer;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (playback.status) {
      PlaybackStatus.loading => 'Loading',
      PlaybackStatus.buffering => 'Buffering',
      PlaybackStatus.error => 'Unavailable',
      PlaybackStatus.completed => 'Completed',
      PlaybackStatus.stopped => 'Stopped',
      PlaybackStatus.ready => 'Ready',
      PlaybackStatus.idle => 'Opening',
    };
    final server =
        serverLabel == null ||
            serverLabel!.isEmpty ||
            serverLabel == providerLabel
        ? providerLabel
        : '$providerLabel · $serverLabel';
    final canRetry = onRetry != null;

    return Material(
      color: const Color(0xFF050505),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$statusLabel · $server',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canRetry)
                  IconButton(
                    tooltip: 'Retry',
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                if (canSwitchServer)
                  IconButton(
                    tooltip: 'Server',
                    onPressed: onServer,
                    icon: const Icon(Icons.dns, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmbeddedWebStatusBanner extends StatelessWidget {
  const _EmbeddedWebStatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xB3000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AndroidPlayerControls extends StatelessWidget {
  const _AndroidPlayerControls({
    required this.visible,
    required this.playback,
    required this.request,
    required this.providerLabel,
    required this.onClose,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSettings,
    required this.onServer,
    this.serverLabel,
    this.onEpisodes,
  });

  final bool visible;
  final PlaybackState playback;
  final PlaybackRequest request;
  final String providerLabel;
  final String? serverLabel;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSettings;
  final VoidCallback onServer;
  final VoidCallback? onEpisodes;

  @override
  Widget build(BuildContext context) {
    PlaybackRuntimeDiagnostics.uiLog(
      'AndroidPlayerControls build visible=$visible '
      'IgnorePointer active=${!visible} serverButtonOnPressed=true '
      'settingsButtonOnPressed=true',
    );
    return IgnorePointer(
      ignoring: !visible,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => PlaybackRuntimeDiagnostics.uiLog(
          'AndroidPlayerControls pointer down position=${event.position} '
          'visible=$visible',
        ),
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  minimum: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              request.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (request.mediaType !=
                                        PlaybackMediaType.movie &&
                                    !request.isLive)
                                  _TinyPlayerChip(
                                    label:
                                        'S${request.season ?? 1} E${request.episode ?? 1}',
                                    color: AppColors.primary,
                                  ),
                                _TinyPlayerChip(label: providerLabel),
                                if (serverLabel != null &&
                                    serverLabel!.isNotEmpty &&
                                    serverLabel != providerLabel)
                                  _TinyPlayerChip(label: serverLabel!),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (onEpisodes != null)
                        IconButton(
                          tooltip: 'Episodes',
                          onPressed: onEpisodes,
                          icon: const Icon(
                            Icons.list,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Server',
                        onPressed: () {
                          PlaybackRuntimeDiagnostics.uiLog(
                            'Server IconButton onPressed entered route=androidControls',
                          );
                          onServer();
                        },
                        icon: const Icon(
                          Icons.dns,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () {
                          PlaybackRuntimeDiagnostics.uiLog(
                            'Settings IconButton onPressed entered route=androidControls',
                          );
                          onSettings();
                        },
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: IconButton(
                  tooltip: playback.isPlaying ? 'Pause' : 'Play',
                  iconSize: 74,
                  color: Colors.white,
                  onPressed: onPlayPause,
                  icon: Icon(
                    playback.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                ),
              ),
              if (!request.isLive)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: SafeArea(
                    top: false,
                    child: _AndroidProgressBar(
                      playback: playback,
                      onSeek: onSeek,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AndroidProgressBar extends StatefulWidget {
  const _AndroidProgressBar({required this.playback, required this.onSeek});

  final PlaybackState playback;
  final ValueChanged<Duration> onSeek;

  @override
  State<_AndroidProgressBar> createState() => _AndroidProgressBarState();
}

class _AndroidProgressBarState extends State<_AndroidProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final duration = widget.playback.duration;
    final position = widget.playback.position;
    final max = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final value = (_dragValue ?? position.inMilliseconds.toDouble()).clamp(
      0.0,
      max,
    );
    final buffered = widget.playback.bufferedPosition.inMilliseconds
        .toDouble()
        .clamp(0.0, max);

    return Row(
      children: [
        _TimeText(duration: Duration(milliseconds: value.round())),
        const SizedBox(width: 14),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white30,
              secondaryActiveTrackColor: Colors.white70,
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
            ),
            child: Slider(
              value: value,
              secondaryTrackValue: buffered,
              max: max,
              onChanged: (next) => setState(() => _dragValue = next),
              onChangeEnd: (next) {
                setState(() => _dragValue = null);
                widget.onSeek(Duration(milliseconds: next.round()));
              },
            ),
          ),
        ),
        const SizedBox(width: 14),
        _TimeText(duration: duration),
      ],
    );
  }
}

class _RightPlayerDrawer extends StatelessWidget {
  const _RightPlayerDrawer({
    required this.drawer,
    required this.playback,
    required this.qualities,
    required this.selectedQuality,
    required this.qualityDiscoveryComplete,
    required this.sourceOptions,
    required this.selectedSourceIndex,
    required this.providerLabel,
    required this.streamAudioOptions,
    required this.selectedStreamAudio,
    required this.externalSubtitles,
    required this.displayFit,
    required this.debandingEnabled,
    required this.subtitleDelay,
    required this.subtitleScale,
    required this.subtitleBackgroundEnabled,
    required this.subtitleOutlineEnabled,
    required this.onClose,
    required this.onSourceSelected,
    required this.onQualitySelected,
    required this.onStreamAudioSelected,
    required this.onAudioSelected,
    required this.onSubtitleSelected,
    required this.onLoadCustomSubtitle,
    required this.onSubtitleDelayChanged,
    required this.onSubtitleScaleChanged,
    required this.onSubtitleBackgroundChanged,
    required this.onSubtitleOutlineChanged,
    required this.onDisplayFitChanged,
    required this.onDebandingChanged,
    required this.onVolumeChanged,
    required this.onDiagnosticsPressed,
    required this.onScreenshotPressed,
    required this.onSpeedSelected,
    required this.onRepeatPressed,
    required this.autoplayNextEpisode,
    this.inline = false,
    this.serverLabel,
    this.onAutoplayChanged,
  });

  final _PlayerDrawer drawer;
  final PlaybackState playback;
  final List<_QualityOption> qualities;
  final String selectedQuality;
  final bool qualityDiscoveryComplete;
  final List<PlaybackSourceOption> sourceOptions;
  final int? selectedSourceIndex;
  final String providerLabel;
  final String? serverLabel;
  final List<String> streamAudioOptions;
  final String selectedStreamAudio;
  final List<stream_models.SubtitleTrack> externalSubtitles;
  final BoxFit displayFit;
  final bool debandingEnabled;
  final Duration subtitleDelay;
  final double subtitleScale;
  final bool subtitleBackgroundEnabled;
  final bool subtitleOutlineEnabled;
  final VoidCallback onClose;
  final ValueChanged<PlaybackSourceOption> onSourceSelected;
  final ValueChanged<_QualityOption> onQualitySelected;
  final ValueChanged<String> onStreamAudioSelected;
  final ValueChanged<String> onAudioSelected;
  final void Function(String trackId, String? externalUrl) onSubtitleSelected;
  final VoidCallback onLoadCustomSubtitle;
  final ValueChanged<Duration> onSubtitleDelayChanged;
  final ValueChanged<double> onSubtitleScaleChanged;
  final ValueChanged<bool> onSubtitleBackgroundChanged;
  final ValueChanged<bool> onSubtitleOutlineChanged;
  final ValueChanged<BoxFit> onDisplayFitChanged;
  final ValueChanged<bool> onDebandingChanged;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onDiagnosticsPressed;
  final VoidCallback onScreenshotPressed;
  final ValueChanged<double> onSpeedSelected;
  final VoidCallback onRepeatPressed;
  final bool autoplayNextEpisode;
  final bool inline;
  final ValueChanged<bool>? onAutoplayChanged;

  static bool _sameAudioLabel(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (inline) return _buildDrawerPanel(context, animated: false);

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            child: const ColoredBox(color: Color(0x66000000)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildDrawerPanel(context, animated: true),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerPanel(BuildContext context, {required bool animated}) {
    final panel = ClipRRect(
      borderRadius: inline
          ? BorderRadius.zero
          : const BorderRadius.horizontal(left: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: inline ? 0 : 16,
          sigmaY: inline ? 0 : 16,
        ),
        child: Material(
          color: inline ? const Color(0xFF101010) : const Color(0xB3101010),
          child: SizedBox(
            width: 360,
            height: double.infinity,
            child: SafeArea(
              left: false,
              child: drawer == _PlayerDrawer.server
                  ? _buildServerDrawer(context)
                  : _buildSettingsDrawer(context),
            ),
          ),
        ),
      ),
    );
    if (!animated) return panel;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) =>
          Transform.translate(offset: Offset(360 * value, 0), child: child),
      child: panel,
    );
  }

  Widget _buildHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildServerDrawer(BuildContext context) {
    final grouped = <String, List<PlaybackSourceOption>>{};
    for (final option in sourceOptions) {
      final key = option.group ?? _providerGroup(option.provider);
      grouped.putIfAbsent(key, () => []).add(option);
    }
    if (grouped.isEmpty) {
      grouped[providerLabel] = [
        PlaybackSourceOption(
          index: selectedSourceIndex ?? 0,
          provider: providerLabel,
          server: serverLabel ?? providerLabel,
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(Icons.dns, 'Select Server'),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final entry in grouped.entries) ...[
                if (entry.value.length > 1) _DrawerGroupTitle(entry.key),
                for (final option in entry.value)
                  _DrawerOptionTile(
                    title: _serverTitle(option),
                    selected: option.index == selectedSourceIndex,
                    onTap: () => onSourceSelected(option),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsDrawer(BuildContext context) {
    final subtitleItems = <({String id, String label, String? externalUrl})>[
      for (final track in playback.subtitleTracks)
        if (!track.isAuto && !track.isOff)
          (id: track.id, label: track.label, externalUrl: null),
      for (final track in externalSubtitles)
        (
          id: 'external:${track.lang}:${track.url}',
          label: track.lang,
          externalUrl: track.url,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(Icons.settings, 'Settings'),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _DrawerSection(
                icon: Icons.aspect_ratio,
                title: 'DISPLAY FIT',
                initiallyExpanded: false,
                children: [
                  _DrawerOptionTile(
                    title: 'Best Fit',
                    selected: displayFit == BoxFit.contain,
                    onTap: () => onDisplayFitChanged(BoxFit.contain),
                  ),
                  _DrawerOptionTile(
                    title: 'Fit Screen',
                    selected: displayFit == BoxFit.cover,
                    onTap: () => onDisplayFitChanged(BoxFit.cover),
                  ),
                  _DrawerOptionTile(
                    title: 'Fill',
                    selected: displayFit == BoxFit.fill,
                    onTap: () => onDisplayFitChanged(BoxFit.fill),
                  ),
                  _DrawerOptionTile(
                    title: 'None',
                    selected: displayFit == BoxFit.none,
                    onTap: () => onDisplayFitChanged(BoxFit.none),
                  ),
                ],
              ),
              _DrawerSection(
                icon: Icons.high_quality,
                title: qualityDiscoveryComplete
                    ? 'QUALITY'
                    : 'QUALITY · DISCOVERING',
                children: [
                  for (final option in qualities)
                    _DrawerOptionTile(
                      title: option.label,
                      selected: option.quality == selectedQuality,
                      onTap: () => onQualitySelected(option),
                    ),
                ],
              ),
              _DrawerSection(
                icon: Icons.audiotrack,
                title: 'AUDIO',
                children: [
                  if (streamAudioOptions.isNotEmpty)
                    for (final audio in streamAudioOptions)
                      _DrawerOptionTile(
                        title: audio,
                        selected: _sameAudioLabel(audio, selectedStreamAudio),
                        onTap: () => onStreamAudioSelected(audio),
                      )
                  else if (playback.audioTracks.isEmpty)
                    const _DrawerMutedText('No audio tracks found'),
                  if (streamAudioOptions.isEmpty)
                    for (final track in playback.audioTracks)
                      _DrawerOptionTile(
                        title: track.label,
                        selected: track.id == playback.selectedAudioTrackId,
                        onTap: () => onAudioSelected(track.id),
                      ),
                ],
              ),
              _DrawerSection(
                icon: Icons.subtitles,
                title: 'SUBTITLE SETTINGS',
                children: [
                  const _DrawerSubheading('TRACKS'),
                  _DrawerOptionTile(
                    title: 'Off',
                    selected: playback.selectedSubtitleTrackId == 'no',
                    onTap: () => onSubtitleSelected('no', null),
                  ),
                  _DrawerOptionTile(
                    title: 'Load from Local File (.srt, .vtt)',
                    leading: Icons.folder_open,
                    selected: false,
                    onTap: onLoadCustomSubtitle,
                  ),
                  _DrawerOptionTile(
                    title: 'Load from URL (Internet)',
                    leading: Icons.link,
                    selected: false,
                    onTap: onLoadCustomSubtitle,
                  ),
                  if (subtitleItems.isEmpty)
                    const _DrawerMutedText('No subtitle tracks found'),
                  for (final track in subtitleItems)
                    _DrawerOptionTile(
                      title: track.label,
                      selected: track.id == playback.selectedSubtitleTrackId,
                      onTap: () =>
                          onSubtitleSelected(track.id, track.externalUrl),
                    ),
                  const _DrawerSubheading('SIZE'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Slider(
                      min: 0.75,
                      max: 1.5,
                      divisions: 3,
                      value: subtitleScale,
                      activeColor: AppColors.primary,
                      label: '${(subtitleScale * 100).round()}%',
                      onChanged: onSubtitleScaleChanged,
                    ),
                  ),
                  SwitchListTile(
                    value: subtitleBackgroundEnabled,
                    onChanged: onSubtitleBackgroundChanged,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Semi-Transparent Background',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SwitchListTile(
                    value: subtitleOutlineEnabled,
                    onChanged: onSubtitleOutlineChanged,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Outline / Shadow',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const _DrawerSubheading('SYNC'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => onSubtitleDelayChanged(
                            const Duration(milliseconds: -250),
                          ),
                          icon: const Icon(Icons.remove, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            '${subtitleDelay.inMilliseconds > 0 ? '+' : ''}${subtitleDelay.inMilliseconds} ms',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onSubtitleDelayChanged(
                            const Duration(milliseconds: 250),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _DrawerSection(
                icon: Icons.blur_linear_rounded,
                title: 'DEBANDING',
                children: [
                  SwitchListTile(
                    value: debandingEnabled,
                    onChanged: onDebandingChanged,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Enable Debanding',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Reduces color banding artifacts.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _providerGroup(String provider) {
    if (provider.startsWith('Animetsu')) return 'Animetsu';
    if (provider.startsWith('Miruro')) return 'Miruro';
    if (provider.startsWith('Animex')) return 'Animex';
    return provider;
  }

  String _serverTitle(PlaybackSourceOption option) {
    var server = option.server;
    for (final prefix in const ['Animetsu (', 'Miruro (', 'Animex (']) {
      if (server.startsWith(prefix) && server.endsWith(')')) {
        server = server.substring(prefix.length, server.length - 1);
      }
    }
    return server.isEmpty ? option.provider : server;
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.white54,
        leading: Icon(icon, color: Colors.white54),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        children: children,
      ),
    );
  }
}

class _DrawerOptionTile extends StatelessWidget {
  const _DrawerOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
    this.diagnosticLabel,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leading;
  final String? diagnosticLabel;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: leading == null
          ? null
          : Icon(leading, color: Colors.white70, size: 19),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected ? AppColors.primary : Colors.white,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primary, size: 19)
          : null,
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
    final label = diagnosticLabel;
    if (label == null) return tile;
    return _RenderDiagnosticsProbe(label: label, child: tile);
  }
}

class _DrawerGroupTitle extends StatelessWidget {
  const _DrawerGroupTitle(this.title, {this.diagnosticLabel});

  final String title;
  final String? diagnosticLabel;

  @override
  Widget build(BuildContext context) {
    final groupTitle = Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final label = diagnosticLabel;
    if (label == null) return groupTitle;
    return _RenderDiagnosticsProbe(label: label, child: groupTitle);
  }
}

class _DrawerSubheading extends StatelessWidget {
  const _DrawerSubheading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _DrawerMutedText extends StatelessWidget {
  const _DrawerMutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Text(text, style: const TextStyle(color: Colors.white38)),
    );
  }
}

class _TinyPlayerChip extends StatelessWidget {
  const _TinyPlayerChip({required this.label, this.color = Colors.white24});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WatchPartyStatusOverlay extends StatefulWidget {
  const _WatchPartyStatusOverlay({
    required this.session,
    required this.isHost,
    required this.canControl,
    required this.connectionLabel,
    required this.controllerLabel,
    required this.statusMessage,
    required this.messages,
    required this.reactions,
    required this.onSendMessage,
    required this.onSendReaction,
    required this.onLeaveOrEnd,
  });

  final WatchPartySession? session;
  final bool isHost;
  final bool canControl;
  final String connectionLabel;
  final String controllerLabel;
  final String? statusMessage;
  final List<WatchPartyChatMessage> messages;
  final List<WatchPartyReaction> reactions;
  final ValueChanged<String> onSendMessage;
  final ValueChanged<String> onSendReaction;
  final VoidCallback onLeaveOrEnd;

  @override
  State<_WatchPartyStatusOverlay> createState() =>
      _WatchPartyStatusOverlayState();
}

class _WatchPartyStatusOverlayState extends State<_WatchPartyStatusOverlay> {
  final TextEditingController _chatController = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Positioned(
      right: 18,
      top: 86,
      child: SafeArea(
        left: false,
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xCC101010),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              session == null
                                  ? 'Watch Party'
                                  : 'Room ${session.sessionCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          _PartyPill(
                            label: widget.canControl
                                ? (widget.isHost ? 'Host' : 'Controller')
                                : 'Following',
                            color: widget.canControl
                                ? AppColors.primary
                                : Colors.white24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _PartyPill(
                          label: widget.connectionLabel,
                          color: widget.connectionLabel == 'Connected'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        _PartyPill(
                          label: '${session?.participantCount ?? 0} members',
                          color: Colors.white24,
                        ),
                        _PartyPill(
                          label: 'Control: ${widget.controllerLabel}',
                          color: Colors.white24,
                        ),
                      ],
                    ),
                    if (widget.statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.statusMessage!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_expanded) ...[
                      const SizedBox(height: 10),
                      _RecentPartyMessages(messages: widget.messages),
                      if (widget.reactions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final reaction
                                in widget.reactions.reversed.take(5))
                              _PartyPill(
                                label:
                                    '${reaction.emoji} ${reaction.senderName}',
                                color: Colors.white24,
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: widget.onLeaveOrEnd,
                            icon: Icon(
                              widget.isHost
                                  ? Icons.power_settings_new
                                  : Icons.logout_rounded,
                              size: 16,
                            ),
                            label: Text(widget.isHost ? 'End' : 'Leave'),
                          ),
                          const Spacer(),
                          for (final emoji in const ['👍', '😂', '🔥', '😮'])
                            IconButton(
                              tooltip: 'Send $emoji',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => widget.onSendReaction(emoji),
                              icon: Text(
                                emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              minLines: 1,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Message party',
                                hintStyle: TextStyle(color: Colors.white38),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Send message',
                            onPressed: _sendMessage,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _chatController.clear();
  }
}

class _RecentPartyMessages extends StatelessWidget {
  const _RecentPartyMessages({required this.messages});

  final List<WatchPartyChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Text(
        'No party messages yet.',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final message in messages.reversed.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${message.senderName}: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: message.text),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _PartyPill extends StatelessWidget {
  const _PartyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DiagnosticsRow extends StatelessWidget {
  const _DiagnosticsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _PlaybackSettingsOverlay extends StatelessWidget {
  const _PlaybackSettingsOverlay({
    required this.playback,
    required this.qualities,
    required this.sourceOptions,
    required this.selectedSourceIndex,
    required this.providerLabel,
    required this.serverLabel,
    required this.selectedQuality,
    required this.qualityDiscoveryComplete,
    required this.externalSubtitles,
    required this.onQualitySelected,
    required this.onSourceSelected,
    required this.onAudioSelected,
    required this.onSubtitleSelected,
    required this.onSpeedSelected,
    required this.onRepeatPressed,
    required this.onLoadCustomSubtitle,
    required this.subtitleDelay,
    required this.onSubtitleDelayChanged,
    required this.onEpisodesPressed,
    required this.autoplayNextEpisode,
    required this.onAutoplayChanged,
  });

  final PlaybackState playback;
  final List<_QualityOption> qualities;
  final List<PlaybackSourceOption> sourceOptions;
  final int? selectedSourceIndex;
  final String providerLabel;
  final String? serverLabel;
  final String selectedQuality;
  final bool qualityDiscoveryComplete;
  final List<stream_models.SubtitleTrack> externalSubtitles;
  final ValueChanged<_QualityOption> onQualitySelected;
  final ValueChanged<PlaybackSourceOption> onSourceSelected;
  final ValueChanged<String> onAudioSelected;
  final void Function(String trackId, String? externalUrl) onSubtitleSelected;
  final ValueChanged<double> onSpeedSelected;
  final VoidCallback onRepeatPressed;
  final VoidCallback onLoadCustomSubtitle;
  final Duration subtitleDelay;
  final ValueChanged<Duration> onSubtitleDelayChanged;
  final VoidCallback? onEpisodesPressed;
  final bool autoplayNextEpisode;
  final ValueChanged<bool>? onAutoplayChanged;

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final subtitleItems = <DropdownMenuItem<String>>[
      ...playback.subtitleTracks.map(
        (track) =>
            DropdownMenuItem<String>(value: track.id, child: Text(track.label)),
      ),
      ...externalSubtitles.map(
        (track) => DropdownMenuItem<String>(
          value: _externalSubtitleId(track),
          child: Text('${track.lang} · External'),
        ),
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _OverlayStatusChip(
              icon: Icons.dns_outlined,
              label: serverLabel == null || serverLabel == providerLabel
                  ? providerLabel
                  : '$providerLabel · $serverLabel',
            ),
            if (sourceOptions.isNotEmpty)
              _DarkDropdown<PlaybackSourceOption>(
                tooltip: 'Provider / Server',
                value: _selectedSourceOption,
                items: sourceOptions
                    .map(
                      (option) => DropdownMenuItem<PlaybackSourceOption>(
                        value: option,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (option) {
                  if (option != null) onSourceSelected(option);
                },
              ),
            _DarkDropdown<_QualityOption>(
              tooltip: qualityDiscoveryComplete
                  ? 'Quality'
                  : 'Discovering qualities...',
              value: _selectedQualityOption,
              items: qualities
                  .map(
                    (option) => DropdownMenuItem<_QualityOption>(
                      value: option,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: (option) {
                if (option != null) onQualitySelected(option);
              },
            ),
            _DarkDropdown<String>(
              tooltip: 'Audio',
              value: _dropdownValue(
                playback.selectedAudioTrackId,
                playback.audioTracks.map((track) => track.id),
              ),
              items: playback.audioTracks
                  .map(
                    (track) => DropdownMenuItem<String>(
                      value: track.id,
                      child: Text(track.label),
                    ),
                  )
                  .toList(),
              onChanged: (trackId) {
                if (trackId != null) onAudioSelected(trackId);
              },
            ),
            _DarkDropdown<String>(
              tooltip: 'Subtitles',
              value: _dropdownValue(
                playback.selectedSubtitleTrackId,
                subtitleItems.map((item) => item.value).whereType<String>(),
              ),
              items: subtitleItems,
              onChanged: (trackId) {
                if (trackId == null) return;
                final external = _matchingExternalSubtitle(trackId);
                onSubtitleSelected(trackId, external?.url);
              },
            ),
            IconButton(
              tooltip: 'Load subtitle URL or local path',
              onPressed: onLoadCustomSubtitle,
              color: Colors.white,
              icon: const Icon(Icons.subtitles_outlined),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Subtitle delay -250ms',
                  onPressed: () => onSubtitleDelayChanged(
                    const Duration(milliseconds: -250),
                  ),
                  color: Colors.white70,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${subtitleDelay.inMilliseconds}ms',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                IconButton(
                  tooltip: 'Subtitle delay +250ms',
                  onPressed: () =>
                      onSubtitleDelayChanged(const Duration(milliseconds: 250)),
                  color: Colors.white70,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            _DarkDropdown<double>(
              tooltip: 'Playback speed',
              value: _speeds.contains(playback.playbackSpeed)
                  ? playback.playbackSpeed
                  : 1.0,
              items: _speeds
                  .map(
                    (speed) => DropdownMenuItem<double>(
                      value: speed,
                      child: Text('${speed}x'),
                    ),
                  )
                  .toList(),
              onChanged: (speed) {
                if (speed != null) onSpeedSelected(speed);
              },
            ),
            IconButton(
              tooltip: 'Repeat: ${playback.repeatMode.name}',
              onPressed: onRepeatPressed,
              color: Colors.white,
              icon: Icon(_repeatIcon(playback.repeatMode)),
            ),
            if (onEpisodesPressed != null)
              IconButton(
                tooltip: 'Episodes',
                onPressed: onEpisodesPressed,
                color: Colors.white,
                icon: const Icon(Icons.format_list_numbered),
              ),
            if (onAutoplayChanged != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Autoplay',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Switch.adaptive(
                    value: autoplayNextEpisode,
                    onChanged: onAutoplayChanged,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  _QualityOption? get _selectedQualityOption {
    return qualities.firstWhere(
      (option) => option.quality == selectedQuality,
      orElse: () => qualities.first,
    );
  }

  PlaybackSourceOption? get _selectedSourceOption {
    if (sourceOptions.isEmpty) return null;
    for (final option in sourceOptions) {
      if (option.index == selectedSourceIndex) return option;
    }
    return sourceOptions.first;
  }

  static String? _dropdownValue(String selected, Iterable<String> values) {
    if (values.contains(selected)) return selected;
    for (final value in values) {
      return value;
    }
    return null;
  }

  stream_models.SubtitleTrack? _matchingExternalSubtitle(String trackId) {
    for (final track in externalSubtitles) {
      if (_externalSubtitleId(track) == trackId) return track;
    }
    return null;
  }

  static String _externalSubtitleId(stream_models.SubtitleTrack track) {
    return 'external:${track.lang}:${track.url}';
  }

  static IconData _repeatIcon(PlaybackRepeatMode mode) {
    return switch (mode) {
      PlaybackRepeatMode.none => Icons.repeat,
      PlaybackRepeatMode.one => Icons.repeat_one,
      PlaybackRepeatMode.all => Icons.repeat_on,
    };
  }
}

class _DarkDropdown<T> extends StatelessWidget {
  const _DarkDropdown({
    required this.tooltip,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String tooltip;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SizedBox(
        height: 36,
        child: OutlinedButton(onPressed: null, child: Text(tooltip)),
      );
    }
    return Tooltip(
      message: tooltip,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: const Color(0xF21A1A1A),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

class _OverlayStatusChip extends StatelessWidget {
  const _OverlayStatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBufferingOverlay extends StatelessWidget {
  const _PlayerBufferingOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0x99000000),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _SkipOverlay extends StatelessWidget {
  const _SkipOverlay({
    required this.playback,
    required this.skipTimes,
    required this.onSkip,
  });

  final PlaybackState playback;
  final List<SkipTime> skipTimes;
  final ValueChanged<Duration> onSkip;

  @override
  Widget build(BuildContext context) {
    SkipTime? active;
    for (final skip in skipTimes) {
      final type = skip.type.toLowerCase();
      final isSupported =
          type == 'op' ||
          type == 'intro' ||
          type == 'mixed-op' ||
          type == 'ed' ||
          type == 'outro' ||
          type == 'mixed-ed';
      if (isSupported &&
          playback.position >= skip.startTime &&
          playback.position < skip.endTime) {
        active = skip;
        break;
      }
    }
    if (active == null) return const SizedBox.shrink();

    final skip = active;

    final skipType = skip.type.toLowerCase();
    final isOutro =
        skipType == 'ed' || skipType == 'outro' || skipType == 'mixed-ed';
    return Positioned(
      right: AppSpacing.xl,
      bottom: AppSpacing.xl,
      child: FilledButton.icon(
        onPressed: () => onSkip(skip.endTime),
        icon: const Icon(Icons.fast_forward),
        label: Text(isOutro ? 'Skip Outro' : 'Skip Intro'),
      ),
    );
  }
}

class _NextEpisodeOverlay extends StatelessWidget {
  const _NextEpisodeOverlay({
    required this.playback,
    required this.autoplay,
    required this.onNext,
  });

  final PlaybackState playback;
  final bool autoplay;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final remaining = playback.duration - playback.position;
    final showCountdown =
        autoplay &&
        remaining > Duration.zero &&
        remaining <= const Duration(seconds: 30);
    if (!showCountdown && playback.status != PlaybackStatus.completed) {
      return const SizedBox.shrink();
    }
    return Positioned(
      right: 18,
      bottom: 82,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: 280,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UP NEXT',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    showCountdown
                        ? 'Play in ${remaining.inSeconds}s'
                        : 'Play Now',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerLoadingOverlay extends StatelessWidget {
  const _PlayerLoadingOverlay({
    required this.title,
    required this.message,
    this.posterPath,
    this.subtitle,
  });

  final String title;
  final String message;
  final String? posterPath;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final imageUrl = TmdbImageBuilder.backdrop(posterPath, size: 'w780');
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Opacity(
              opacity: 0.16,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerErrorOverlay extends StatelessWidget {
  const _PlayerErrorOverlay({
    required this.message,
    required this.canSwitchServer,
    required this.onSwitchServer,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final bool canSwitchServer;
  final VoidCallback onSwitchServer;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6000000),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.primary,
                  size: 52,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Playback unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (canSwitchServer)
                      ElevatedButton.icon(
                        onPressed: onSwitchServer,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Switch Server'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    OutlinedButton(
                      onPressed: onClose,
                      child: const Text('Back'),
                    ),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodePickerDialog extends StatefulWidget {
  const _EpisodePickerDialog({
    required this.totalEpisodes,
    required this.currentEpisode,
  });

  final int totalEpisodes;
  final int currentEpisode;

  @override
  State<_EpisodePickerDialog> createState() => _EpisodePickerDialogState();
}

class _EpisodePickerDialogState extends State<_EpisodePickerDialog> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final episodes = List<int>.generate(widget.totalEpisodes, (i) => i + 1)
        .where((episode) => _query.isEmpty || '$episode'.contains(_query))
        .toList(growable: false);

    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: const Color(0xFF141414),
          child: SizedBox(
            width: 560,
            height: 560,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Season 1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${widget.totalEpisodes} Episodes',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _controller,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search episodes...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[500],
                                size: 18,
                              ),
                            ),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: episodes.isEmpty
                      ? Center(
                          child: Text(
                            'No episodes match "$_query"',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: episodes.length,
                          itemBuilder: (context, index) {
                            final episode = episodes[index];
                            final current = episode == widget.currentEpisode;
                            final shape = RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: current
                                  ? const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    )
                                  : BorderSide.none,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: current
                                    ? AppColors.primary.withValues(alpha: 0.16)
                                    : const Color(0xFF1E1E1E),
                                shape: shape,
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.black45,
                                    child: Icon(
                                      current
                                          ? Icons.equalizer
                                          : Icons.play_arrow,
                                      color: current
                                          ? AppColors.primary
                                          : Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    'Episode $episode',
                                    style: TextStyle(
                                      color: current
                                          ? AppColors.primary
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  trailing: current
                                      ? const Text(
                                          'NOW',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        )
                                      : null,
                                  selected: current,
                                  selectedTileColor: AppColors.primary
                                      .withValues(alpha: 0.16),
                                  hoverColor: Colors.white.withValues(
                                    alpha: 0.06,
                                  ),
                                  shape: shape,
                                  onTap: () => Navigator.pop(context, episode),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumeOverlay extends StatelessWidget {
  const _VolumeOverlay({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 28,
      top: 0,
      bottom: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 44,
              height: 220,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xB3000000),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white70, size: 18),
                  const SizedBox(height: 10),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: LinearProgressIndicator(
                        value: (value / 2).clamp(0.0, 1.0),
                        color: AppColors.primary,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(value * 100).round()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeText extends StatelessWidget {
  const _TimeText({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:$minutes:$seconds'
        : '$minutes:$seconds';
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }
}
