import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/stream_result.dart';
import '../../../shared/theme/index.dart';
import '../../player/models/playback_request.dart';
import '../../player/services/desktop_streaming_service.dart';
import '../../player/services/m3u8_parser.dart';
import '../../player/services/stream_resolver.dart';

class DesktopDownloadSelection {
  const DesktopDownloadSelection({
    required this.result,
    required this.streamUrl,
    required this.quality,
    this.source,
    this.server,
    this.audioLanguage,
    this.subtitleLanguage,
    this.subtitleUrl,
  });

  final StreamResult result;
  final String streamUrl;
  final String quality;
  final StreamSource? source;
  final PlaybackSourceOption? server;
  final String? audioLanguage;
  final String? subtitleLanguage;
  final String? subtitleUrl;
}

class DesktopDownloadPrompt {
  const DesktopDownloadPrompt._();

  static Future<DesktopDownloadSelection?> show({
    required BuildContext context,
    required PlaybackRequest request,
    required StreamResult initialResult,
    required DesktopStreamingService streamingService,
    required List<PlaybackSourceOption> servers,
    String title = 'Download Settings',
  }) {
    return showDialog<DesktopDownloadSelection>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DesktopDownloadDialog(
        title: title,
        request: request,
        initialResult: initialResult,
        streamingService: streamingService,
        servers: servers,
      ),
    );
  }
}

class _DesktopDownloadDialog extends StatefulWidget {
  const _DesktopDownloadDialog({
    required this.title,
    required this.request,
    required this.initialResult,
    required this.streamingService,
    required this.servers,
  });

  final String title;
  final PlaybackRequest request;
  final StreamResult initialResult;
  final DesktopStreamingService streamingService;
  final List<PlaybackSourceOption> servers;

  @override
  State<_DesktopDownloadDialog> createState() => _DesktopDownloadDialogState();
}

