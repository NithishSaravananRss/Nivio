import '../models/detail_models.dart';

final Map<String, DetailMedia> mockDetailCatalog = {
  for (final media in _items) media.id: media,
  for (final media in _items) media.title.toLowerCase(): media,
};

DetailMedia detailForId(String id) {
  return mockDetailCatalog[id] ??
      mockDetailCatalog[id.toLowerCase()] ??
      _items.first;
}

const _defaultCast = [
  DetailPerson(name: 'Mira Vale', role: 'Ari Lane'),
  DetailPerson(name: 'Jon Kade', role: 'Rook'),
  DetailPerson(name: 'Sara Imani', role: 'Nox'),
  DetailPerson(name: 'Dev Rao', role: 'Orin'),
  DetailPerson(name: 'Lena Cross', role: 'Captain Hale'),
  DetailPerson(name: 'Kai Mercer', role: 'Echo'),
];

const _defaultCrew = DetailCrew(
  director: 'N. Varma',
  writer: 'Ira Chen',
  producer: 'M. Solace',
  composer: 'Ada Voss',
  editor: 'Rin Patel',
  production: 'Nivio Originals',
);

const _related = [
  DetailPosterItem(
    id: 'signal-lost',
    title: 'Signal Lost',
    year: '2026',
    rating: '8.4',
    subtitle: 'Action · Drama',
  ),
  DetailPosterItem(
    id: 'midnight-harbor',
    title: 'Midnight Harbor',
    year: '2025',
    rating: '7.9',
    subtitle: 'Mystery · Thriller',
  ),
  DetailPosterItem(
    id: 'zero-day',
    title: 'Zero Day',
    year: '2026',
    rating: '8.1',
    subtitle: 'Sci-Fi · Action',
  ),
  DetailPosterItem(
    id: 'sky-forge',
    title: 'Sky Forge',
    year: '2026',
    rating: '9.0',
    subtitle: 'Anime · Action',
  ),
];

const _seasons = [
  DetailSeason(
    number: 1,
    name: 'Season 1',
    episodes: [
      DetailEpisode(
        number: 1,
        title: 'Pilot Signal',
        runtime: '48m',
        overview:
            'A missing broadcast pulls the crew into a city-wide conspiracy.',
        progress: 1,
        status: 'Watched',
      ),
      DetailEpisode(
        number: 2,
        title: 'Dead Drop',
        runtime: '51m',
        overview:
            'The trail leads to an abandoned relay station under lockdown.',
        progress: 0.62,
        status: 'In Progress',
      ),
      DetailEpisode(
        number: 3,
        title: 'Cold Channel',
        runtime: '46m',
        overview:
            'Old allies return as the signal begins rewriting public feeds.',
        progress: 0,
        status: 'Unwatched',
      ),
    ],
  ),
  DetailSeason(
    number: 2,
    name: 'Season 2',
    episodes: [
      DetailEpisode(
        number: 1,
        title: 'Afterimage',
        runtime: '49m',
        overview: 'A hidden archive exposes what happened after the blackout.',
        progress: 0,
        status: 'Unwatched',
      ),
      DetailEpisode(
        number: 2,
        title: 'Mirror Port',
        runtime: '52m',
        overview:
            'The team crosses into a port where everyone has a duplicate.',
        progress: 0,
        status: 'Unwatched',
      ),
    ],
  ),
];

