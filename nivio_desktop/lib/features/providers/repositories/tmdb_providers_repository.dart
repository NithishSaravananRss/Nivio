import '../../../core/constants/providers_data.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../shared/dto/media_dto.dart';
import '../../../shared/mappers/media_mapper.dart';
import '../../search/models/search_media_item.dart';
import '../models/provider_models.dart';
import 'providers_repository.dart';

class TmdbProvidersRepository implements ProvidersRepository {
  TmdbProvidersRepository({required this.client});

  final TmdbClient client;
  final Map<String, List<ProviderContentSection>> _cache = {};

  @override
  List<StreamingProviderItem> getProviders() {
    return allProviders
        .map(
          (provider) => StreamingProviderItem(
            id: (provider['id'] as num).toInt(),
            name: provider['name'] as String,
            logoPath: provider['logo_path'] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ProviderContentSection>> getProviderContent({
    required StreamingProviderItem provider,
    required ProviderMediaType mediaType,
  }) async {
    final cacheKey = '${provider.id}:${mediaType.tmdbValue}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final genres = _genreSections(mediaType);
    final responses = await Future.wait([
      _discover(provider: provider, mediaType: mediaType),
      for (final genre in genres)
        _discover(provider: provider, mediaType: mediaType, genreId: genre.id),
    ]);

    final sections = <ProviderContentSection>[
      ProviderContentSection(
        title: 'Popular ${mediaType.label} on ${provider.name.trim()}',
        items: responses.first,
      ),
      for (var i = 0; i < genres.length; i++)
        ProviderContentSection(title: genres[i].label, items: responses[i + 1]),
    ].where((section) => section.items.isNotEmpty).toList(growable: false);

    _cache[cacheKey] = sections;
    return sections;
  }

  Future<List<SearchMediaItem>> _discover({
    required StreamingProviderItem provider,
    required ProviderMediaType mediaType,
    int? genreId,
  }) async {
    final response = await client.discover(mediaType.tmdbValue, {
      'language': 'en',
      'page': 1,
      'include_adult': false,
      'sort_by': 'popularity.desc',
      'watch_region': 'US',
      'with_watch_providers': provider.id,
      if (mediaType == ProviderMediaType.movie) 'include_video': false,
      'with_genres': ?genreId,
    });

    final searchResponse = SearchResponseDto.fromJson(response);
    final seen = <String>{};
    return searchResponse.results
        .map(
          (dto) => MediaDto(
            id: dto.id,
            malId: dto.malId,
            title: dto.title,
            type: mediaType.tmdbValue,
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            overview: dto.overview,
            voteAverage: dto.voteAverage,
            releaseDate: dto.releaseDate,
            originalLanguage: dto.originalLanguage,
          ),
        )
        .map(MediaMapper.toSearchMediaItem)
        .where((item) => item.title.trim().isNotEmpty && seen.add(item.id))
        .map((item) => _withProvider(item, provider.name.trim()))
        .toList(growable: false);
  }

  SearchMediaItem _withProvider(SearchMediaItem item, String providerName) {
    return SearchMediaItem(
      id: item.id,
      title: item.title,
      year: item.year,
      rating: item.rating,
      language: item.language,
      mediaType: item.mediaType,
      provider: providerName,
      genres: item.genres,
      posterLabel: item.posterLabel,
      overview: item.overview,
      runtimeLabel: item.runtimeLabel,
      posterPath: item.posterPath,
      backdropPath: item.backdropPath,
    );
  }

  List<_ProviderGenre> _genreSections(ProviderMediaType mediaType) {
    return switch (mediaType) {
      ProviderMediaType.movie => const [
        _ProviderGenre(28, 'Action & Thrillers'),
        _ProviderGenre(10749, 'Romance Movies'),
        _ProviderGenre(35, 'Comedy Movies'),
        _ProviderGenre(16, 'Animation'),
      ],
      ProviderMediaType.tv => const [
        _ProviderGenre(10759, 'Action & Adventure'),
        _ProviderGenre(18, 'Drama'),
        _ProviderGenre(10765, 'Sci-Fi & Fantasy'),
        _ProviderGenre(16, 'Animation'),
      ],
    };
  }
}

class _ProviderGenre {
  const _ProviderGenre(this.id, this.label);

  final int id;
  final String label;
}
