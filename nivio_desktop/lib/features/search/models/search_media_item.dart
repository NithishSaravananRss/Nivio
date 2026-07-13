enum SearchLanguageFilter { all, english, tamil, hindi, japanese, korean }

enum SearchMediaTypeFilter { all, movie, tv, anime }

enum SearchSortOption { defaultOrder, title, year, rating }

enum SearchViewMode { grid, list }

class SearchMediaItem {
  const SearchMediaItem({
    required this.id,
    required this.title,
    required this.year,
    required this.rating,
    required this.language,
    required this.mediaType,
    required this.provider,
    required this.genres,
    required this.posterLabel,
    required this.overview,
    required this.runtimeLabel,
    this.posterPath,
    this.backdropPath,
  });

  final String id;
  final String title;
  final int year;
  final double rating;
  final SearchLanguageFilter language;
  final SearchMediaTypeFilter mediaType;
  final String provider;
  final List<String> genres;
  final String posterLabel;
  final String overview;
  final String runtimeLabel;
  final String? posterPath;
  final String? backdropPath;

  String get yearLabel => year.toString();
  String get ratingLabel => rating.toStringAsFixed(1);
  String get mediaTypeLabel => switch (mediaType) {
    SearchMediaTypeFilter.movie => 'Movie',
    SearchMediaTypeFilter.tv => 'TV',
    SearchMediaTypeFilter.anime => 'Anime',
    SearchMediaTypeFilter.all => 'All',
  };

  String get languageLabel => switch (language) {
    SearchLanguageFilter.all => 'All',
    SearchLanguageFilter.english => 'English',
    SearchLanguageFilter.tamil => 'Tamil',
    SearchLanguageFilter.hindi => 'Hindi',
    SearchLanguageFilter.japanese => 'Japanese',
    SearchLanguageFilter.korean => 'Korean',
  };
}