final _items = [
  DetailMedia(
    id: 'blackout-city',
    title: 'Blackout City',
    originalTitle: 'Blackout City',
    mediaType: DetailMediaType.movie,
    releaseYear: '2026',
    releaseDate: '2026-07-12',
    runtime: '2h 18m',
    certification: 'TV-MA',
    rating: 8.6,
    voteCount: 18420,
    popularity: 91.4,
    genres: ['Action', 'Sci-Fi', 'Thriller'],
    overview:
        'A damaged ex-courier crosses a neon city to deliver a memory vault that every faction wants, while an old promise pulls him back into the frame.',
    tagline: 'Every memory has a price.',
    providers: ['Netflix', 'Prime Video'],
    languages: ['English', 'Tamil', 'Hindi'],
    audioTracks: ['English 5.1', 'Tamil Stereo'],
    subtitleTracks: ['English CC', 'Tamil', 'Hindi'],
    productionCompanies: ['Nivio Pictures', 'Northline Studios'],
    countries: ['United States', 'India'],
    status: 'Released',
    cast: _defaultCast,
    crew: _defaultCrew,
    related: _related,
    moreLikeThis: _related,
    resumeProgress: 0.36,
    isInWatchlist: true,
  ),
  DetailMedia(
    id: 'night-protocol',
    title: 'Night Protocol',
    mediaType: DetailMediaType.tv,
    releaseYear: '2026',
    releaseDate: '2026-01-15',
    runtime: '48m',
    certification: 'TV-14',
    rating: 8.5,
    voteCount: 9310,
    popularity: 87.2,
    genres: ['Crime', 'Drama', 'Thriller'],
    overview:
        'A covert response unit investigates crimes that only happen after midnight.',
    tagline: 'The city changes after dark.',
    providers: ['Disney+', 'Hulu'],
    languages: ['English', 'Hindi'],
    audioTracks: ['English 5.1', 'Hindi Stereo'],
    subtitleTracks: ['English CC', 'Hindi'],
    productionCompanies: ['Harborline TV'],
    countries: ['United States'],
    status: 'Returning Series',
    cast: _defaultCast,
    crew: _defaultCrew,
    related: _related,
    moreLikeThis: _related,
    seasons: _seasons,
    resumeProgress: 0.62,
    isInWatchlist: false,
  ),
  DetailMedia(
    id: 'sky-forge',
    title: 'Sky Forge',
    originalTitle: 'Sora Forge',
    mediaType: DetailMediaType.anime,
    releaseYear: '2026',
    releaseDate: '2026-01-15',
    runtime: '24m',
    certification: 'TV-14',
    rating: 9.0,
    voteCount: 22740,
    popularity: 96.1,
    genres: ['Animation', 'Anime', 'Action'],
    overview:
        'A young engineer builds forbidden machines in a kingdom that worships the sky.',
    tagline: 'Build what the heavens fear.',
    providers: ['Crunchyroll'],
    languages: ['Japanese', 'English'],
    audioTracks: ['Japanese Stereo', 'English Dub'],
    subtitleTracks: ['English', 'Tamil'],
    productionCompanies: ['Studio Horizon'],
    countries: ['Japan'],
    status: 'Returning Series',
    cast: _defaultCast,
    crew: _defaultCrew,
    related: _related,
    moreLikeThis: _related,
    seasons: _seasons,
    resumeProgress: 0.18,
    isInWatchlist: true,
  ),
  for (final item in _related)
    DetailMedia(
      id: item.id,
      title: item.title,
      mediaType: item.subtitle.contains('Anime')
          ? DetailMediaType.anime
          : item.subtitle.contains('TV')
          ? DetailMediaType.tv
          : DetailMediaType.movie,
      releaseYear: item.year,
      releaseDate: '${item.year}-07-12',
      runtime: item.subtitle.contains('TV') || item.subtitle.contains('Anime')
          ? '46m'
          : '1h 56m',
      certification: 'TV-14',
      rating: double.parse(item.rating),
      voteCount: 7240,
      popularity: 72.0,
      genres: item.subtitle.split(' · '),
      overview: '${item.title} is part of the current mock desktop catalog.',
      tagline: 'A Nivio catalog title.',
      providers: ['Netflix'],
      languages: ['English'],
      audioTracks: ['English 5.1'],
      subtitleTracks: ['English CC'],
      productionCompanies: ['Nivio Studios'],
      countries: ['United States'],
      status: 'Released',
      cast: _defaultCast,
      crew: _defaultCrew,
      related: _related,
      moreLikeThis: _related,
      seasons: item.subtitle.contains('TV') || item.subtitle.contains('Anime')
          ? _seasons
          : const [],
    ),
];
