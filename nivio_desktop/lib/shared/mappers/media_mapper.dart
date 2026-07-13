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
      language: SearchLanguageFilter.all, // Should map from language code later if needed
      mediaType: typeFilter,
      provider: 'N/A', // Will be enriched by watch providers
      genres: const [], // To be added based on genre IDs
      posterLabel: dto.title,
      overview: dto.overview,
      runtimeLabel: '',
    );
  }
}
