import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/constants.dart';
import '../models/library_models.dart';
import 'library_persistence.dart';

class LibraryEpisodeTrackingService {
  LibraryEpisodeTrackingService._({
    Dio? dio,
    SharedPreferencesAsync? preferences,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: tmdbBaseUrl,
               connectTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 30),
               queryParameters: {'api_key': tmdbApiKey},
             ),
           ),
       _preferences = preferences ?? SharedPreferencesAsync();

  static final LibraryEpisodeTrackingService instance =
      LibraryEpisodeTrackingService._();

  static const _lastCheckKey = 'desktop_episode_check_last_run';
  static const _frequencyKey = 'desktop_episode_check_frequency_hours';
  static const _enabledKey = 'desktop_episode_check_enabled';
  static const _defaultFrequencyHours = 24;

  final Dio _dio;
  final SharedPreferencesAsync _preferences;
  Future<int>? _activeCheck;

  Box<LibraryNewEpisodeItem> get _box => LibraryPersistence.newEpisodesBox;

  ValueListenable<Box<LibraryNewEpisodeItem>> listenable() => _box.listenable();

  List<LibraryNewEpisodeItem> getNewEpisodes() {
    if (!LibraryPersistence.isReady) return const [];
    return _box.values.toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  int getUnreadCount() {
    if (!LibraryPersistence.isReady) return 0;
    return _box.values.where((episode) => !episode.isRead).length;
  }

  Future<bool> isEnabled() async {
    return await _preferences.getBool(_enabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) {
    return _preferences.setBool(_enabledKey, enabled);
  }

  Future<int> getFrequencyHours() async {
    return await _preferences.getInt(_frequencyKey) ?? _defaultFrequencyHours;
  }

  Future<void> setFrequencyHours(int hours) {
    return _preferences.setInt(_frequencyKey, hours);
  }

  Future<DateTime?> getLastCheckTime() async {
    final timestamp = await _preferences.getInt(_lastCheckKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> runAppLaunchCheck() async {
    if (!LibraryPersistence.isReady || !await isEnabled()) return;

    final lastCheck = await getLastCheckTime();
    if (lastCheck != null) {
      final frequencyHours = await getFrequencyHours();
      final nextCheck = lastCheck.add(Duration(hours: frequencyHours));
      if (DateTime.now().isBefore(nextCheck)) return;
    }

    unawaited(
      Future<void>.delayed(const Duration(seconds: 5)).then((_) => checkNow()),
    );
  }

  Future<int> checkNow() {
    if (_activeCheck != null) return _activeCheck!;
    final check = _performEpisodeCheck();
    _activeCheck = check.whenComplete(() => _activeCheck = null);
    return _activeCheck!;
  }

  Future<void> markAsRead(String episodeKey) async {
    if (!LibraryPersistence.isReady) return;
    final episode = _box.get(episodeKey);
    if (episode == null || episode.isRead) return;
    await _box.put(episodeKey, episode.copyWith(isRead: true));
  }

  Future<void> markAllAsRead() async {
    if (!LibraryPersistence.isReady) return;
    for (final key in _box.keys) {
      final episode = _box.get(key);
      if (episode != null && !episode.isRead) {
        await _box.put(key, episode.copyWith(isRead: true));
      }
    }
  }

  Future<void> clearAll() async {
    if (!LibraryPersistence.isReady) return;
    await _box.clear();
  }

  Future<int> _performEpisodeCheck() async {
    if (!LibraryPersistence.isReady || !await isEnabled()) return 0;

    try {
      final since =
          await getLastCheckTime() ??
          DateTime.now().subtract(const Duration(days: 7));
      final tvShows = LibraryPersistence.watchlistBox.values
          .where((item) => item.mediaType == 'tv')
          .toList();
      if (tvShows.isEmpty) {
        await _preferences.setInt(
          _lastCheckKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return 0;
      }

      var newEpisodesFound = 0;
      for (final show in tvShows) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          final episodes = await _checkShowForNewEpisodes(show, since);
          for (final episode in episodes) {
            if (_box.containsKey(episode.episodeKey)) continue;
            await _box.put(episode.episodeKey, episode);
            newEpisodesFound++;
          }
        } catch (_) {
          continue;
        }
      }

      await _preferences.setInt(
        _lastCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      return newEpisodesFound;
    } catch (_) {
      return 0;
    }
  }

  Future<List<LibraryNewEpisodeItem>> _checkShowForNewEpisodes(
    LibraryWatchlistItem show,
    DateTime since,
  ) async {
    final details = await _dio.get('/3/tv/${show.id}');
    final seasons = details.data['seasons'] as List<dynamic>? ?? const [];
    final recentSeasons =
        seasons
            .where((season) => (season['season_number'] as int? ?? 0) > 0)
            .toList()
          ..sort(
            (a, b) => (b['season_number'] as int).compareTo(
              a['season_number'] as int,
            ),
          );

    final newEpisodes = <LibraryNewEpisodeItem>[];
    for (final season in recentSeasons.take(2)) {
      final seasonNumber = season['season_number'] as int;
      final response = await _dio.get('/3/tv/${show.id}/season/$seasonNumber');
      final episodes = response.data['episodes'] as List<dynamic>? ?? const [];

      for (final episode in episodes) {
        final airDate = DateTime.tryParse(
          episode['air_date']?.toString() ?? '',
        );
        if (airDate == null ||
            !airDate.isAfter(since) ||
            airDate.isAfter(DateTime.now())) {
          continue;
        }

        final episodeNumber = episode['episode_number'] as int? ?? 0;
        if (episodeNumber <= 0) continue;

        newEpisodes.add(
          LibraryNewEpisodeItem(
            showId: show.id,
            showName: show.title,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            episodeName: episode['name']?.toString().trim().isNotEmpty == true
                ? episode['name'] as String
                : 'Episode $episodeNumber',
            posterPath: show.posterPath,
            airDate: airDate,
            detectedAt: DateTime.now(),
          ),
        );
      }
    }

    return newEpisodes;
  }
}
