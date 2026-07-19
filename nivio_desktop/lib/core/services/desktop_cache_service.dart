import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/library/models/library_models.dart';
import '../../features/library/services/library_persistence.dart';

class DesktopCacheEntry {
  const DesktopCacheEntry({
    required this.key,
    required this.data,
    required this.timestamp,
    required this.ttlMilliseconds,
  });

  factory DesktopCacheEntry.fromJson(Map<String, dynamic> json) {
    return DesktopCacheEntry(
      key: json['key']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      ttlMilliseconds: json['ttlMilliseconds'] is int
          ? json['ttlMilliseconds'] as int
          : int.tryParse(json['ttlMilliseconds']?.toString() ?? '') ?? 0,
    );
  }

  final String key;
  final String data;
  final DateTime timestamp;
  final int ttlMilliseconds;

  bool get isExpired {
    if (ttlMilliseconds <= 0) return false;
    return DateTime.now().difference(timestamp) >
        Duration(milliseconds: ttlMilliseconds);
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'ttlMilliseconds': ttlMilliseconds,
  };
}

class DesktopCacheStats {
  const DesktopCacheStats({
    required this.apiEntries,
    required this.validApiEntries,
    required this.expiredApiEntries,
    required this.apiCacheBytes,
    required this.hiveBytes,
    required this.downloadBytes,
    required this.downloadCount,
    required this.completedDownloadCount,
    required this.missingDownloadFiles,
    required this.orphanDownloadFiles,
    required this.offlineModeEnabled,
    required this.networkOnline,
    required this.lastUpdated,
  });

  final int apiEntries;
  final int validApiEntries;
  final int expiredApiEntries;
  final int apiCacheBytes;
  final int hiveBytes;
  final int downloadBytes;
  final int downloadCount;
  final int completedDownloadCount;
  final int missingDownloadFiles;
  final int orphanDownloadFiles;
  final bool offlineModeEnabled;
  final bool networkOnline;
  final DateTime lastUpdated;

  int get localStorageBytes => apiCacheBytes + hiveBytes + downloadBytes;
  bool get shouldPreferOffline => offlineModeEnabled || !networkOnline;
}

class DesktopCacheService {
  DesktopCacheService._();

  static final DesktopCacheService instance = DesktopCacheService._();

  static const apiCacheBoxName = 'desktop_api_cache';
  static const offlineModeKey = 'desktop_offline_mode_enabled';
  static const shortCache = Duration(minutes: 15);
  static const mediumCache = Duration(hours: 1);
  static const longCache = Duration(hours: 24);
  static const extraLongCache = Duration(days: 7);

  Box<String>? _apiCacheBox;
  bool _cleanupStarted = false;

  Future<void> init() async {
    _apiCacheBox ??= await Hive.openBox<String>(apiCacheBoxName);
    if (!_cleanupStarted) {
      _cleanupStarted = true;
      unawaited(cleanExpiredApiCache());
    }
  }