class _DesktopDownloadDialogState extends State<_DesktopDownloadDialog> {
  StreamResult? _result;
  PlaybackSourceOption? _server;
  List<M3u8VideoResolution> _resolutions = const [];
  List<M3u8Track> _audioTracks = const [];
  List<M3u8Track> _subtitleTracks = const [];
  M3u8VideoResolution? _selectedResolution;
  StreamSource? _selectedSource;
  String? _selectedAudio;
  String? _selectedSubtitle;
  String _preferredQuality = 'auto';
  String _preferredAudio = 'Original';
  String _preferredSubtitle = 'Auto';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _server = _selectedServerFor(widget.initialResult);
    _result = widget.initialResult;
    _loadPreferencesAndDetails(widget.initialResult);
  }

  Future<void> _loadPreferencesAndDetails(StreamResult result) async {
    final prefs = await SharedPreferences.getInstance();
    _preferredQuality = prefs.getString('download_quality') ?? 'auto';
    _preferredAudio =
        prefs.getString('preferred_download_audio_language') ?? 'Original';
    _preferredSubtitle =
        prefs.getString('preferred_download_subtitle_language') ?? 'Auto';
    await _loadDetails(result);
  }

  Future<void> _loadDetails(StreamResult result) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final url = result.sources.firstOrNull?.url ?? result.url;
    final headers = result.headers;
    var resolutions = <M3u8VideoResolution>[];
    var audioTracks = <M3u8Track>[];
    var subtitleTracks = <M3u8Track>[];
    final isHls = result.isM3U8 || url.toLowerCase().contains('.m3u8');

    if (isHls) {
      resolutions = await M3u8Parser.parseVideoResolutions(url, headers);
      final tracks = await M3u8Parser.parseTracks(url, headers);
      audioTracks = tracks['audio'] ?? const [];
      subtitleTracks = tracks['subtitle'] ?? const [];
    }

    for (final audio in result.availableAudios) {
      if (!audioTracks.any((track) => track.language == audio)) {
        audioTracks.add(M3u8Track(language: audio, name: audio));
      }
    }
    for (final subtitle in result.subtitles) {
      if (!subtitleTracks.any((track) => track.language == subtitle.lang)) {
        subtitleTracks.add(
          M3u8Track(language: subtitle.lang, name: subtitle.lang),
        );
      }
    }

    resolutions.sort(
      (a, b) => _qualityScore(b.quality).compareTo(_qualityScore(a.quality)),
    );
    final sources = [...result.sources]
      ..sort(
        (a, b) => _qualityScore(b.quality).compareTo(_qualityScore(a.quality)),
      );

    if (!mounted) return;
    setState(() {
      _result = result;
      _resolutions = resolutions;
      _audioTracks = audioTracks;
      _subtitleTracks = subtitleTracks;
      _selectedResolution = _pickResolution(resolutions);
      _selectedSource = _pickSource(sources);
      _selectedAudio = _pickAudio(result, audioTracks);
      _selectedSubtitle = _pickSubtitle(subtitleTracks);
      _loading = false;
    });
  }

  PlaybackSourceOption? _selectedServerFor(StreamResult result) {
    if (widget.servers.isEmpty) return null;
    final providerIndex = result.providerIndex;
    if (providerIndex != null) {
      for (final server in widget.servers) {
        if (server.index == providerIndex) return server;
      }
    }
    return widget.servers.first;
  }

  Future<void> _changeServer(PlaybackSourceOption server) async {
    setState(() {
      _server = server;
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.streamingService.resolveDownloadable(
        widget.request.copyWith(providerIndex: server.index),
      );
      await _loadDetails(result);
    } on StreamResolutionException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Server failed to load.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      title: Row(
        children: [
          Expanded(child: Text(widget.title, style: AppTypography.title)),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose server, quality, audio, and subtitles before queueing.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.servers.length > 1)
              _FieldShell(
                label: 'Server',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PlaybackSourceOption>(
                    value: _server,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    items: [
                      for (final server in widget.servers)
                        DropdownMenuItem(
                          value: server,
                          child: Text(server.label),
                        ),
                    ],
                    onChanged: _loading || _server == null
                        ? null
                        : (server) {
                            if (server != null && server != _server) {
                              _changeServer(server);
                            }
                          },
                  ),
                ),
              ),
            if (widget.servers.length > 1)
              const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              Text(
                _error!,
                style: AppTypography.body.copyWith(color: AppColors.danger),
              )
            else if (result != null) ...[
              if (_resolutions.isNotEmpty)
                _FieldShell(
                  label: 'Quality',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<M3u8VideoResolution>(
                      value: _selectedResolution,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: [
                        for (final resolution in _resolutions)
                          DropdownMenuItem(
                            value: resolution,
                            child: Text(resolution.quality),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedResolution = value),
                    ),
                  ),
                )
              else if (result.sources.isNotEmpty)
                _FieldShell(
                  label: 'Quality',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StreamSource>(
                      value: _selectedSource,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: [
                        for (final source in result.sources)
                          DropdownMenuItem(
                            value: source,
                            child: Text(
                              '${source.quality}${source.isDub ? ' (Dub)' : ''}',
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedSource = value),
                    ),
                  ),
                )
              else
                const _ReadOnlyValue(label: 'Quality', value: 'Auto'),
              const SizedBox(height: AppSpacing.md),
              if (_audioTracks.isNotEmpty) ...[
                _FieldShell(
                  label: 'Audio',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAudio,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: [
                        for (final track in _audioTracks)
                          DropdownMenuItem(
                            value: track.language,
                            child: Text(track.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedAudio = value),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_subtitleTracks.isNotEmpty) ...[
                _FieldShell(
                  label: 'Subtitles',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedSubtitle,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Off')),
                        for (final track in _subtitleTracks)
                          DropdownMenuItem(
                            value: track.language,
                            child: Text(track.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedSubtitle = value),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _loading || _error != null || result == null
              ? null
              : () => Navigator.pop(context, _selection(result)),
          icon: const Icon(Icons.download),
          label: const Text('Start Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  DesktopDownloadSelection _selection(StreamResult result) {
    final resolution = _selectedResolution;
    final source = resolution == null
        ? _selectedSource
        : StreamSource(
            url: resolution.url,
            quality: resolution.quality,
            isM3U8: true,
          );
    final streamUrl = source?.url ?? result.url;
    final quality = source?.quality ?? result.quality;
    return DesktopDownloadSelection(
      result: result,
      streamUrl: streamUrl,
      quality: quality,
      source: source,
      server: _server,
      audioLanguage: _selectedAudio,
      subtitleLanguage: _selectedSubtitle,
      subtitleUrl: _subtitleUrlFor(result, _selectedSubtitle),
    );
  }

  M3u8VideoResolution? _pickResolution(List<M3u8VideoResolution> items) {
    if (items.isEmpty) return null;
    if (_preferredQuality.toLowerCase() != 'auto') {
      for (final item in items) {
        if (item.quality.toLowerCase() == _preferredQuality.toLowerCase()) {
          return item;
        }
      }
    }
    return items.first;
  }

  StreamSource? _pickSource(List<StreamSource> items) {
    if (items.isEmpty) return null;
    if (_preferredQuality.toLowerCase() != 'auto') {
      for (final item in items) {
        if (item.quality.toLowerCase() == _preferredQuality.toLowerCase()) {
          return item;
        }
      }
    }
    return items.first;
  }

  String? _pickAudio(StreamResult result, List<M3u8Track> tracks) {
    if (tracks.isEmpty) return null;
    final current = result.selectedAudio.trim();
    if (current.isNotEmpty &&
        tracks.any((track) => track.language == current)) {
      return current;
    }
    final preferred = _preferredAudio.toLowerCase();
    if (preferred == 'original' || preferred == 'auto') {
      return tracks.first.language;
    }
    for (final track in tracks) {
      final haystack = '${track.language} ${track.name}'.toLowerCase();
      if (haystack.contains(preferred)) return track.language;
    }
    return tracks.first.language;
  }

  String? _pickSubtitle(List<M3u8Track> tracks) {
    if (tracks.isEmpty || _preferredSubtitle.toLowerCase() == 'off') {
      return null;
    }
    final preferred = _preferredSubtitle.toLowerCase();
    if (preferred == 'auto') return tracks.first.language;
    for (final track in tracks) {
      final haystack = '${track.language} ${track.name}'.toLowerCase();
      if (haystack.contains(preferred)) return track.language;
    }
    return tracks.first.language;
  }

  String? _subtitleUrlFor(StreamResult result, String? selectedSubtitle) {
    if (selectedSubtitle == null || selectedSubtitle.toLowerCase() == 'off') {
      return null;
    }
    for (final subtitle in result.subtitles) {
      final haystack = '${subtitle.lang} ${subtitle.url}'.toLowerCase();
      if (haystack.contains(selectedSubtitle.toLowerCase())) {
        return subtitle.url;
      }
    }
    return result.subtitles.firstOrNull?.url;
  }

  int _qualityScore(String quality) {
    final q = quality.toLowerCase().trim();
    if (q == 'auto') return -1;
    final match = RegExp(r'(\d{3,4})p').firstMatch(q);
    return match == null ? 0 : int.tryParse(match.group(1) ?? '') ?? 0;
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      child: SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppTypography.body),
        ),
      ),
    );
  }
}
