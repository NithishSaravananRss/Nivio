import '../models/movie_category.dart';
import '../models/movie_genre.dart';
import '../models/movie_page.dart';

abstract class MoviesRepository {
  Future<List<MovieGenre>> getGenres();

  Future<MoviePage> getMovies({
    required MovieCategory category,
    int? genreId,
    int page = 1,
  });
}
