import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/index.dart';
import '../models/playback_request.dart';
import '../models/playback_state.dart';
import '../playback_surface.dart';
import '../services/mini_player_service.dart';

class MiniPlayerOverlay extends StatefulWidget {
  const MiniPlayerOverlay({super.key, required this.onExpand});

  final ValueChanged<PlaybackRequest> onExpand;

  @override
  State<MiniPlayerOverlay> createState() => _MiniPlayerOverlayState();
}

class _MiniPlayerOverlayState extends State<MiniPlayerOverlay>
    with SingleTickerProviderStateMixin {
  static const _width = 340.0;
  static const _height = 192.0;
  static const _edgePadding = 18.0;

  late final AnimationController _snapController;
  Animation<Offset>? _snapAnimation;
  ValueListenable<PlaybackState>? _listenedState;
  Offset? _dragStart;
  Offset _position = Offset.zero;
  bool _positionInitialized = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_updateSnapPosition);
    MiniPlayerService.instance.addListener(_serviceChanged);
    _serviceChanged();
  }

  @override
  void dispose() {
    MiniPlayerService.instance.removeListener(_serviceChanged);
    _listenedState?.removeListener(_engineChanged);
    _snapController.dispose();
    super.dispose();
  }

  void _serviceChanged() {
    _listenedState?.removeListener(_engineChanged);
    final session = MiniPlayerService.instance.session;
    if (session != null) {
      _listenedState = session.engine.state;
      _listenedState!.addListener(_engineChanged);
    } else {
      _listenedState = null;
      _positionInitialized = false;
    }
    if (mounted) setState(() {});
  }

  void _engineChanged() {
    if (mounted) setState(() {});
  }

  void _initializePosition(Size size) {
    if (_positionInitialized) return;
    _position = Offset(
      (size.width - _width - _edgePadding).clamp(_edgePadding, size.width),
      (size.height - _height - _edgePadding).clamp(_edgePadding, size.height),
    );
    _positionInitialized = true;
  }

  void _updateSnapPosition() {
    final animation = _snapAnimation;
    if (animation == null || !mounted) return;
    setState(() => _position = animation.value);
  }

  void _onPanStart(DragStartDetails details) {
    _snapController.stop();
    _dragStart = details.globalPosition - _position;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final start = _dragStart;
    if (start == null) return;
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _position = _clampPosition(details.globalPosition - start, size);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final size = MediaQuery.sizeOf(context);
    final leftSide = _position.dx + _width / 2 < size.width / 2;
    final topSide = _position.dy + _height / 2 < size.height / 2;
    final target = _clampPosition(
      Offset(
        leftSide ? _edgePadding : size.width - _width - _edgePadding,
        topSide ? _edgePadding : size.height - _height - _edgePadding,
      ),
      size,
    );
    _snapAnimation = Tween<Offset>(begin: _position, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
  }

  Offset _clampPosition(Offset value, Size size) {
    return Offset(
      value.dx.clamp(_edgePadding, size.width - _width - _edgePadding),
      value.dy.clamp(_edgePadding, size.height - _height - _edgePadding),
    );
  }

  Future<void> _close() async {
    await MiniPlayerService.instance.deactivate();
  }

  void _expand(PlaybackRequest request) {
    widget.onExpand(request);
  }

  Future<void> _togglePlayPause(MiniPlayerSession session) async {
    final state = session.engine.state.value;
    if (state.isPlaying) {
      await session.engine.pause();
    } else {
      await session.engine.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = MiniPlayerService.instance.session;
    if (session == null) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    _initializePosition(size);
    final playback = session.engine.state.value;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () => _expand(session.request),
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _hovered ? 0.65 : 0.42,
                    ),
                    blurRadius: _hovered ? 26 : 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MiniPlayerSurface(session: session),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.58),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: _MiniPlayerChrome(
                      request: session.request,
                      playback: playback,
                      onClose: _close,
                      onPlayPause: () => unawaited(_togglePlayPause(session)),
                    ),
                  ),
                  if (!_hovered)
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: Text(
                        session.request.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _MiniPlayerSurface extends StatelessWidget {
  const _MiniPlayerSurface({required this.session});

  final MiniPlayerSession session;

  @override
  Widget build(BuildContext context) {
    final engine = session.engine;
    if (engine is PlaybackSurfaceEngine) {
      return engine.buildSurface(
        context: context,
        fit: BoxFit.cover,
        controls: (_) => const SizedBox.shrink(),
      );
    }
    return const ColoredBox(color: Colors.black);
  }
}

class _MiniPlayerChrome extends StatelessWidget {
  const _MiniPlayerChrome({
    required this.request,
    required this.playback,
    required this.onClose,
    required this.onPlayPause,
  });

  final PlaybackRequest request;
  final PlaybackState playback;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 8,
          left: 10,
          right: 44,
          child: Text(
            request.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _MiniControlButton(
            tooltip: 'Close mini player',
            icon: Icons.close,
            onPressed: onClose,
          ),
        ),
        Center(
          child: _MiniControlButton(
            tooltip: playback.isPlaying ? 'Pause' : 'Play',
            icon: playback.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 32,
            onPressed: onPlayPause,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LinearProgressIndicator(
            minHeight: 3,
            value: playback.duration > Duration.zero
                ? (playback.position.inMilliseconds /
                          playback.duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                : null,
            backgroundColor: Colors.white24,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _MiniControlButton extends StatelessWidget {
  const _MiniControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = 20,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.56),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: Colors.white, size: size),
          ),
        ),
      ),
    );
  }
}
