class DetailMedia {
  const DetailMedia({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.mediaType,
    required this.releaseYear,
    required this.releaseDate,
    required this.runtime,
    required this.certification,
    required this.rating,
    required this.voteCount,
    required this.popularity,
    required this.genres,
    required this.overview,
    required this.tagline,
    required this.providers,
    required this.languages,
    required this.audioTracks,
    required this.subtitleTracks,
    required this.productionCompanies,
    required this.countries,
    required this.status,
    required this.cast,
    required this.crew,
    required this.related,
    required this.moreLikeThis,
    this.seasons = const [],
    this.resumeProgress = 0,
    this.isInWatchlist = false,
  });

  final String id;
  final String title;
  final String? originalTitle;
  final DetailMediaType mediaType;
  final String releaseYear;
  final String releaseDate;
  final String runtime;
  final String certification;
  final double rating;
  final int voteCount;
  final double popularity;
  final List<String> genres;
  final String overview;
  final String tagline;
  final List<String> providers;
  final List<String> languages;
  final List<String> audioTracks;
  final List<String> subtitleTracks;
  final List<String> productionCompanies;
  final List<String> countries;
  final String status;
  final List<DetailPerson> cast;
  final DetailCrew crew;
  final List<DetailPosterItem> related;
  final List<DetailPosterItem> moreLikeThis;
  final List<DetailSeason> seasons;
  final double resumeProgress;
  final bool isInWatchlist;

  bool get isSeries =>
      mediaType == DetailMediaType.tv || mediaType == DetailMediaType.anime;

  DetailMedia copyWith({bool? isInWatchlist}) {
    return DetailMedia(
      id: id,
      title: title,
      originalTitle: originalTitle,
      mediaType: mediaType,
      releaseYear: releaseYear,
      releaseDate: releaseDate,
      runtime: runtime,
      certification: certification,
      rating: rating,
      voteCount: voteCount,
      popularity: popularity,
      genres: genres,
      overview: overview,
      tagline: tagline,
      providers: providers,
      languages: languages,
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
      productionCompanies: productionCompanies,
      countries: countries,
      status: status,
      cast: cast,
      crew: crew,
      related: related,
      moreLikeThis: moreLikeThis,
      seasons: seasons,
      resumeProgress: resumeProgress,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
    );
  }
}

enum DetailMediaType { movie, tv, anime, live }

extension DetailMediaTypeLabel on DetailMediaType {
  String get label => switch (this) {
    DetailMediaType.movie => 'Movie',
    DetailMediaType.tv => 'TV',
    DetailMediaType.anime => 'Anime',
    DetailMediaType.live => 'Live',
  };
}

class DetailSeason {
  const DetailSeason({
    required this.number,
    required this.name,
    required this.episodes,
  });

  final int number;
  final String name;
  final List<DetailEpisode> episodes;
}

class DetailEpisode {
  const DetailEpisode({
    required this.number,
    required this.title,
    required this.runtime,
    required this.overview,
    required this.progress,
    required this.status,
  });

  final int number;
  final String title;
  final String runtime;
  final String overview;
  final double progress;
  final String status;
}

class DetailPerson {
  const DetailPerson({required this.name, required this.role});

  final String name;
  final String role;
}

class DetailCrew {
  const DetailCrew({
    required this.director,
    required this.writer,
    required this.producer,
    required this.composer,
    required this.editor,
    required this.production,
  });

  final String director;
  final String writer;
  final String producer;
  final String composer;
  final String editor;
  final String production;
}

class DetailPosterItem {
  const DetailPosterItem({
    required this.id,
    required this.title,
    required this.year,
    required this.rating,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String year;
  final String rating;
  final String subtitle;
}
