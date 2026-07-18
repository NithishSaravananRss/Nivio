# Nivio Desktop Production Blueprint

Status: architecture frozen after Phase 22.4.11.

Scope: Linux Desktop production architecture. This document is the permanent
reference for remaining Desktop implementation. Android remains the behavioral
source of truth; Desktop remains the Linux implementation architecture.

## 1. Project Design Principles

1. Android defines behavior.
2. Desktop defines implementation.
3. Extend existing Desktop architecture before introducing new frameworks.
4. `media_kit` and libmpv remain the primary playback engine.
5. WebKitGTK is used only where direct playback is technically impossible.
6. Every Linux-specific feature goes through `PlatformService`.
7. Every streaming provider implements the Provider Registry contract.
8. Local-first functionality is mandatory.
9. Cloud synchronization augments local data; it never replaces local data.
10. Follow native Linux UX conventions while preserving Android feature parity.
11. Optimize for maintainability, reliability, debuggability, and production quality.
12. No architecture changes after this freeze unless a verified technical blocker is discovered.

## 2. Source Of Truth

Android is the specification for:

- feature behavior.
- provider behavior and ordering.
- metadata APIs.
- episode metadata pipeline.
- watch history behavior.
- recommendation algorithm.
- watch party state model.
- settings semantics.
- empty, loading, and error states.

Desktop is the implementation target for:

- Linux UI shell.
- controller and repository boundaries.
- Linux playback implementation.
- Linux persistence implementation.
- Linux packaging.
- Linux platform integrations.

Desktop must not copy Android platform code blindly. Android services are mapped
to Desktop repositories, controllers, platform services, and providers.

## 3. Final Desktop Architecture

The Desktop architecture is:

```text
Widget
↓
Controller
↓
Repository / Provider Registry / PlatformService
↓
Network Client / Hive / libmpv / Linux API
↓
External API / Local Filesystem / Linux Desktop
```

Rules:

- Widgets render UI and dispatch user intent.
- Controllers own loading, empty, error, pagination, sorting, retry, and view state.
- Repositories own API access, persistence, mapping, cache use, retry, and error conversion.
- Provider Registry owns stream provider selection and stream resolution contracts.
- `PlatformService` owns every Linux-native API.
- Widgets and controllers must not call Dio, Hive, DBus, Secret Service, XDG portals, libnotify, or filesystem dialogs directly.
- Repositories must not call UI widgets.
- Player code must use the playback engine abstraction before reaching `media_kit` or libmpv.

Do not introduce Riverpod into Desktop implementation. Existing Desktop
controller/repository architecture is the frozen direction.

## 4. Multi-Distribution Support Policy

Primary developer environment:

- Arch Linux.

Tier 1 release validation:

- Ubuntu LTS.
- Fedora Workstation.
- Arch Linux.

Tier 2:

- Debian.
- openSUSE.

Future:

- ARM64 Linux.
- Additional distributions after x86_64 release quality is stable.

Every production release must pass validation on all Tier 1 platforms. Tier 2
platforms are compatibility targets and should be tested before major releases
when practical. Both Wayland and X11 are supported targets.

Primary package order:

1. AppImage for broad first-party distribution.
2. Flatpak for sandboxed desktop distribution.
3. DEB and RPM for distro-native packaging.
4. PKGBUILD/AUR packaging after release artifacts stabilize.
5. Snap only if there is explicit product need.

## 5. Linux PlatformService

`PlatformService` is mandatory. Every Linux-specific feature goes through this
abstraction.

```text
PlatformService
├── DBus
├── MPRIS
├── Notifications
├── Secret Service
├── XDG Portals
├── Media Keys
├── Clipboard
├── File Picker
├── Power Inhibit
├── URI Launcher
└── Desktop Entry Integration
```

No UI, Player, Downloader, Party, Authentication, or Repository layer may call
Linux APIs directly.

Required PlatformService capabilities:

- DBus integration for MPRIS and desktop notifications.
- MPRIS metadata and playback controls.
- Media key handling.
- Secret Service token storage.
- XDG portal file open/save flows where appropriate.
- Native file picker abstraction.
- Clipboard read/write abstraction.
- Power inhibition while playing video or downloading.
- URI launch/open handling.
- Desktop entry and URI scheme integration.
- Notification actions for supported desktops.

Optional PlatformService capabilities:

- system tray.
- always-on-top windows.
- mini-player.
- multi-monitor placement helpers.
- diagnostic export dialog.

Future PlatformService capabilities:

- Discord Rich Presence.
- deeper KDE/GNOME integration.
- Picture-in-Picture if a reliable Linux implementation is verified.

## 6. Cache Contract

Every cache must support:

- TTL.
- schema/version metadata.
- stale-while-revalidate.
- manual clear.
- automatic cleanup.
- statistics.
- corruption recovery.
- background refresh.

Every cache should expose diagnostics:

- entry count.
- memory usage.
- disk usage.
- last refresh.
- expiration.
- hit rate.
- miss rate.

Standard cache lifecycle:

```text
Lookup
↓
Fresh hit: return cached value
↓
Stale hit: return stale value and schedule background refresh
↓
Miss: fetch from source and persist
↓
Fetch failure with stale value: return stale value and expose warning
↓
Fetch failure without stale value: return typed error
↓
Cleanup: remove expired entries outside retention window
↓
Diagnostics: report health and usage
```

Cache implementations must recover from corrupted boxes/files by preserving a
backup where practical, clearing only the damaged cache, and surfacing a
diagnostic event. User data caches such as history, watchlist, downloads, and
settings require stronger migration and recovery rules than disposable API
caches.

Desktop must mirror Android's cache behavior where Android already defines it:
short, medium, long, and extra-long TTL classes; Hive-backed persistent cache;
and stale-while-revalidate for user-facing API data.

## 7. Provider Registry Contract

Desktop must introduce a Provider Registry without changing Android behavior.
Android provider selection is currently service-driven and hard-coded; Desktop
keeps the same ordering and behavior but formalizes the contract for long-term
maintenance.

Required provider architecture:

```text
ProviderRegistry
↓
StreamProvider interface
↓
NetMirror / Nivio
Animetsu
Miruro
Animex
VidUp
VidCore
VidLink
VidPlus
Future providers
```

Every provider must expose:

- metadata: id, display name, media types, priority, stable provider key.
- capabilities: direct media, iframe, HLS, DASH, subtitles, audio tracks, quality selection, download support.
- authentication requirements.
- request headers and referrer/origin requirements.
- stream resolution.
- server enumeration.
- quality enumeration.
- subtitle enumeration.
- audio enumeration.
- error classification.
- diagnostics.

Provider rules:

- Android provider order remains the behavior baseline.
- Anime provider priority follows Android settings: Animetsu default, then Miruro, then Animex unless user preference changes ordering.
- Provider/server selection persistence must match Android watch history behavior where Android persists it.
- Direct providers route to `media_kit`/libmpv.
- Iframe-only providers route to WebKitGTK fallback only when no direct stream is available.
- External plugin loading is a future enhancement, not a v1 requirement.

## 8. Playback Blueprint

Primary playback engine:

- `media_kit` on Flutter Desktop.
- libmpv/MPV underneath.

Direct media routes:

- MP4.
- MKV.
- HLS.
- DASH where provider exposes a compatible manifest.
- IPTV M3U/M3U8 streams.
- downloaded local files.

All direct media flows route through the Desktop playback engine abstraction,
then to `media_kit`/libmpv.

Iframe provider policy:

- WebKitGTK is not the primary player.
- WebKitGTK is allowed only for providers that do not expose direct playable media URLs.
- WebView fallback must preserve Android iframe behavior: ad/popup suppression, fullscreen handling, page lifecycle handling, and error reporting.
- WebView fallback must remain isolated behind provider/player routing and must not leak into normal direct playback.

Trailers:

- Prefer direct trailer playback when a direct media URL exists.
- Use WebKitGTK only for iframe trailer embeds that cannot be resolved directly.
- Fall back to opening an external browser when embedded playback is unreliable.

Required playback features:

- provider and server selection.
- quality selection.
- subtitle track selection.
- local subtitle file support.
- remote subtitle URL support.
- subtitle delay.
- subtitle styling where supported by libmpv.
- audio track selection.
- playback speed.
- repeat.
- resume.
- watch history.
- continue watching.
- party synchronization for Android-equivalent state.
- fullscreen.
- keyboard controls.
- media keys via `PlatformService`.

Desktop-only optional enhancements:

- playback statistics.
- decoder information.
- cache statistics.
- dropped frame counter.
- screenshot capture.
- HDR diagnostics.
- tone mapping controls.
- GLSL shader profiles.
- replay gain.
- audio normalization.
- performance overlay.

