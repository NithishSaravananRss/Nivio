import 'package:flutter/material.dart';

import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import '../search/models/search_media_item.dart';
import '../player/models/playback_request.dart';
import '../player/playback_request_factory.dart';
import 'controllers/movies_controller.dart';
import 'models/movie_category.dart';
import 'models/movie_genre.dart';

class MoviesView extends StatefulWidget {
  const MoviesView({
    super.key,
    required this.controller,
    this.onOpenDetail,
    this.onPlay,
  });

  final MoviesController controller;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

  @override
  State<MoviesView> createState() => _MoviesViewState();
}

class _MoviesViewState extends State<MoviesView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.controller.scrollOffset,
    )..addListener(_handleScroll);
    widget.controller.initialize();
  }

  @override
  void didUpdateWidget(covariant MoviesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _scrollController.jumpTo(widget.controller.scrollOffset);
      oldWidget.controller.saveScrollOffset(_scrollController.offset);
      widget.controller.initialize();
    }
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) {
      widget.controller.saveScrollOffset(_scrollController.offset);
    }
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    widget.controller.saveScrollOffset(_scrollController.offset);
    final position = _scrollController.position;
    if (position.extentAfter < 720) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return DesktopScrollbar(
          controller: _scrollController,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: PageContainer(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xxl,
                      bottom: AppSpacing.lg,
                    ),
                    child: _MoviesHeader(controller: widget.controller),
                  ),
                ),
              ),
              _buildContent(),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.massive),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final controller = widget.controller;

    if (controller.isInitialLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        sliver: _SkeletonGrid(),
      );
    }

    if (controller.status == MoviesStatus.offline) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: NetworkErrorView(onRetry: controller.retry),
      );
    }

    if (controller.status == MoviesStatus.apiError ||
        controller.status == MoviesStatus.error) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          title: 'Movies unavailable',
          message:
              controller.errorMessage ?? 'We could not load movies right now.',
          onRetry: controller.retry,
        ),
      );
    }

    if (controller.status == MoviesStatus.empty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          title: 'No movies found',
          message: 'Try another category or genre.',
        ),
      );
    }

    final itemCount =
        controller.movies.length + (controller.isLoadingMore ? 6 : 0);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 190,
          mainAxisSpacing: AppSpacing.xl,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: AppBreakpoints.posterRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= controller.movies.length) {
            return const PosterSkeleton();
          }

          return _MovieGridCard(
            item: controller.movies[index],
            onOpenDetail: widget.onOpenDetail,
            onPlay: widget.onPlay,
          );
        },
      ),
    );
  }
}

class _MoviesHeader extends StatelessWidget {
  const _MoviesHeader({required this.controller});

  final MoviesController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Movies', style: AppTypography.pageTitle),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final category in MovieCategory.values)
              ChoiceChip(
                label: Text(category.label),
                selected: controller.selectedCategory == category,
                onSelected: (_) => controller.selectCategory(category),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _GenreSelector(controller: controller),
      ],
    );
  }
}

class _GenreSelector extends StatelessWidget {
  const _GenreSelector({required this.controller});

  final MoviesController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingGenres && controller.genres.isEmpty) {
      return Text(
        'Loading genres...',
        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
      );
    }

    if (controller.genreError != null && controller.genres.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.genreError!,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: controller.loadGenres,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    final genres = <MovieGenre?>[null, ...controller.genres];
    return DropdownButton<MovieGenre?>(
      value: controller.selectedGenre,
      hint: const Text('All genres'),
      items: [
        for (final genre in genres)
          DropdownMenuItem<MovieGenre?>(
            value: genre,
            child: Text(genre?.name ?? 'All genres'),
          ),
      ],
      onChanged: controller.selectGenre,
    );
  }
}

class _MovieGridCard extends StatelessWidget {
  const _MovieGridCard({required this.item, this.onOpenDetail, this.onPlay});

  final SearchMediaItem item;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      mediaId: item.id,
      title: item.title,
      posterPath: item.posterPath,
      backdropPath: item.backdropPath,
      year: item.year > 0 ? item.yearLabel : null,
      rating: item.rating > 0 ? item.ratingLabel : null,
      subtitle: item.mediaTypeLabel,
      overview: item.overview,
      onTap: () => onOpenDetail?.call(item.id),
      onPlay: () => onPlay?.call(PlaybackRequestFactory.fromSearchItem(item)),
      onMore: () => onOpenDetail?.call(item.id),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: AppSpacing.xl,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: AppBreakpoints.posterRatio,
      ),
      itemCount: 18,
      itemBuilder: (context, index) => const PosterSkeleton(),
    );
  }
}
