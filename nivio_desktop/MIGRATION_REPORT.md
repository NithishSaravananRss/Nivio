# Nivio Desktop Migration Report

Scope: platform-independent Dart foundations from the original Nivio app.

Original project paths are read-only references. All destinations are inside
`nivio_desktop/`.

## Migrated Foundation Files

### `constants.dart`

Original: `../lib/core/constants.dart`

Destination: `lib/core/constants/constants.dart`

Reason: simple API/image constants and quality priority data. No Flutter UI,
storage, authentication, platform channels, navigation, providers, or media
player dependencies.

Dependencies: none.

Status: migrated.

### `providers_data.dart`

Original: `../lib/core/providers_data.dart`

Destination: `lib/core/constants/providers_data.dart`

Reason: static provider metadata only. No runtime service, storage, UI, or
platform dependency.

Dependencies: none.

Status: migrated.

### `skip_times_models.dart`

Original: `../lib/services/skip_times_models.dart`

Destination: `lib/shared/models/skip_times_models.dart`

Reason: pure Dart value object for skip-time ranges. It does not call network
services or media playback APIs.

Dependencies: Dart core `Duration`.

Status: migrated.

### `stream_result.dart`

Original: `../lib/models/stream_result.dart`

Destination: `lib/shared/models/stream_result.dart`

Reason: plain Dart stream metadata classes with JSON parsing and `copyWith`.
No player, widget, storage, provider, platform, or network dependency.

Dependencies: `skip_times_models.dart`.

Status: migrated with import updated from `package:nivio/...` to local desktop
model import.

### `iptv_channel.dart`

Original: `../lib/models/iptv_channel.dart`

Destination: `lib/shared/models/iptv_channel.dart`

Reason: plain Dart data class with `fromJson` and `toJson`.

Dependencies: none.

Status: migrated.

### `iptv_playlist.dart`

Original: `../lib/models/iptv_playlist.dart`

Destination: `lib/shared/models/iptv_playlist.dart`

Reason: plain Dart data class with `fromJson` and `toJson`.

Dependencies: none.

Status: migrated.

## Safe In Isolation, Deferred

### `watch_party_models.dart`

Original: `../lib/services/watch_party/watch_party_models.dart`

Proposed destination: `lib/shared/models/watch_party_models.dart`

Reason: pure Dart enums and data classes.

Dependencies: Dart core `DateTime`.

Status: deferred. The current phase explicitly excludes business features,
authentication, backend, and feature implementation. Watch-party domain types
are feature-specific, so they should move later with the watch-party feature
boundary.

### Freezed JSON models

Original:

- `../lib/models/api_source.dart`
- `../lib/models/search_result.dart`
- `../lib/models/season_info.dart`
- `../lib/models/watch_history.dart`

Proposed destination: `lib/shared/models/`

Reason: platform-independent model definitions.

Dependencies:

- `freezed_annotation`
- generated `*.freezed.dart`
- generated `*.g.dart`
- desktop build-time generator setup if regenerated

Status: deferred. These are reusable, but migrating them now would require
adding code generation dependencies and generated files to the desktop app.
`watch_history.dart` is also feature-specific to history.

## Do Not Migrate In This Phase

### Hive-backed models

Original:

- `../lib/models/cache_entry.dart`
- `../lib/models/download_item.dart`
- `../lib/models/new_episode.dart`
- `../lib/models/watchlist_item.dart`

Reason: depend on Hive/HiveObject and generated adapters. Current desktop
phase excludes local storage, downloads, notifications, and feature state.

Status: do not migrate.

### UI, screens, widgets, providers, routing, and theme

Original:

- `../lib/widgets/**`
- `../lib/screens/**`
- `../lib/providers/**`
- `../lib/core/theme.dart`

Reason: depend on Flutter widgets, Material UI, BuildContext, Riverpod, or app
feature composition.

Status: do not migrate.

### Services with platform, backend, or feature behavior

Original:

- `../lib/services/auth_service.dart`
- `../lib/services/cache_service.dart`
- `../lib/services/download_service.dart`
- `../lib/services/github_release_update_service.dart`
- `../lib/services/hls_proxy_service.dart`
- `../lib/services/iptv_service.dart`
- `../lib/services/shorebird_update_service.dart`
- `../lib/services/streaming_service.dart`
- `../lib/services/watch_history_service.dart`
- `../lib/services/watch_party/**`
- `../lib/services/watchlist_service.dart`
- `../lib/services/scrapers/**`

Reason: depend on Firebase, Supabase, Hive, SharedPreferences, path providers,
platform services, media playback/download behavior, provider state, or feature
business logic.

Status: do not migrate.

### Network/business services deferred

Original:

- `../lib/services/anilist_service.dart`
- `../lib/services/aniskip_service.dart`
- `../lib/services/api_status_service.dart`
- `../lib/services/episode_check_service.dart`
- `../lib/services/m3u8_parser.dart`
- `../lib/services/schedule_api_service.dart`
- `../lib/services/theintrodb_service.dart`
- `../lib/services/tmdb_service.dart`

Reason: mostly platform-independent networking/parsing, but they introduce API
clients, backend calls, media parsing, or feature business behavior. The current
phase explicitly excludes APIs, backend, media player code, and business
features.

Status: defer until the relevant feature/service layer is intentionally added.
