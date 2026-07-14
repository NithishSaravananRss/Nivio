import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_environment.dart';
import '../../shared/theme/index.dart';
import '../../shared/widgets/feedback/error_view.dart';
import '../../shared/widgets/feedback/loading_view.dart';
import '../library/services/library_persistence.dart';
import '../live_tv/services/iptv_service.dart';
import '../party/services/watch_party_identity.dart';
import '../party/services/watch_party_supabase_config.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, this.onBack, this.embedded = false});

  final VoidCallback? onBack;
  final bool embedded;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _controller = SettingsController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    if (state.isLoading) {
      return const LoadingView(
        title: 'Loading Settings',
        message: 'Reading local preferences and environment status.',
      );
    }
    if (state.fatalError != null) {
      return ErrorView(
        title: 'Settings unavailable',
        message: state.fatalError!,
        onRetry: _controller.load,
      );
    }

    final content = ListView(
      primary: widget.embedded ? false : null,
      shrinkWrap: widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        widget.embedded ? 0 : AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      children: [
        Row(
          children: [
            if (widget.onBack != null) ...[
              IconButton.filledTonal(
                tooltip: 'Back to Profile',
                onPressed: widget.onBack,
                icon: const Icon(LucideIcons.arrowLeft),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: AppTypography.display),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Playback, download, app, and account preferences.',
                    style: AppTypography.body,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _Section(
          title: 'Playback',
          icon: LucideIcons.play,
          error: state.sectionErrors['playback'],
          child: Column(
            children: [
              _ChoiceTile(
                title: 'Default Playback Speed',
                value: state.settings.playbackSpeed.toString(),
                options: SettingsDefaults.playbackSpeeds
                    .map((speed) => speed.toString())
                    .toList(),
                onChanged: (value) => _controller.updateDouble(
                  SettingsKeys.playbackSpeed,
                  double.parse(value),
                ),
              ),
              _ChoiceTile(
                title: 'Preferred Video Quality',
                value: state.settings.videoQuality,
                options: SettingsDefaults.videoQualities,
                onChanged: (value) =>
                    _controller.updateString(SettingsKeys.videoQuality, value),
              ),
              _ChoiceTile(
                title: 'Preferred Audio Language',
                value: state.settings.preferredAudioLanguage,
                options: SettingsDefaults.audioLanguages,
                onChanged: (value) => _controller.updateString(
                  SettingsKeys.preferredAudioLanguage,
                  value,
                ),
              ),
              _ChoiceTile(
                title: 'Preferred Subtitle Language',
                value: state.settings.preferredSubtitleLanguage,
                options: SettingsDefaults.subtitleLanguages,
                onChanged: (value) => _controller.updateString(
                  SettingsKeys.preferredSubtitleLanguage,
                  value,
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Downloads',
          icon: LucideIcons.download,
          error: state.sectionErrors['downloads'],
          child: Column(
            children: [
              _ChoiceTile(
                title: 'Preferred Download Audio',
                value: state.settings.preferredDownloadAudioLanguage,
                options: SettingsDefaults.audioLanguages,
                onChanged: (value) => _controller.updateString(
                  SettingsKeys.preferredDownloadAudioLanguage,
                  value,
                ),
              ),
              _ChoiceTile(
                title: 'Preferred Download Subtitle',
                value: state.settings.preferredDownloadSubtitleLanguage,
                options: SettingsDefaults.subtitleLanguages,
                onChanged: (value) => _controller.updateString(
                  SettingsKeys.preferredDownloadSubtitleLanguage,
                  value,
                ),
              ),
              _ChoiceTile(
                title: 'Parallel Download Connections',
                value: state.settings.downloadConcurrency.toString(),
                options: const ['1', '2', '3', '4', '5', '6', '8'],
                onChanged: (value) => _controller.updateInt(
                  SettingsKeys.downloadConcurrency,
                  int.parse(value),
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: 'App & Updates',
          icon: LucideIcons.info,
          error: state.sectionErrors['appearance'],
          child: Column(
            children: [
              _ChoiceTile(
                title: 'Theme Color',
                value: state.settings.accentColor,
                options: SettingsDefaults.accentColors,
                onChanged: (value) =>
                    _controller.updateString(SettingsKeys.accentColor, value),
              ),
              _InfoTile(title: 'App Version', value: state.appVersion),
            ],
          ),
        ),
        _Section(
          title: 'Data & Account',
          icon: LucideIcons.database,
          error: state.sectionErrors['storage'],
          child: Column(
            children: [
              _DestructiveTile(
                title: 'Clear Watch History',
                onConfirm: _controller.clearWatchHistory,
              ),
              _DestructiveTile(
                title: 'Clear Cache',
                onConfirm: _controller.clearImageCache,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );

    if (widget.embedded) return content;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.background],
        ),
      ),
      child: content,
    );
  }
}

class SettingsController extends ChangeNotifier {
  SettingsState state = SettingsState.loading();

  Future<void> load() async {
    state = SettingsState.loading();
    notifyListeners();

    final errors = <String, String>{};
    var settings = DesktopSettings.defaults();
    var playlistCount = 0;
    var downloadBytes = 0;
    var partyUserName = 'Guest';
    var appVersion = '1.0.0';
    var buildNumber = '1';
    var serviceStatus = const ServiceStatus(
      tmdb: 'Checking',
      anilist: 'Checking',
      iptv: 'Checking',
      supabase: 'Checking',
      realtime: 'Checking',
    );

    try {
      settings = await DesktopSettings.load();
    } catch (error) {
      errors['preferences'] = 'Could not load preferences: $error';
    }

    try {
      await LibraryPersistence.init();
      downloadBytes = await _downloadStorageBytes();
    } catch (error) {
      errors['downloads'] = 'Could not read download metadata: $error';
    }

    try {
      final playlists = await DesktopIptvService().getPlaylists();
      playlistCount = playlists.length;
    } catch (error) {
      errors['liveTv'] = 'Could not read IPTV playlists: $error';
    }

    try {
      final identity = await WatchPartyIdentityStore().load();
      partyUserName = identity.userName;
    } catch (error) {
      errors['party'] = 'Could not read party identity: $error';
    }

    try {
      final versionInfo = await _readVersionInfo();
      appVersion = versionInfo.$1;
      buildNumber = versionInfo.$2;
    } catch (error) {
      errors['environment'] = 'Could not read app version: $error';
    }

    state = SettingsState.loaded(
      settings: settings,
      sectionErrors: errors,
      iptvPlaylistCount: playlistCount,
      downloadBytes: downloadBytes,
      partyUserName: partyUserName,
      appVersion: appVersion,
      buildNumber: buildNumber,
      serviceStatus: serviceStatus,
    );
    notifyListeners();

    unawaited(_refreshServiceStatus());
  }

  Future<void> updateString(String key, String value) async {
    await _save(key, value);
  }

  Future<void> updateBool(String key, bool value) async {
    await _save(key, value);
  }

  Future<void> updateInt(String key, int value) async {
    await _save(key, value);
  }

  Future<void> updateDouble(String key, double value) async {
    await _save(key, value);
  }

  Future<void> _save(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (value) {
      case String():
        await prefs.setString(key, value);
      case bool():
        await prefs.setBool(key, value);
      case int():
        await prefs.setInt(key, value);
      case double():
        await prefs.setDouble(key, value);
    }
    await load();
  }

  Future<void> refreshIptvStatus() => _refreshServiceStatus();

  Future<void> _refreshServiceStatus() async {
    final current = state;
    if (current.isLoading || current.fatalError != null) return;

    final previous = current.serviceStatus;
    final tmdb = _checkGet('${AppEnvironment.imageProxyUrl}/3/configuration');
    final anilist = _checkPost(AppEnvironment.anilistApiUrl);
    final iptv = _checkGet(current.settings.iptvPlaylistUrl);
    final supabase = Future.value(
      WatchPartySupabaseConfig.isConfigured
          ? WatchPartySupabaseConfig.isAvailable
                ? 'Online'
                : 'Configured'
          : 'Not configured',
    );

    final results = await Future.wait([tmdb, anilist, iptv, supabase]);
    state = current.copyWith(
      serviceStatus: ServiceStatus(
        tmdb: results[0],
        anilist: results[1],
        iptv: results[2],
        supabase: results[3],
        realtime: WatchPartySupabaseConfig.isAvailable
            ? 'Available'
            : previous.realtime == 'Checking'
            ? 'Offline'
            : previous.realtime,
      ),
    );
    notifyListeners();
  }

  Future<String> clearImageCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    return 'Image cache cleared';
  }

  Future<String> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    await prefs.remove('recent_searches');
    return 'Search history cleared';
  }

  Future<String> clearWatchHistory() async {
    final box = await Hive.openBox<String>('watch_history');
    await box.clear();
    return 'Watch history cleared';
  }

  Future<String> clearPlaybackCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_playback_position');
    await prefs.remove('last_playback_media');
    final box = await Hive.openBox<String>('watch_history');
    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw == null) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      decoded
        ..remove('preferredAudioTrack')
        ..remove('preferredSubtitleTrack')
        ..remove('preferredResolution')
        ..remove('preferredProviderIndex');
      await box.put(key, jsonEncode(decoded));
    }
    return 'Playback cache cleared';
  }

  Future<String> clearDownloadsMetadata() async {
    await LibraryPersistence.init();
    await LibraryPersistence.downloadsBox.clear();
    await load();
    return 'Downloads metadata cleared';
  }
}

class SettingsState {
  const SettingsState._({
    required this.isLoading,
    required this.settings,
    required this.sectionErrors,
    required this.iptvPlaylistCount,
    required this.downloadBytes,
    required this.partyUserName,
    required this.appVersion,
    required this.buildNumber,
    required this.serviceStatus,
    this.fatalError,
  });

  factory SettingsState.loading() => SettingsState._(
    isLoading: true,
    settings: DesktopSettings.defaults(),
    sectionErrors: const {},
    iptvPlaylistCount: 0,
    downloadBytes: 0,
    partyUserName: 'Guest',
    appVersion: '1.0.0',
    buildNumber: '1',
    serviceStatus: const ServiceStatus(
      tmdb: 'Checking',
      anilist: 'Checking',
      iptv: 'Checking',
      supabase: 'Checking',
      realtime: 'Checking',
    ),
  );

  factory SettingsState.loaded({
    required DesktopSettings settings,
    required Map<String, String> sectionErrors,
    required int iptvPlaylistCount,
    required int downloadBytes,
    required String partyUserName,
    required String appVersion,
    required String buildNumber,
    required ServiceStatus serviceStatus,
  }) => SettingsState._(
    isLoading: false,
    settings: settings,
    sectionErrors: sectionErrors,
    iptvPlaylistCount: iptvPlaylistCount,
    downloadBytes: downloadBytes,
    partyUserName: partyUserName,
    appVersion: appVersion,
    buildNumber: buildNumber,
    serviceStatus: serviceStatus,
  );

  final bool isLoading;
  final DesktopSettings settings;
  final Map<String, String> sectionErrors;
  final int iptvPlaylistCount;
  final int downloadBytes;
  final String partyUserName;
  final String appVersion;
  final String buildNumber;
  final ServiceStatus serviceStatus;
  final String? fatalError;

  String get downloadStorageLabel => _formatBytes(downloadBytes);
  String get flutterVersion => Platform.version.split(' ').first;
  String get platformLabel => '${Platform.operatingSystem} ${Platform.version}';

  SettingsState copyWith({ServiceStatus? serviceStatus}) => SettingsState._(
    isLoading: isLoading,
    settings: settings,
    sectionErrors: sectionErrors,
    iptvPlaylistCount: iptvPlaylistCount,
    downloadBytes: downloadBytes,
    partyUserName: partyUserName,
    appVersion: appVersion,
    buildNumber: buildNumber,
    serviceStatus: serviceStatus ?? this.serviceStatus,
    fatalError: fatalError,
  );
}

class DesktopSettings {
  const DesktopSettings({
    required this.accentColor,
    required this.videoQuality,
    required this.playbackSpeed,
    required this.preferredAudioLanguage,
    required this.preferredSubtitleLanguage,
    required this.preferredDownloadAudioLanguage,
    required this.preferredDownloadSubtitleLanguage,
    required this.autoplay,
    required this.resumePlayback,
    required this.downloadLocation,
    required this.downloadQuality,
    required this.downloadConcurrency,
    required this.wifiOnlyDownloads,
    required this.imageQuality,
    required this.imageProxyUrl,
    required this.iptvPlaylistUrl,
    required this.iptvCacheHours,
  });

  factory DesktopSettings.defaults() => DesktopSettings(
    accentColor: 'red',
    videoQuality: 'auto',
    playbackSpeed: 1,
    preferredAudioLanguage: 'Original',
    preferredSubtitleLanguage: 'Auto',
    preferredDownloadAudioLanguage: 'Original',
    preferredDownloadSubtitleLanguage: 'Auto',
    autoplay: true,
    resumePlayback: true,
    downloadLocation: '',
    downloadQuality: 'auto',
    downloadConcurrency: 6,
    wifiOnlyDownloads: false,
    imageQuality: 'w500',
    imageProxyUrl: AppEnvironment.imageProxyUrl,
    iptvPlaylistUrl: AppEnvironment.iptvPlaylistUrl,
    iptvCacheHours: 24,
  );

  static Future<DesktopSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = DesktopSettings.defaults();
    final fallbackDownloadDir = await _defaultDownloadDirectory();
    return DesktopSettings(
      accentColor:
          prefs.getString(SettingsKeys.accentColor) ?? defaults.accentColor,
      videoQuality:
          prefs.getString(SettingsKeys.videoQuality) ?? defaults.videoQuality,
      playbackSpeed:
          prefs.getDouble(SettingsKeys.playbackSpeed) ?? defaults.playbackSpeed,
      preferredAudioLanguage:
          prefs.getString(SettingsKeys.preferredAudioLanguage) ??
          defaults.preferredAudioLanguage,
      preferredSubtitleLanguage:
          prefs.getString(SettingsKeys.preferredSubtitleLanguage) ??
          defaults.preferredSubtitleLanguage,
      preferredDownloadAudioLanguage:
          prefs.getString(SettingsKeys.preferredDownloadAudioLanguage) ??
          defaults.preferredDownloadAudioLanguage,
      preferredDownloadSubtitleLanguage:
          prefs.getString(SettingsKeys.preferredDownloadSubtitleLanguage) ??
          defaults.preferredDownloadSubtitleLanguage,
      autoplay: prefs.getBool(SettingsKeys.autoplay) ?? defaults.autoplay,
      resumePlayback:
          prefs.getBool(SettingsKeys.resumePlayback) ?? defaults.resumePlayback,
      downloadLocation:
          prefs.getString(SettingsKeys.downloadLocation) ?? fallbackDownloadDir,
      downloadQuality:
          prefs.getString(SettingsKeys.downloadQuality) ??
          defaults.downloadQuality,
      downloadConcurrency:
          prefs.getInt(SettingsKeys.downloadConcurrency) ??
          defaults.downloadConcurrency,
      wifiOnlyDownloads:
          prefs.getBool(SettingsKeys.wifiOnlyDownloads) ??
          defaults.wifiOnlyDownloads,
      imageQuality:
          prefs.getString(SettingsKeys.imageQuality) ?? defaults.imageQuality,
      imageProxyUrl:
          prefs.getString(SettingsKeys.imageProxyUrl) ?? defaults.imageProxyUrl,
      iptvPlaylistUrl:
          prefs.getString(SettingsKeys.iptvPlaylistUrl) ??
          defaults.iptvPlaylistUrl,
      iptvCacheHours:
          prefs.getInt(SettingsKeys.iptvCacheHours) ?? defaults.iptvCacheHours,
    );
  }

  final String accentColor;
  final String videoQuality;
  final double playbackSpeed;
  final String preferredAudioLanguage;
  final String preferredSubtitleLanguage;
  final String preferredDownloadAudioLanguage;
  final String preferredDownloadSubtitleLanguage;
  final bool autoplay;
  final bool resumePlayback;
  final String downloadLocation;
  final String downloadQuality;
  final int downloadConcurrency;
  final bool wifiOnlyDownloads;
  final String imageQuality;
  final String imageProxyUrl;
  final String iptvPlaylistUrl;
  final int iptvCacheHours;
}

abstract final class SettingsKeys {
  static const accentColor = 'app_accent_color';
  static const videoQuality = 'video_quality';
  static const playbackSpeed = 'playback_speed';
  static const preferredAudioLanguage = 'preferred_audio_language';
  static const preferredSubtitleLanguage = 'preferred_subtitle_language';
  static const preferredDownloadAudioLanguage =
      'preferred_download_audio_language';
  static const preferredDownloadSubtitleLanguage =
      'preferred_download_subtitle_language';
  static const autoplay = 'autoplay_next_episode';
  static const resumePlayback = 'resume_playback';
  static const downloadLocation = 'download_location';
  static const downloadQuality = 'download_quality';
  static const downloadConcurrency = 'download_concurrency';
  static const wifiOnlyDownloads = 'download_wifi_only';
  static const imageQuality = 'image_quality';
  static const imageProxyUrl = 'image_proxy_url';
  static const iptvPlaylistUrl = 'iptv_playlist_url';
  static const iptvCacheHours = 'iptv_cache_hours';
}

abstract final class SettingsDefaults {
  static const accentColors = [
    'red',
    'blue',
    'green',
    'orange',
    'pink',
    'purple',
    'teal',
    'yellow',
    'cyan',
  ];
  static const videoQualities = ['auto', '2160p', '1080p', '720p', '480p'];
  static const playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const audioLanguages = [
    'Original',
    'English',
    'Japanese',
    'Hindi',
    'Tamil',
    'Telugu',
    'Spanish',
    'French',
    'Korean',
    'German',
    'Italian',
  ];
  static const subtitleLanguages = [
    'Auto',
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Spanish',
    'French',
    'Korean',
    'German',
    'Off',
  ];
}

class ServiceStatus {
  const ServiceStatus({
    required this.tmdb,
    required this.anilist,
    required this.iptv,
    required this.supabase,
    required this.realtime,
  });

  final String tmdb;
  final String anilist;
  final String iptv;
  final String supabase;
  final String realtime;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.error,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(title, style: AppTypography.title)),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// Retained for settings capabilities that are not exposed by Android Profile.
// ignore: unused_element
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    // ignore: unused_element_parameter
    this.leading,
    // ignore: unused_element_parameter
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData? leading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: leading == null ? null : Icon(leading),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(
          value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body,
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: options.contains(value) ? value : options.first,
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

// ignore: unused_element
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
    );
  }
}

// ignore: unused_element
class _TextSettingTile extends StatelessWidget {
  const _TextSettingTile({
    required this.title,
    required this.value,
    required this.hint,
    required this.validator,
    required this.onSubmitted,
  });

  final String title;
  final String value;
  final String hint;
  final String? Function(String) validator;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value.isEmpty ? hint : value),
      trailing: IconButton(
        tooltip: 'Edit $title',
        icon: const Icon(LucideIcons.pencil),
        onPressed: () async {
          final next = await _promptText(
            context,
            title: title,
            initialValue: value,
            hint: hint,
            validator: validator,
          );
          if (next != null) onSubmitted(next);
        },
      ),
    );
  }
}

