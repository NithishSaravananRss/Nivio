import 'package:hive_flutter/hive_flutter.dart';

import '../models/library_models.dart';

class LibraryPersistence {
  static const watchlistBoxName = 'watchlist';
  static const downloadsBoxName = 'downloads';
  static const newEpisodesBoxName = 'new_episodes';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _registerAdapters();
    await Future.wait([
      Hive.openBox<LibraryWatchlistItem>(watchlistBoxName),
      Hive.openBox<LibraryDownloadItem>(downloadsBoxName),
      Hive.openBox<LibraryNewEpisodeItem>(newEpisodesBoxName),
    ]);
    _initialized = true;
  }

  static bool get isReady =>
      _initialized &&
      Hive.isBoxOpen(watchlistBoxName) &&
      Hive.isBoxOpen(downloadsBoxName) &&
      Hive.isBoxOpen(newEpisodesBoxName);

  static Box<LibraryWatchlistItem> get watchlistBox =>
      Hive.box<LibraryWatchlistItem>(watchlistBoxName);

  static Box<LibraryDownloadItem> get downloadsBox =>
      Hive.box<LibraryDownloadItem>(downloadsBoxName);

  static Box<LibraryNewEpisodeItem> get newEpisodesBox =>
      Hive.box<LibraryNewEpisodeItem>(newEpisodesBoxName);

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
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(LibraryNewEpisodeItemAdapter());
    }
  }
}
