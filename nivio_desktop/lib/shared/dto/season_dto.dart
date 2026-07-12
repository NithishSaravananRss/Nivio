class EpisodeDto {
  final int id;
  final int episodeNumber;
  final String title;
  final String overview;
  final String? stillPath;
  final double voteAverage;
  final int? runtime;
  final String? airDate;

  const EpisodeDto({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.overview,
    this.stillPath,
    required this.voteAverage,
    this.runtime,
    this.airDate,
  });

  factory EpisodeDto.fromJson(Map<String, dynamic> json) {
    return EpisodeDto(
      id: json['id'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      title: json['name'] ?? json['title'] ?? 'Unknown',
      overview: json['overview'] ?? '',
      stillPath: json['still_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      runtime: json['runtime'] as int?,
      airDate: json['air_date'],
    );
  }
}

class SeasonDto {
  final int id;
  final int seasonNumber;
  final String title;
  final String? posterPath;
  final List<EpisodeDto> episodes;

  const SeasonDto({
    required this.id,
    required this.seasonNumber,
    required this.title,
    this.posterPath,
    required this.episodes,
  });

  factory SeasonDto.fromJson(Map<String, dynamic> json) {
    return SeasonDto(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      title: json['name'] ?? 'Season ${json['season_number']}',
      posterPath: json['poster_path'],
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => EpisodeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class SeriesInfoDto {
  final int id;
  final List<SeasonDto> seasons;
  final int numberOfSeasons;
  final int numberOfEpisodes;

  const SeriesInfoDto({
    required this.id,
    required this.seasons,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
  });

  factory SeriesInfoDto.fromJson(Map<String, dynamic> json) {
    return SeriesInfoDto(
      id: json['id'] as int? ?? 0,
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((e) => SeasonDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: json['number_of_episodes'] as int? ?? 0,
    );
  }
}
