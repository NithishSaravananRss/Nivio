part of 'player_screen.dart';

class _PlayerGestureLayer extends StatefulWidget {
  const _PlayerGestureLayer({
    required this.playback,
    required this.onTap,
    required this.onSeekBy,
    required this.onVolumeChanged,
  });

  final PlaybackState playback;
  final VoidCallback onTap;
  final ValueChanged<Duration> onSeekBy;
  final ValueChanged<double> onVolumeChanged;

  @override
  State<_PlayerGestureLayer> createState() => _PlayerGestureLayerState();
}

class _PlayerGestureLayerState extends State<_PlayerGestureLayer> {
  static const _sensitivity = 0.005;

  Timer? _hideTimer;
  double _brightness = 1;
  bool _draggingBrightness = false;
  bool _ignoreDrag = false;
  bool _showBrightness = false;
  bool _showVolume = false;
  bool _showSeek = false;
  bool _seekRight = true;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startVerticalDrag(DragStartDetails details, bool brightnessSide) {
    final height = MediaQuery.sizeOf(context).height;
    final y = details.localPosition.dy;
    _ignoreDrag = y < 56 || y > height - 56;
    if (_ignoreDrag) return;
    _draggingBrightness = brightnessSide;
  }

  void _updateVerticalDrag(DragUpdateDetails details) {
    if (_ignoreDrag) return;
    final value = (_draggingBrightness ? _brightness : widget.playback.volume);
    final adjusted = (value - details.delta.dy * _sensitivity).clamp(
      0.0,
      _draggingBrightness ? 1.0 : 2.0,
    );
    if (_draggingBrightness) {
      setState(() {
        _brightness = adjusted;
        _showBrightness = true;
        _showVolume = false;
      });
    } else {
      widget.onVolumeChanged(adjusted);
      setState(() {
        _showVolume = true;
        _showBrightness = false;
      });
    }
    _scheduleHide();
  }

  void _endVerticalDrag(DragEndDetails details) {
    if (_ignoreDrag) {
      _ignoreDrag = false;
      return;
    }
    _scheduleHide();
  }

  void _doubleTap(bool right) {
    widget.onSeekBy(
      right ? const Duration(seconds: 10) : const Duration(seconds: -10),
    );
    setState(() {
      _seekRight = right;
      _showSeek = true;
    });
    _scheduleHide(milliseconds: 650);
  }

  void _scheduleHide({int milliseconds = 900}) {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(milliseconds: milliseconds), () {
      if (!mounted) return;
      setState(() {
        _showBrightness = false;
        _showVolume = false;
        _showSeek = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: ColoredBox(
            color: Colors.black.withValues(
              alpha: (1.0 - _brightness).clamp(0.0, 0.82),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                onDoubleTap: () => _doubleTap(false),
                onVerticalDragStart: (details) =>
                    _startVerticalDrag(details, true),
                onVerticalDragUpdate: _updateVerticalDrag,
                onVerticalDragEnd: _endVerticalDrag,
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                onDoubleTap: () => _doubleTap(true),
                onVerticalDragStart: (details) =>
                    _startVerticalDrag(details, false),
                onVerticalDragUpdate: _updateVerticalDrag,
                onVerticalDragEnd: _endVerticalDrag,
              ),
            ),
          ],
        ),
        if (_showBrightness)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 28),
              child: _VerticalGestureIndicator(
                icon: Icons.brightness_6_rounded,
                value: _brightness,
                label: '${(_brightness * 100).round()}%',
              ),
            ),
          ),
        if (_showVolume)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 28),
              child: _VerticalGestureIndicator(
                icon: Icons.volume_up_rounded,
                value: widget.playback.volume > 1
                    ? widget.playback.volume - 1
                    : widget.playback.volume,
                label: '${(widget.playback.volume * 100).round()}%',
                boosted: widget.playback.volume > 1,
              ),
            ),
          ),
        if (_showSeek)
          Align(
            alignment: _seekRight
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.38,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _seekRight
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    end: _seekRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.11),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _seekRight
                            ? Icons.fast_forward_rounded
                            : Icons.fast_rewind_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _seekRight ? '+10s' : '-10s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VerticalGestureIndicator extends StatelessWidget {
  const _VerticalGestureIndicator({
    required this.icon,
    required this.value,
    required this.label,
    this.boosted = false,
  });

  final IconData icon;
  final double value;
  final String label;
  final bool boosted;

  @override
  Widget build(BuildContext context) {
    final color = boosted ? Colors.orangeAccent : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: SizedBox(
        width: 48,
        height: 178,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RotatedBox(
                  quarterTurns: -1,
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    color: color,
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
