# Reusable Dart Migration Plan

## Scope

Only platform-independent Dart code from the original Android Flutter project is eligible for migration into `nivio_desktop`. Reusable code must not depend on Flutter widgets, Android APIs, Firebase, Supabase, platform-specific plugins, generated build steps, storage adapters, or state management providers.

## Migrated

### Core Constants

- `../lib/core/constants.dart` -> `lib/core/constants/constants.dart`
- `../lib/core/providers_data.dart` -> `lib/core/constants/providers_data.dart`

These files contain static Dart constants and catalog data only.

### Shared Models

- `../lib/models/iptv_channel.dart` -> `lib/shared/models/iptv_channel.dart`
- `../lib/models/iptv_playlist.dart` -> `lib/shared/models/iptv_playlist.dart`
- `../lib/models/stream_result.dart` -> `lib/shared/models/stream_result.dart`
- `../lib/services/skip_times_models.dart` -> `lib/shared/models/skip_times_models.dart`
- `../lib/services/watch_party/watch_party_models.dart` -> `lib/shared/models/watch_party_models.dart`

These files are plain Dart DTOs/value objects. The copied `stream_result.dart` import was updated from the original app package path to the local desktop model path.

## Deferred

The following groups are reusable only after a deliberate desktop dependency strategy is chosen:

- Freezed/json-serializable models: `api_source`, `search_result`, `season_info`, `watch_history`
- Hive-backed models: `cache_entry`, `download_item`, `new_episode`, `watchlist_item`
- API clients and scrapers that depend on generated models, cache services, Riverpod providers, Flutter foundation utilities, Cronet, WebView, or existing Android app package imports
- Storage, authentication, watchlist, watch history, download, update, notification, player, Firebase, Supabase, and platform-plugin services

## Verification

After each migration group, run:

```sh
flutter analyze
flutter test
```

The desktop app should remain a compilable shell until feature implementation begins.
