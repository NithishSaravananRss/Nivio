part of 'player_screen.dart';

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