// ignore: unused_element
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    // ignore: unused_element_parameter
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(LucideIcons.refreshCw),
      onTap: onTap,
    );
  }
}

class _DestructiveTile extends StatelessWidget {
  const _DestructiveTile({required this.title, required this.onConfirm});

  final String title;
  final Future<String> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(LucideIcons.trash2, color: AppColors.danger),
      onTap: () async {
        final confirmed = await _confirm(context, title);
        if (!confirmed) return;
        final message = await onConfirm();
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String initialValue,
  required String hint,
  required String? Function(String) validator,
}) {
  final controller = TextEditingController(text: initialValue);
  String? errorText;
  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: hint, errorText: errorText),
              onSubmitted: (_) {
                final value = controller.text.trim();
                final error = validator(value);
                if (error != null) {
                  setState(() => errorText = error);
                  return;
                }
                Navigator.pop(context, value);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  final error = validator(value);
                  if (error != null) {
                    setState(() => errorText = error);
                    return;
                  }
                  Navigator.pop(context, value);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool> _confirm(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$title?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return result == true;
}

String? _validateHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return 'Enter a valid URL.';
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return 'URL must start with http or https.';
  }
  return null;
}

// ignore: unused_element
String? _validateDirectory(String value) {
  if (value.trim().isEmpty) return 'Enter a directory path.';
  final dir = Directory(value);
  if (!dir.existsSync()) return 'Directory does not exist.';
  return null;
}