Default libmpv policy:

- use automatic hardware decoding by default.
- do not force VAAPI, NVDEC, Vulkan, or OpenGL globally.
- expose diagnostics so users and developers can see selected decoder, renderer, cache, dropped frames, FPS, and hardware acceleration state.
- allow advanced users to override hardware acceleration settings later.

## 9. Authentication Blueprint

Desktop authentication uses:

- guest mode/local identity by default.
- browser OAuth for Google sign-in.
- Firebase Authentication REST API.
- Firestore REST API.
- Secret Service for secure token persistence.
- Hive/local persistence for local-first user data.

FlutterFire Linux is not required for v1 because Desktop only needs the Auth and
Firestore REST surfaces, and Linux plugin coverage does not justify bringing in
mobile-oriented Firebase runtime assumptions.

Rules:

- Guest mode must work without cloud services.
- Local history, watchlist, settings, downloads, and library data must work without login.
- Login enables cloud sync, not local functionality.
- Expired tokens must recover through refresh flow or prompt for sign-in.
- Secure tokens go through `PlatformService` Secret Service integration.
- Firestore sync conflicts must prefer deterministic merge rules and never corrupt local data.

## 10. Download Blueprint

Linux downloads are implemented as a Desktop download engine, not an Android
service port.

Required capabilities:

- queue.
- pause/resume where source supports it.
- retry.
- cancellation.
- parallel direct downloads.
- HLS playlist download.
- HLS segment download.
- segment/key URL handling.
- FFmpeg-based mux/merge where needed.
- progress persistence.
- metadata persistence.
- library integration.
- notifications via `PlatformService`.
- recovery after app restart.

Linux implementation policy:

- Android `DownloadService` behavior is the reference.
- Android notifications, permissions, wakelock, FFmpegKit, and Cronet code are replaced.
- Use system FFmpeg first in development.
- Bundled FFmpeg may be used for production AppImage if licensing and codec policy are verified.
- Flatpak packaging must declare/runtime-provide required multimedia dependencies.
- Download file layout must be predictable, user-visible, and recoverable.

## 11. Linux UX Rules

Android remains the UX behavior reference. Desktop adapts interaction for Linux:

- mouse.
- keyboard.
- hover.
- large displays.
- multiple windows where supported.
- native window management.

Required Linux UX rules:

- native keyboard shortcuts.
- `Ctrl+Q`: quit.
- `Ctrl+W`: close current window/view where applicable.
- `Ctrl+F`: find/search within current view where applicable.
- `Ctrl+L`: focus location/search field where applicable.
- `F11`: fullscreen.
- media keys for playback.
- native drag and drop.
- clipboard support.
- native file dialogs.
- native notifications.
- window position persistence.
- window size persistence.
- last monitor persistence where reliable.
- fullscreen persistence.
- HiDPI support.
- respect desktop theme where appropriate.

Existing Desktop shortcut rules remain valid:

- `Ctrl+K` or `/`: global search.
- `Esc`: close popover/dialog or clear focus.
- `Alt+Left`: back.
- `Alt+Right`: forward.
- `Ctrl+,`: settings.
- `F5` or `Ctrl+R`: refresh current data view.
- `Enter`: activate focused card/action.
- `Space`: toggle focused checkbox/switch.

Hover rules:

- hover may reveal secondary actions.
- hover must not be the only way to access an action.
- hover must not change layout dimensions.

Player UX rules:

- full player must be usable without a mouse.
- keyboard shortcuts must cover play/pause, seek, volume, fullscreen, subtitle/audio menu access, and escape/back behavior.
- media keys must map to playback through `PlatformService`.

## 12. Accessibility Requirements

Accessibility is mandatory, not optional.

Required:

- keyboard-only navigation.
- visible focus indicators.
- keyboard alternative for every hover interaction.
- semantic labels for icon-only buttons.
- high contrast compatibility.
- text scaling support.
- reduced motion compatibility.
- full player usability without a mouse.

Implementation rules:

- focus order follows visual order.
- every actionable control is reachable by keyboard.
- icon-only buttons expose semantic labels and tooltips.
- no critical state is conveyed by color alone.
- text scaling must not clip primary controls.
- nonessential animation must respect reduced motion.
- media cards expose title, year, type, and primary action semantics.