  Future<Map<String, dynamic>?> getRaw(
    String key, {
    bool allowStale = false,
  }) async {
    final box = await _box();
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final entry = DesktopCacheEntry.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (entry.isExpired && !allowStale) {
        await box.delete(key);
        return null;
      }
      return jsonDecode(entry.data) as Map<String, dynamic>;
    } catch (_) {
      await box.delete(key);
      return null;
    }
  }

  Future<void> setRaw(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = mediumCache,
  }) async {
    final box = await _box();
    final entry = DesktopCacheEntry(
      key: key,
      data: jsonEncode(data),
      timestamp: DateTime.now(),
      ttlMilliseconds: ttl.inMilliseconds,
    );
    await box.put(key, jsonEncode(entry.toJson()));
  }

  Future<DesktopCacheStats> getStats() async {
    await init();
    if (!LibraryPersistence.isReady) await LibraryPersistence.init();

    final prefs = await SharedPreferences.getInstance();
    final box = await _box();
    var expired = 0;
    var valid = 0;
    var apiBytes = 0;
    for (final raw in box.values) {
      apiBytes += raw.length;
      try {
        final entry = DesktopCacheEntry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (entry.isExpired) {
          expired++;
        } else {
          valid++;
        }
      } catch (_) {
        expired++;
      }
    }

    final downloadIntegrity = await _downloadIntegrity();

    return DesktopCacheStats(
      apiEntries: box.length,
      validApiEntries: valid,
      expiredApiEntries: expired,
      apiCacheBytes: apiBytes,
      hiveBytes: await _hiveBytes(),
      downloadBytes: downloadIntegrity.downloadBytes,
      downloadCount: LibraryPersistence.downloadsBox.length,
      completedDownloadCount: LibraryPersistence.downloadsBox.values
          .where((item) => item.status == LibraryDownloadStatus.completed)
          .length,
      missingDownloadFiles: downloadIntegrity.missingFiles,
      orphanDownloadFiles: downloadIntegrity.orphanFiles,
      offlineModeEnabled: prefs.getBool(offlineModeKey) ?? false,
      networkOnline: await isNetworkOnline(),
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> setOfflineMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(offlineModeKey, enabled);
  }

  Future<bool> isOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(offlineModeKey) ?? false;
  }

  Future<bool> isNetworkOnline() async {
    try {
      final result = await InternetAddress.lookup(
        'api.themoviedb.org',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<int> cleanExpiredApiCache() async {
    final box = await _box();
    final expiredKeys = <String>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final entry = DesktopCacheEntry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (entry.isExpired) expiredKeys.add(key.toString());
      } catch (_) {
        expiredKeys.add(key.toString());
      }
    }
    for (final key in expiredKeys) {
      await box.delete(key);
    }
    return expiredKeys.length;
  }

  Future<void> clearApiCache() async {
    final box = await _box();
    await box.clear();
  }

  Future<void> clearImageCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await DefaultCacheManager().emptyCache();
  }

  Future<int> removeMissingDownloadRecords() async {
    if (!LibraryPersistence.isReady) await LibraryPersistence.init();
    final missingIds = <String>[];
    for (final item in LibraryPersistence.downloadsBox.values) {
      if (item.status != LibraryDownloadStatus.completed) continue;
      if (item.savePath.trim().isEmpty || !File(item.savePath).existsSync()) {
        missingIds.add(item.id);
      }
    }
    for (final id in missingIds) {
      await LibraryPersistence.downloadsBox.delete(id);
    }
    return missingIds.length;
  }

  Future<int> cleanOrphanDownloadPartials() async {
    final directory = await _downloadDirectory();
    if (!directory.existsSync()) return 0;
    var removed = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.part')) {
        try {
          await entity.delete();
          removed++;
        } catch (_) {}
      } else if (entity is Directory && entity.path.contains('/.hls_')) {
        try {
          await entity.delete(recursive: true);
          removed++;
        } catch (_) {}
      }
    }
    return removed;
  }

  Future<Box<String>> _box() async {
    await init();
    return _apiCacheBox!;
  }

  Future<int> _hiveBytes() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory(appDir.path);
      if (!hiveDir.existsSync()) return 0;
      var total = 0;
      await for (final entity in hiveDir.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path;
          if (path.endsWith('.hive') || path.endsWith('.lock')) {
            total += await entity.length();
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<_DownloadIntegrity> _downloadIntegrity() async {
    final knownPaths = <String>{};
    var bytes = 0;
    var missing = 0;
    for (final item in LibraryPersistence.downloadsBox.values) {
      final path = item.savePath.trim();
      if (path.isEmpty) continue;
      knownPaths.add(path);
      final file = File(path);
      if (file.existsSync()) {
        bytes += await file.length();
      } else if (item.status == LibraryDownloadStatus.completed) {
        missing++;
      }
    }

    final directory = await _downloadDirectory();
    var orphanFiles = 0;
    if (directory.existsSync()) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is! File) continue;
        if (entity.path.endsWith('.part')) {
          orphanFiles++;
          continue;
        }
        if (_isMediaFile(entity.path) && !knownPaths.contains(entity.path)) {
          orphanFiles++;
        }
      }
    }

    return _DownloadIntegrity(
      downloadBytes: bytes,
      missingFiles: missing,
      orphanFiles: orphanFiles,
    );
  }

  Future<Directory> _downloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final configured = prefs.getString('download_location')?.trim();
    if (configured != null && configured.isNotEmpty) {
      return Directory(configured);
    }
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/downloads');
  }

  bool _isMediaFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.srt') ||
        lower.endsWith('.vtt');
  }
}

class _DownloadIntegrity {
  const _DownloadIntegrity({
    required this.downloadBytes,
    required this.missingFiles,
    required this.orphanFiles,
  });

  final int downloadBytes;
  final int missingFiles;
  final int orphanFiles;
}
