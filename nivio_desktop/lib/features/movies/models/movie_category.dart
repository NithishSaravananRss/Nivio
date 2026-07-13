enum MovieCategory {
  trending('Trending'),
  popular('Popular'),
  nowPlaying('Now Playing'),
  topRated('Top Rated'),
  upcoming('Upcoming');

  const MovieCategory(this.label);

  final String label;
}