## 13. Desktop Asset Policy

Required production assets:

- SVG source assets.
- symbolic icons.
- HiDPI icons.
- 16 px icon.
- 24 px icon.
- 32 px icon.
- 48 px icon.
- 64 px icon.
- 128 px icon.
- 256 px icon.
- 512 px icon.
- Desktop Entry icon.
- AppStream icon.
- light theme compatibility.
- dark theme compatibility.
- font license verification.
- loading illustrations.
- empty-state illustrations.

Rules:

- Keep source SVGs tracked in Git.
- Generated raster icons may be tracked when they are release artifacts needed by Linux package formats.
- Verify font license before bundling fonts.
- Verify illustration/icon licenses before distribution.
- App icon and AppStream icon must match package metadata.
- Assets must render cleanly on HiDPI displays and both light/dark themes.

## 14. Binary Distribution Policy

Before every release verify:

- FFmpeg build configuration.
- libmpv build configuration.
- license compatibility.
- third-party notices.
- bundled binaries.
- dynamic vs static linking.
- AppImage contents.
- Flatpak runtime.
- package dependencies.

Release compliance requirements:

- record whether FFmpeg is system-provided or bundled.
- record whether libmpv is system-provided or bundled.
- document enabled FFmpeg codecs/features.
- avoid nonfree FFmpeg builds for public distribution unless legal review approves.
- include third-party notices for bundled dependencies.
- include TMDB attribution where required.
- verify WebKitGTK dependency policy for WebView fallback packages.
- validate package contents on Tier 1 distributions.

## 15. Performance Budget

Engineering goals:

| Area | Target |
| --- | --- |
| Cold start | < 3 seconds |
| Warm start | < 1 second |
| Player launch after stream resolved | < 1 second |
| Search response after debounce/cache | < 300 ms for cached/common paths |
| Cache lookup | < 50 ms |
| Grid/rail scrolling | 60 FPS target |
| Player UI overlay response | < 100 ms |
| Provider fallback decision | < 2 seconds per failed provider where possible |
| Idle CPU | near 0 percent when not playing/downloading |
| Idle RAM | keep below 500 MB target after warm home load |
| Download progress update cadence | smooth but throttled to avoid UI churn |

Performance rules:

- no expensive synchronous work in build methods.
- image dimensions must be reserved before load.
- API and image cache behavior must be observable in diagnostics.
- provider resolution should be cancellable where practical.
- large IPTV playlists must parse off the UI-critical path.
- diagnostics and logging must not materially degrade playback.

## 16. Logging And Diagnostics

Log levels:

- `TRACE`: detailed development-only flow.
- `DEBUG`: implementation diagnostics.
- `INFO`: lifecycle and user-relevant background events.
- `WARN`: recoverable failures.
- `ERROR`: failed operations requiring fallback or user-visible failure.
- `FATAL`: unrecoverable crash or startup blocker.

Rules:

- logs are stored under XDG state/cache locations, not arbitrary project paths.
- logs rotate.
- tokens, secrets, cookies, and raw authorization headers are redacted.
- developer diagnostics are hidden behind developer mode.
- users can export diagnostics intentionally.

Required diagnostics:

- player backend.
- decoder.
- renderer.
- GPU.
- hardware acceleration state.
- provider.
- server.
- stream URL type.
- bitrate where available.
- resolution.
- FPS.
- dropped frames.
- cache usage.
- network speed.
- current package/runtime information.

## 17. Error Reporting

Production error handling:

- user-facing messages explain what failed and what action is possible.
- technical details go to logs/diagnostics, not normal dialogs.
- retries are explicit unless operation is a background refresh.
- crash reporting, if added, must be opt-in.
- log export must be available for support.
- recovery flows must preserve local data.

Common recovery cases:

- missing `.env`: app starts with dependent cloud features disabled.
- expired authentication: refresh token or prompt sign-in.
- invalid provider: skip to next provider and report fallback.
- failed stream: offer retry/provider switch/server switch.
- corrupted disposable cache: clear cache and refetch.
- corrupted user data store: backup, recover, and explain.

## 18. Data Migration Strategy

Required:

- Hive schema versioning.
- box-level migrations.
- preference key migrations.
- backups before destructive migrations.
- rollback handling where practical.
- recovery handling for corrupted boxes.

Rules:

- updates must never silently corrupt user data.
- migrations are idempotent.
- user data is never deleted without a recovery attempt.
- disposable API caches can be cleared after corruption.
- watch history, watchlist, downloads, settings, and auth sessions require explicit migration paths.
- downgrades are not guaranteed to be feature-compatible, but the app must avoid destroying newer user data.

## 19. Testing Strategy

Required test coverage before v1:

- unit tests for repositories.
- unit tests for Provider Registry and provider contracts.
- resolver tests for every provider.
- cache lifecycle tests.
- migration tests.
- widget tests for core screens.
- integration tests for playback handoff.
- download engine tests.
- watch party synchronization tests.
- authentication/session tests.
- Linux platform service tests with fakes.
- accessibility checks for keyboard/focus/semantics.
- packaging smoke tests.

Release validation:

- run `flutter analyze`.
- run `flutter test`.
- build Linux release.
- validate AppImage.
- validate Flatpak.
- validate DEB/RPM when those packages are in scope.
- smoke test on Ubuntu LTS, Fedora Workstation, and Arch Linux.
- smoke test on Wayland and X11.

## 20. Privacy And Telemetry

Policy:

- privacy-first defaults.
- no analytics by default.
- no silent crash uploads.
- telemetry must be opt-in.
- crash reporting must be opt-in.
- local logs remain local unless user exports them.
- disclose network services used: TMDB, AniList, Firebase, Firestore, Supabase, and provider endpoints.
- disclose what data is synced when login is enabled.

## 21. Technology Decisions

| Subsystem | Decision | Technology | Reason |
| --- | --- | --- | --- |
| Desktop architecture | Keep | Controller + Repository | Existing Desktop architecture is cleaner for Linux and avoids Android platform coupling. |
| Playback | Keep/extend | `media_kit` + libmpv | Best fit for Linux native playback, direct media, subtitles, tracks, diagnostics, and hardware acceleration. |
| Iframe playback | Adapt | WebKitGTK fallback | Required only for providers that cannot expose direct streams. |
| Provider selection | Adapt | Provider Registry | Preserves Android behavior while making Desktop providers testable and maintainable. |
| TMDB | Keep | TMDB API | Android source of truth for movie/TV metadata. |
| AniList | Keep | AniList GraphQL | Android source of truth for anime discovery/metadata. |
| Episode metadata | Keep/adapt | TMDB + AniZip + AniList fallback | Mirrors Android TV/anime episode pipeline. |
| Local persistence | Keep | Hive + SharedPreferences where appropriate | Matches Android persistence concepts and existing Desktop foundation. |
| API cache | Adapt | Hive cache contract | Desktop must add Android-equivalent TTL/SWR behavior. |
| Authentication | Replace SDK approach | Firebase Auth REST + Firestore REST + browser OAuth | Avoids FlutterFire Linux dependency and preserves Firebase behavior. |
| Secure storage | Adapt | Secret Service via PlatformService | Native Linux token storage. |
| Watch Party | Keep/adapt | Supabase realtime | Android behavior source with Desktop service/UI implementation. |
| Downloads | Replace platform service | Linux download engine + FFmpeg | Android DownloadService has Android-only dependencies. |
| Notifications | Replace | DBus/freedesktop notifications via PlatformService | Native Linux notification behavior. |
| Media keys | Extend | MPRIS/DBus via PlatformService | Native desktop integration. |
| File picker | Adapt | XDG portals/native file picker via PlatformService | Required for sandbox and native desktop behavior. |
| WebKitGTK | Limited use | WebView fallback | Not needed for direct playback; only iframe providers. |
| Shorebird | Remove for Desktop | Package updates | Android OTA does not fit Linux package distribution. |
| Cronet | Replace | Dio/libmpv headers/provider-specific fallback | Android networking dependency not appropriate for Linux. |
| FFmpegKit | Replace | system/bundled FFmpeg | FFmpegKit is mobile-oriented; Linux packaging needs explicit binary policy. |

## 22. Final Roadmap

The remaining roadmap is frozen in this order because it minimizes rework:

1. 22.5 Watch Party Completion.
2. 22.6 Playback & Streaming Completion.
3. 22.7 Download Engine.
4. 22.8 Linux Platform Integration.
5. 22.9 Authentication & Cloud Sync.
6. 23 Desktop DXR.
7. 24 Performance & Optimization.
8. 25 Packaging & Distribution.
9. 26 Final QA & Release.
10. v1.0.0.

