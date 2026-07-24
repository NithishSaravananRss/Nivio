import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../history/desktop_watch_history_repository.dart';
import '../history/watch_history_storage.dart';
import '../library/models/library_models.dart';
import '../library/services/library_persistence.dart';
import 'firebase_auth_rest_service.dart';
import 'firebase_firestore_rest_service.dart';

class DesktopCloudSyncService {
  DesktopCloudSyncService._();

  static final DesktopCloudSyncService instance = DesktopCloudSyncService._();

  final FirebaseAuthRestService _auth = FirebaseAuthRestService.instance;
  final FirebaseFirestoreRestService _firestore =
      FirebaseFirestoreRestService.instance;

  bool _initialized = false;
  bool _syncing = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _auth.addListener(_onAuthChanged);
    if (_auth.canSyncCloud) {
      unawaited(syncEverything());
    }
  }

  Future<void> syncEverything() async {
    if (!_auth.canSyncCloud || _syncing) return;
    _syncing = true;
    try {
      await syncProfile();
      await downloadWatchlist();
      await downloadHistory();
      await syncAllWatchlist();
      await syncAllHistory();
    } finally {
      _syncing = false;
    }
  }

  Future<void> syncProfile() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _ignoreCloudErrors(() {
      return _firestore.setDocument('users/${user.uid}', {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<void> syncWatchlistItem(LibraryWatchlistItem item) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _ignoreCloudErrors(() {
      return _firestore.setDocument(
        'users/${user.uid}/watchlist/${item.id}',
        _watchlistItemToJson(item),
      );
    });
  }

  Future<void> removeWatchlistItem(int mediaId) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _ignoreCloudErrors(() {
      return _firestore.deleteDocument('users/${user.uid}/watchlist/$mediaId');
    });
  }

  Future<void> syncAllWatchlist() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || !LibraryPersistence.isReady) return;
    final items = LibraryPersistence.watchlistBox.values.toList();
    for (final item in items) {
      await syncWatchlistItem(item);
    }
  }

  Future<void> downloadWatchlist() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || !LibraryPersistence.isReady) return;
    await _ignoreCloudErrors(() async {
      final docs = await _firestore.listDocuments(
        'users/${user.uid}/watchlist',
      );
      final box = LibraryPersistence.watchlistBox;
      for (final doc in docs) {
        final item = _watchlistItemFromJson(doc);
        if (item == null || box.containsKey(item.id)) continue;
        await box.put(item.id, item);
      }
    });
  }

  Future<void> syncHistoryEntry(Map<String, dynamic> entry) async {
    final user = _auth.currentUser;
    final mediaId = _intValue(entry['tmdbId'] ?? entry['mediaId']);
    if (user == null || user.isAnonymous || mediaId == null) return;
    await _ignoreCloudErrors(() {
      return _firestore.setDocument(
        'users/${user.uid}/watchHistory/$mediaId',
        entry,
      );
    });
  }

  Future<void> removeHistoryEntry(int mediaId) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _ignoreCloudErrors(() {
      return _firestore.deleteDocument(
        'users/${user.uid}/watchHistory/$mediaId',
      );
    });
  }

  Future<void> syncAllHistory() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    final history = await DesktopWatchHistoryRepository.instance
        .getWatchHistory();
    for (final entry in history) {
      await syncHistoryEntry(entry);
    }
  }

  Future<void> downloadHistory() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _ignoreCloudErrors(() async {
      final docs = await _firestore.listDocuments(
        'users/${user.uid}/watchHistory',
      );
      final box = await Hive.openBox<String>(HiveWatchHistoryStorage.boxName);
      for (final entry in docs) {
        final mediaId = _intValue(entry['tmdbId'] ?? entry['mediaId']);
        if (mediaId == null) continue;
        final key = 'null_$mediaId';
        final local = _decode(box.get(key));
        final cloudDate = _date(entry['lastWatchedAt']);
        final localDate = _date(local?['lastWatchedAt']);
        if (local == null || cloudDate.isAfter(localDate)) {
          await box.put(key, jsonEncode(entry));
        }
      }
    });
  }

  Future<void> clearCloudHistory() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _ignoreCloudErrors(() async {
      final docs = await _firestore.listDocuments(
        'users/${user.uid}/watchHistory',
      );
      for (final entry in docs) {
        final mediaId = _intValue(entry['tmdbId'] ?? entry['mediaId']);
        if (mediaId != null) await removeHistoryEntry(mediaId);
      }
    });
  }

  Future<void> syncSettings(Map<String, dynamic> settings) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _ignoreCloudErrors(() {
      return _firestore.setDocument('users/${user.uid}/settings/app', {
        ...settings,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<Map<String, dynamic>?> downloadSettings() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    try {
      return await _firestore.getDocument('users/${user.uid}/settings/app');
    } catch (_) {
      return null;
    }
  }

  void _onAuthChanged() {
    if (_auth.canSyncCloud) unawaited(syncEverything());
  }

  static Map<String, dynamic> _watchlistItemToJson(LibraryWatchlistItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'posterPath': item.posterPath,
      'mediaType': item.mediaType,
      'addedAt': item.addedAt.toIso8601String(),
      'voteAverage': item.voteAverage,
      'releaseDate': item.releaseDate,
      'overview': item.overview,
    };
  }

  static LibraryWatchlistItem? _watchlistItemFromJson(
    Map<String, dynamic> json,
  ) {
    final id = _intValue(json['id']);
    final title = json['title']?.toString();
    final mediaType = json['mediaType']?.toString();
    if (id == null || title == null || title.isEmpty || mediaType == null) {
      return null;
    }
    return LibraryWatchlistItem(
      id: id,
      title: title,
      posterPath: json['posterPath']?.toString(),
      mediaType: mediaType,
      addedAt: _date(json['addedAt']),
      voteAverage: _doubleValue(json['voteAverage']),
      releaseDate: json['releaseDate']?.toString(),
      overview: json['overview']?.toString(),
    );
  }

  static Future<void> _ignoreCloudErrors(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  static Map<String, dynamic>? _decode(String? encoded) {
    if (encoded == null) return null;
    try {
      final value = jsonDecode(encoded);
      if (value is Map) {
        return value.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return null;
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _doubleValue(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime _date(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
