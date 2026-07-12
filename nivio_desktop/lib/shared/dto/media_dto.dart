class MediaDto {
  final int id;
  final int? malId;
  final String title;
  final String type; // 'movie', 'tv', 'anime'
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final double voteAverage;
  final String? releaseDate;

  const MediaDto({
    required this.id,
    this.malId,
    required this.title,
    required this.type,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.voteAverage,
    this.releaseDate,
  });

  factory MediaDto.fromJson(Map<String, dynamic> json) {
    return MediaDto(
      id: json['id'] as int,
      malId: json['idMal'] as int?,
      title: json['title'] ?? json['name'] ?? '',
      type: json['media_type'] ?? 'unknown',
      posterPath: json['poster_path'] ?? json['coverImage']?['extraLarge'],
      backdropPath: json['backdrop_path'] ?? json['bannerImage'],
      overview: json['overview'] ?? json['description'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'] ?? json['first_air_date'],
    );
  }
}

class SearchResponseDto {
  final int page;
  final int totalPages;
  final int totalResults;
  final List<MediaDto> results;

  const SearchResponseDto({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    required this.results,
  });

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) {
    return SearchResponseDto(
      page: json['page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalResults: json['total_results'] as int? ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => MediaDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
