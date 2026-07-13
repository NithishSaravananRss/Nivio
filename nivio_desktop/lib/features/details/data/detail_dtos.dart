class DetailDto {
  final Map<String, dynamic> raw;

  const DetailDto(this.raw);

  int get id => raw['id'] as int? ?? 0;
  String get title => (raw['title'] ?? raw['name'] ?? '') as String;
  String? get originalTitle => (raw['original_title'] ?? raw['original_name']) as String?;
  String? get overview => raw['overview'] as String?;
  String? get releaseDate => (raw['release_date'] ?? raw['first_air_date']) as String?;
  int? get runtime => raw['runtime'] as int? ?? (raw['episode_run_time'] is List && (raw['episode_run_time'] as List).isNotEmpty ? (raw['episode_run_time'] as List).first as int : null);
  double get voteAverage => (raw['vote_average'] as num? ?? 0).toDouble();
  int get voteCount => raw['vote_count'] as int? ?? 0;
  double get popularity => (raw['popularity'] as num? ?? 0).toDouble();
  String? get tagline => raw['tagline'] as String?;
  String? get status => raw['status'] as String?;
  String? get posterPath => raw['poster_path'] as String?;
  String? get backdropPath => raw['backdrop_path'] as String?;
  String? get type => raw['type'] as String?;

  List<String> get genres => (raw['genres'] as List? ?? [])
      .map((g) => g is Map ? g['name'] as String? : null)
      .whereType<String>()
      .toList();

  Map<String, dynamic>? get belongsToCollection =>
      raw['belongs_to_collection'] as Map<String, dynamic>?;

  List<String> get productionCompanies => (raw['production_companies'] as List? ?? [])
      .map((c) => c is Map ? c['name'] as String? : null)
      .whereType<String>()
      .toList();

  List<String> get productionCountries => (raw['production_countries'] as List? ?? [])
      .map((c) => c is Map ? c['name'] as String? : null)
      .whereType<String>()
      .toList();

  List<String> get spokenLanguages => (raw['spoken_languages'] as List? ?? [])
      .map((l) => l is Map ? l['name'] as String? : null)
      .whereType<String>()
      .toList();

  List<String> get originCountry => (raw['origin_country'] as List? ?? [])
      .whereType<String>()
      .toList();

  List<String> get createdBy => (raw['created_by'] as List? ?? [])
      .map((c) => c is Map ? c['name'] as String? : null)
      .whereType<String>()
      .toList();

  List<String> get networks => (raw['networks'] as List? ?? [])
      .map((n) => n is Map ? n['name'] as String? : null)
      .whereType<String>()
      .toList();

  String? get homepage => raw['homepage'] as String?;
  String? get imdbId => raw['imdb_id'] as String?;

  // Seasons info (for TV shows)
  List<Map<String, dynamic>> get seasons => (raw['seasons'] as List? ?? [])
      .map((s) => s is Map ? Map<String, dynamic>.from(s) : null)
      .whereType<Map<String, dynamic>>()
      .toList();
}

class CreditsDto {
  final Map<String, dynamic> raw;

  const CreditsDto(this.raw);

  List<Map<String, dynamic>> get cast => (raw['cast'] as List? ?? [])
      .map((c) => c is Map ? Map<String, dynamic>.from(c) : null)
      .whereType<Map<String, dynamic>>()
      .toList();

  List<Map<String, dynamic>> get crew => (raw['crew'] as List? ?? [])
      .map((c) => c is Map ? Map<String, dynamic>.from(c) : null)
      .whereType<Map<String, dynamic>>()
      .toList();
}

class VideosDto {
  final Map<String, dynamic> raw;

  const VideosDto(this.raw);

  List<Map<String, dynamic>> get results => (raw['results'] as List? ?? [])
      .map((v) => v is Map ? Map<String, dynamic>.from(v) : null)
      .whereType<Map<String, dynamic>>()
      .toList();
}

class ProvidersDto {
  final Map<String, dynamic> raw;

  const ProvidersDto(this.raw);

  Map<String, dynamic> get results => Map<String, dynamic>.from(raw['results'] ?? {});
}

class ImagesDto {
  final Map<String, dynamic> raw;

  const ImagesDto(this.raw);

  List<Map<String, dynamic>> get backdrops => (raw['backdrops'] as List? ?? [])
      .map((i) => i is Map ? Map<String, dynamic>.from(i) : null)
      .whereType<Map<String, dynamic>>()
      .toList();

  List<Map<String, dynamic>> get posters => (raw['posters'] as List? ?? [])
      .map((i) => i is Map ? Map<String, dynamic>.from(i) : null)
      .whereType<Map<String, dynamic>>()
      .toList();

  List<Map<String, dynamic>> get logos => (raw['logos'] as List? ?? [])
      .map((i) => i is Map ? Map<String, dynamic>.from(i) : null)
      .whereType<Map<String, dynamic>>()
      .toList();
}
