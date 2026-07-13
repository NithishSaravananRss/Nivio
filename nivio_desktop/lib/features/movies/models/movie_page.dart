import '../../search/models/search_media_item.dart';

class MoviePage {
  const MoviePage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<SearchMediaItem> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