Dependency notes:

- Watch Party completion depends on the current shared party model and player routing.
- Playback must land before downloads because downloads depend on resolved streams and provider contracts.
- Downloads should land before platform integration is finalized so notification and power-inhibit requirements are concrete.
- Platform integration should land before authentication because Secret Service and URI handling are auth dependencies.
- Authentication/cloud sync should land after local-first repositories are stable.
- DXR must not redesign behavior; it may refine visuals and ergonomics only.
- Packaging waits until runtime dependencies and platform integrations are known.
- Final QA validates every Tier 1 distribution, Wayland/X11, packaging format, migration, and recovery path.

## 23. Release Validation Checklist

- [ ] Fresh install.
- [ ] Upgrade install.
- [ ] Downgrade compatibility.
- [ ] Offline startup.
- [ ] Cache corruption recovery.
- [ ] Hive recovery.
- [ ] Missing `.env`.
- [ ] Expired authentication.
- [ ] Invalid provider.
- [ ] Failed stream fallback.
- [ ] Download resume.
- [ ] Watch Party recovery.
- [ ] Wayland.
- [ ] X11.
- [ ] Intel GPU.
- [ ] AMD GPU.
- [ ] NVIDIA GPU.
- [ ] AppImage.
- [ ] Flatpak.
- [ ] DEB.
- [ ] RPM.

## 24. Production Readiness Checklist

| Subsystem | Status | Notes |
| --- | --- | --- |
| Home | Needs implementation | Core structure exists; Android parity still incomplete. |
| Search | Needs implementation | Must preserve Android merge/filter/pagination behavior. |
| Details | Needs implementation | Episode metadata pipeline must mirror Android. |
| Player | Needs implementation | Foundation exists; provider registry, diagnostics, and full controls remain. |
| Movies | Needs implementation | TMDB parity required. |
| Anime | Needs implementation | AniList/AniZip/provider parity required. |
| Live TV | Needs implementation | IPTV parsing/storage exists conceptually; full UX/playback remains. |
| Library | Needs implementation | Watchlist/history/download integration remains. |
| Downloads | Missing | Linux download engine required. |
| Party | Needs implementation | Supabase model exists; full Desktop UX/recovery remains. |
| Profile | Needs implementation | Auth/session-dependent behavior remains. |
| Settings | Needs implementation | Must cover playback, cache, provider, accessibility, and platform settings. |
| Authentication | Missing | Browser OAuth, REST auth, Secret Service, and sync remain. |
| Notifications | Missing | Must go through PlatformService. |
| Linux Integration | Missing | PlatformService required. |
| Packaging | Missing | AppImage/Flatpak/DEB/RPM release pipeline required. |
| Performance | Needs implementation | Diagnostics and budgets defined; optimization remains. |
| QA | Missing | Tier 1 validation and release checklist required. |

## 25. References

Local source references:

- Android app: `../lib/`.
- Desktop app: `./lib/`.
- Android architecture audit: `ARCHITECTURE_ANALYSIS.md`.
- Desktop implementation rules: `../DESKTOP_IMPLEMENTATION_GUIDELINES.md`.
- UX guidance: `DESKTOP_UX_GUIDELINES.md`.
- Feature map: `FEATURE_MAP.md`.
- Networking migration report: `NETWORKING_MIGRATION_REPORT.md`.
- Data layer report: `DATA_LAYER_REPORT.md`.

Upstream documentation references:

- media_kit package documentation: https://pub.dev/packages/media_kit
- MPV/libmpv manual: https://mpv.io/manual/stable/
- MPV license notes: https://github.com/mpv-player/mpv/blob/master/Copyright
- FFmpeg legal and distribution notes: https://ffmpeg.org/legal.html
- MPRIS specification: https://specifications.freedesktop.org/mpris-spec/latest/
- Desktop notifications specification: https://specifications.freedesktop.org/notification-spec/latest/
- Secret Service specification: https://specifications.freedesktop.org/secret-service/latest/
- XDG desktop portal FileChooser: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.FileChooser.html
- Flutter Linux deployment: https://docs.flutter.dev/deployment/linux
- AppImage documentation: https://docs.appimage.org/introduction/index.html
- Flatpak documentation: https://docs.flatpak.org/en/latest/
- Firebase Auth REST API: https://firebase.google.com/docs/reference/rest/auth

