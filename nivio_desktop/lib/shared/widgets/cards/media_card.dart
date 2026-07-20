import 'package:flutter/material.dart';

import '../../../core/network/image/tmdb_image_builder.dart';
import 'poster_card.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    this.mediaId,
    required this.title,
    this.imageProvider,
    this.previewImageProvider,
    this.posterPath,
    this.backdropPath,
    this.year,
    this.rating,
    this.subtitle,
    this.overview,
    this.onTap,
    this.onPlay,
    this.onWatchlist,
    this.isInWatchlist = false,
    this.onMore,
    this.progress,
  });

  final String? mediaId;
  final String title;
  final ImageProvider? imageProvider;
  final ImageProvider? previewImageProvider;
  final String? posterPath;
  final String? backdropPath;
  final String? year;
  final String? rating;
  final String? subtitle;
  final String? overview;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onWatchlist;
  final bool isInWatchlist;
  final VoidCallback? onMore;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final resolvedImage =
        imageProvider ??
        ((posterPath != null && posterPath!.isNotEmpty)
            ? NetworkImage(TmdbImageBuilder.poster(posterPath!))
            : null);
    final resolvedPreviewImage =
        previewImageProvider ??
        ((backdropPath != null && backdropPath!.isNotEmpty)
            ? NetworkImage(TmdbImageBuilder.backdrop(backdropPath!))
            : null);

    return PosterCard(
      mediaId: mediaId,
      title: title,
      imageProvider: resolvedImage,
      previewImageProvider: resolvedPreviewImage,
      year: year,
      rating: rating,
      subtitle: subtitle,
      overview: overview,
      onTap: onTap,
      onPlay: onPlay,
      onWatchlist: onWatchlist,
      isInWatchlist: isInWatchlist,
      onMore: onMore,
      progress: progress,
    );
  }
}
