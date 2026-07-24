import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnvironment {
  static const String fileName = '.env';
  static Map<String, String>? _fileValues;

  static const List<String> _requiredKeys = [
    'TMDB_API_KEY',
    'ANILIST_API_URL',
    'IMAGE_PROXY_URL',
    'IPTV_PLAYLIST_URL',
    'LOG_LEVEL',
  ];

  static Future<void> load() async {
    debugPrint('[env] load start file=$fileName');
    await dotenv.load(fileName: fileName);
    debugPrint('[env] load end keys=${dotenv.env.keys.length}');
    validate();
    debugPrint('[env] validation ok');
  }

  static void validate() {
    final missing = _requiredKeys
        .where((key) => _value(key).trim().isEmpty)
        .toList(growable: false);
    if (missing.isEmpty) return;

    debugPrint('[env] validation failed missing=${missing.join(',')}');
    throw StateError(
      'Missing required desktop environment variable(s): ${missing.join(', ')}. '
      'Create nivio_desktop/.env from .env.example and provide values before startup.',
    );
  }

  static String get tmdbApiKey => _require('TMDB_API_KEY');
  static String get tmdbReadAccessToken => _optional('TMDB_READ_ACCESS_TOKEN');
  static String get anilistApiUrl => _require('ANILIST_API_URL');
  static String get supabaseUrl => _optional('SUPABASE_URL');
  static String get supabaseAnonKey => _optional('SUPABASE_ANON_KEY');
  static String get iptvPlaylistUrl => _require('IPTV_PLAYLIST_URL');
  static String get iptvEpgUrl => _optional('IPTV_EPG_URL');
  static String get firebaseWebApiKey => _optional('FIREBASE_WEB_API_KEY');
  static String get firebaseProjectId => _optional('FIREBASE_PROJECT_ID');
  static String get firebaseGoogleClientId =>
      _optional('FIREBASE_GOOGLE_CLIENT_ID');
  static String get firebaseGoogleClientSecret =>
      _optional('FIREBASE_GOOGLE_CLIENT_SECRET');
  static String get firebaseAppId => _optional('FIREBASE_APP_ID');
  static String get firebaseMessagingSenderId =>
      _optional('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseStorageBucket =>
      _optional('FIREBASE_STORAGE_BUCKET');
  static String get apiBaseUrl => _optional('API_BASE_URL');
  static String get imageProxyUrl =>
      _trimTrailingSlash(_require('IMAGE_PROXY_URL'));
  static String get logLevel => _require('LOG_LEVEL');
  static String get desktopUpdateRepoOwner =>
      _optional('DESKTOP_UPDATE_REPO_OWNER');
  static String get desktopUpdateRepoName =>
      _optional('DESKTOP_UPDATE_REPO_NAME');
  static String get desktopUpdateAssetPattern =>
      _optional('DESKTOP_UPDATE_ASSET_PATTERN');

  static String _require(String key) {
    final value = _value(key).trim();
    if (value.isNotEmpty) return value;
    throw StateError(
      'Missing required desktop environment variable: $key. '
      'Create nivio_desktop/.env from .env.example and provide a value.',
    );
  }

  static String _optional(String key) => _value(key).trim();

  static String _value(String key) {
    try {
      final dotenvValue = dotenv.maybeGet(key);
      if (dotenvValue != null) return dotenvValue;
    } catch (_) {
      // Widget tests may instantiate the app without running bootstrap().
      // Fall back to the desktop .env file so tests do not bypass production
      // startup validation, which still happens in load().
    }

    final fileValue = _readFileValues()[key];
    if (fileValue != null) return fileValue;

    return String.fromEnvironment(key);
  }

  static String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Map<String, String> _readFileValues() {
    final cached = _fileValues;
    if (cached != null) return cached;

    final file = File(fileName);
    if (!file.existsSync()) {
      _fileValues = const {};
      return _fileValues!;
    }

    final values = <String, String>{};
    for (final rawLine in file.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      values[key] = value;
    }
    _fileValues = values;
    return values;
  }
}
