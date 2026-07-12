# Data Foundation Report

## 1. Android Files Analyzed
- `tmdb_service.dart`
- `anilist_service.dart`
- `aniskip_service.dart`
- `theintrodb_service.dart`
- Models in `lib/models/` (`search_result.dart`, `season_info.dart`, etc.)

## 2. Safe Reusable Classes
- No Android services were 100% safe to reuse as-is because they relied on Riverpod caching, Hive DB logic, and sometimes mixed UI models into the raw service.
- The endpoints and request logic are safe to adapt.

## 3. Adapted Classes
- Extracted network calling code from `TmdbService` into a pure Dart `TmdbClient` in `lib/core/network/tmdb_client.dart`.
- Extracted `AniListService` logic into `AniListClient`.
- Extracted `AniSkipService` logic into `AniSkipClient`.
- Extracted `TheIntroDBService` logic into `TheIntroDbClient`.
- Created pure Dart DTOs instead of reusing Freezed / Hive generated models.
- Abstracted TMDB image URL building logic from `TmdbService` into `TmdbImageBuilder`.

## 4. Deferred Classes
- Repositories (will be built in the next phase).
- Caching logic (should use a Desktop-safe cache, deferring cache integration until repositories).
- Feature-specific UI mapping (deferred until providers are connected).

## 5. Folder Structure Created
- `lib/core/network/`
- `lib/core/network/image/`
- `lib/core/errors/`
- `lib/shared/dto/`
- `lib/shared/mappers/`

## 6. DTOs Created
- `MediaDto`, `SearchResponseDto` (`media_dto.dart`)
- `SeasonDto`, `EpisodeDto`, `SeriesInfoDto` (`season_dto.dart`)
- `SkipTimeDto` (`skip_time_dto.dart`)

## 7. Mappers Created
- `MediaMapper` (`media_mapper.dart`) - Maps `MediaDto` to Desktop `SearchMediaItem`.

## 8. Errors Created
- `AppNetworkError`, `NetworkError`, `TimeoutError`, `ApiError`, `ParsingError`, `UnknownError`
- `NetworkErrorMapper` to safely intercept `DioException` and convert it into typed errors without leaking raw Dio models to the UI.

## 9. Remaining Work before Repository Integration
- Wire up `Dio` interceptors for logging if needed.
- Write abstract repository interfaces.
- Create concrete repository implementations connecting these Clients to local caches (e.g., Hive or SQLite when ready).
- Wire repositories into the Desktop application's state management (e.g. Riverpod or Provider).
