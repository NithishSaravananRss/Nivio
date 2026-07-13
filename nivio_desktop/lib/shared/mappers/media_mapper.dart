import '../dto/media_dto.dart';
import '../../features/search/models/search_media_item.dart';

class MediaMapper {
  static SearchMediaItem toSearchMediaItem(MediaDto dto) {
    int year = 0;
    if (dto.releaseDate != null && dto.releaseDate!.length >= 4) {
      year = int.tryParse(dto.releaseDate!.substring(0, 4)) ?? 0;
    }

    SearchMediaTypeFilter typeFilter = SearchMediaTypeFilter.all;
    if (dto.type == 'movie') typeFilter = SearchMediaTypeFilter.movie;
    if (dto.type == 'tv') typeFilter = SearchMediaTypeFilter.tv;
    if (dto.type == 'anime') typeFilter = SearchMediaTypeFilter.anime;

    return SearchMediaItem(
      id: '${dto.type}:${dto.id}',
      title: dto.title,
      year: year,
      rating: dto.voteAverage,
      language: _languageFromCode(dto.originalLanguage),
      mediaType: typeFilter,
      provider: 'N/A', // Will be enriched by watch providers
      genres: const [], // To be added based on genre IDs
      posterLabel: dto.title,
      overview: dto.overview,
      runtimeLabel: '',
      posterPath: dto.posterPath,
      backdropPath: dto.backdropPath,
    );
  }

  static SearchLanguageFilter _languageFromCode(String? code) {
    return switch (code) {
      'en' => SearchLanguageFilter.english,
      'ta' => SearchLanguageFilter.tamil,
      'te' => SearchLanguageFilter.telugu,
      'hi' => SearchLanguageFilter.hindi,
      'ko' => SearchLanguageFilter.korean,
      'ja' => SearchLanguageFilter.japanese,
      _ => SearchLanguageFilter.all,
    };
  }
}
