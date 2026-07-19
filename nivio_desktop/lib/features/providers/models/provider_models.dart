import '../../search/models/search_media_item.dart';

enum ProviderMediaType {
  tv,
  movie;

  String get tmdbValue => switch (this) {
    ProviderMediaType.tv => 'tv',
    ProviderMediaType.movie => 'movie',
  };

  String get label => switch (this) {
    ProviderMediaType.tv => 'TV Shows',
    ProviderMediaType.movie => 'Movies',
  };
}

class StreamingProviderItem {
  const StreamingProviderItem({
    required this.id,
    required this.name,
    this.logoPath,
  });

  final int id;
  final String name;
  final String? logoPath;
}

class ProviderContentSection {
  const ProviderContentSection({required this.title, required this.items});

  final String title;
  final List<SearchMediaItem> items;
}
