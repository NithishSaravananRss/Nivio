import 'package:hive_flutter/hive_flutter.dart';

import '../models/library_models.dart';

class LibraryPersistence {
  static const watchlistBoxName = 'watchlist';
  static const downloadsBoxName = 'downloads';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _registerAdapters();
    await Future.wait([
      Hive.openBox<LibraryWatchlistItem>(watchlistBoxName),
      Hive.openBox<LibraryDownloadItem>(downloadsBoxName),
    ]);
    _initialized = true;
  }

  static bool get isReady =>
      _initialized &&
      Hive.isBoxOpen(watchlistBoxName) &&
      Hive.isBoxOpen(downloadsBoxName);

  static Box<LibraryWatchlistItem> get watchlistBox =>
      Hive.box<LibraryWatchlistItem>(watchlistBoxName);

  static Box<LibraryDownloadItem> get downloadsBox =>
      Hive.box<LibraryDownloadItem>(downloadsBoxName);

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(LibraryWatchlistItemAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(LibraryDownloadStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(LibraryDownloadItemAdapter());
    }
  }
}