Future<String> _checkGet(String url) async {
  final validation = _validateHttpUrl(url);
  if (validation != null) return 'Invalid';
  try {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 6));
    return response.statusCode < 500 ? 'Online' : 'Offline';
  } catch (_) {
    return 'Offline';
  }
}

Future<String> _checkPost(String url) async {
  final validation = _validateHttpUrl(url);
  if (validation != null) return 'Invalid';
  try {
    final response = await http
        .post(
          Uri.parse(url),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'query': '{ Media(id: 1) { id } }'}),
        )
        .timeout(const Duration(seconds: 6));
    return response.statusCode == 200 ? 'Online' : 'Offline';
  } catch (_) {
    return 'Offline';
  }
}

Future<int> _downloadStorageBytes() async {
  if (!LibraryPersistence.isReady) return 0;
  var total = 0;
  for (final item in LibraryPersistence.downloadsBox.values) {
    try {
      final file = File(item.savePath);
      if (file.existsSync()) total += file.lengthSync();
    } catch (_) {}
  }
  return total;
}

Future<String> _defaultDownloadDirectory() async {
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/downloads';
}

Future<(String, String)> _readVersionInfo() async {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return ('1.0.0', '1');
  final content = await file.readAsString();
  final match = RegExp(
    r'^version:\s*([^\s+]+)(?:\+(\S+))?',
    multiLine: true,
  ).firstMatch(content);
  return (match?.group(1) ?? '1.0.0', match?.group(2) ?? '1');
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(unit < 2 ? 0 : 1)} ${units[unit]}';
}
