/// Utility class for generating TMDB image URLs.
class TmdbImageBuilder {
  static const String _baseUrl = 'https://image.tmdb.org/t/p/';

  static String poster(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseUrl$size$path';
  }

  static String backdrop(String? path, {String size = 'w780'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseUrl$size$path';
  }

  static String profile(String? path, {String size = 'w185'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseUrl$size$path';
  }

  static String still(String? path, {String size = 'w300'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseUrl$size$path';
  }

  static String logo(String? path, {String size = 'w154'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseUrl$size$path';
  }
}
