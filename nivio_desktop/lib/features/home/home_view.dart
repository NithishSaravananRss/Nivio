import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/providers_data.dart';
import '../../core/network/image/tmdb_image_builder.dart';
import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import '../search/models/search_media_item.dart';
import 'controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.controller, this.onOpenDetail});

  final HomeController controller;
  final ValueChanged<String>? onOpenDetail;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();
  late final PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 0;
  bool _isHovering = false;
  Timer? _resumeAutoplayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _carouselTimer?.cancel();
    _resumeAutoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      if (_isHovering) return;
      if (!_pageController.hasClients) return;

      final items = widget.controller.featuredItems;
      if (items.isEmpty) return;

      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageUserInteraction() {
    _carouselTimer?.cancel();
    _resumeAutoplayTimer?.cancel();
    _resumeAutoplayTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        _startCarouselTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final featuredItems = ctrl.featuredItems;

        return DesktopScrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Dynamic Hero Carousel Section
                  SectionPadding(
                    vertical: AppSpacing.xxl,
                    child: ctrl.isLoadingFeatured
                        ? Container(
                            height: 400,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.panel,
                              ),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : featuredItems.isEmpty
                        ? const SizedBox.shrink()
                        : MouseRegion(
                            onEnter: (_) => setState(() => _isHovering = true),
                            onExit: (_) => setState(() => _isHovering = false),
                            child: Focus(
                              autofocus: true,
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowLeft) {
                                    _onPageUserInteraction();
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 1200,
                                      ),
                                      curve: Curves.easeInOutCubic,
                                    );
                                    return KeyEventResult.handled;
                                  } else if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowRight) {
                                    _onPageUserInteraction();
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 1200,
                                      ),
                                      curve: Curves.easeInOutCubic,
                                    );
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 400,
                                    child: PageView.builder(
                                      controller: _pageController,
                                      itemCount: featuredItems.length + 1,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentPage = index;
                                        });

                                        // Replicate Android loop jump back
                                        if (index == featuredItems.length) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (!_pageController
                                                    .hasClients) {
                                                  return;
                                                }
                                                _pageController.jumpToPage(0);
                                                setState(
                                                  () => _currentPage = 0,
                                                );
                                              });
                                        }
                                      },
                                      itemBuilder: (context, index) {
                                        final actualIndex =
                                            index % featuredItems.length;
                                        final item = featuredItems[actualIndex];

                                        return HeroBanner(
                                          item: item,
                                          primaryActionLabel: 'Play now',
                                          secondaryActionLabel:
                                              'Add to watchlist',
                                          onPrimaryAction: () => widget
                                              .onOpenDetail
                                              ?.call(item.id),
                                          onSecondaryAction: () {},
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Page Indicators
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      featuredItems.length,
                                      (index) {
                                        final isSelected =
                                            (_currentPage %
                                                featuredItems.length) ==
                                            index;
                                        return GestureDetector(
                                          onTap: () {
                                            _onPageUserInteraction();
                                            _pageController.animateToPage(
                                              index,
                                              duration: const Duration(
                                                milliseconds: 1200,
                                              ),
                                              curve: Curves.easeInOutCubic,
                                            );
                                          },
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textMuted
                                                        .withValues(alpha: 0.4),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  // 2. Continue Watching (Only visible if not empty)
                  SectionPadding(
                    child: _ContinueWatchingSection(
                      items: ctrl.watchHistory,
                      isLoading: ctrl.isLoadingHistory,
                      onOpenDetail: widget.onOpenDetail,
                    ),
                  ),

                  // 3. Trending Movies
                  SectionPadding(
                    child: _TrendingMoviesSection(
                      items: ctrl.trendingMovies,
                      isLoading: ctrl.isLoadingMovies,
                      error: ctrl.moviesError,
                      onRetry: () => ctrl.retryMovies(),
                      onOpenDetail: widget.onOpenDetail,
                    ),
                  ),
                  const SectionPadding(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),

                  // 4. Trending TV
                  SectionPadding(
                    child: _TrendingTvSection(
                      items: ctrl.trendingTv,
                      isLoading: ctrl.isLoadingTv,
                      error: ctrl.tvError,
                      onRetry: () => ctrl.retryTv(),
                      onOpenDetail: widget.onOpenDetail,
                    ),
                  ),
                  const SectionPadding(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),

                  // 5. Trending Anime (Hidden completely per Android parity)
                  const SectionPadding(child: _TrendingAnimeSection()),

                  // 6. Providers
                  const SectionPadding(child: _ProvidersSection()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection({
    required this.items,
    required this.isLoading,
    this.onOpenDetail,
  });

  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Continue Watching',
          subtitle: 'Pick up where you left off',
        ),
        const SizedBox(height: AppSpacing.lg),
        MediaRail(
          itemWidth: 360,
          height: 340,
          children: items.map((item) {
            final id = item['id']?.toString();
            final title = (item['title'] ?? item['name'] ?? 'Untitled')
                .toString();
            final season = item['currentSeason'] ?? item['season'];
            final episode = item['currentEpisode'] ?? item['episode'];
            final rawProgress =
                (item['progressPercent'] as num?)?.toDouble() ??
                (item['progress'] as num?)?.toDouble() ??
                0;
            final progress = rawProgress > 1 ? rawProgress / 100 : rawProgress;
            final episodeLabel = season != null && episode != null
                ? 'Season $season · Episode $episode'
                : null;

            return ContinueWatchingCard(
              title: title,
              episodeLabel: episodeLabel,
              posterLabel: title,
              progress: progress,
              onResume: id == null ? null : () => onOpenDetail?.call(id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TrendingMoviesSection extends StatelessWidget {
  const _TrendingMoviesSection({
    required this.items,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.onOpenDetail,
  });

  final List<SearchMediaItem> items;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (error != null && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Trending Movies', onSeeAllPressed: _noop),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
                const SizedBox(height: AppSpacing.md),
                SelectableText(
                  error!,
                  style: const TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(label: 'Retry', onPressed: onRetry),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Trending Movies', onSeeAllPressed: _noop),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveGrid(
          minItemWidth: 170,
          childAspectRatio: 0.66,
          children: isLoading
              ? List.generate(
                  6,
                  (index) => const PosterCard(title: '', isLoading: true),
                )
              : items
                    .map(
                      (item) => PosterCard(
                        title: item.title,
                        year: item.year > 0 ? item.yearLabel : null,
                        rating: item.rating > 0 ? item.ratingLabel : null,
                        subtitle: item.mediaTypeLabel,
                        imageProvider:
                            item.posterPath != null &&
                                item.posterPath!.isNotEmpty
                            ? NetworkImage(
                                TmdbImageBuilder.poster(item.posterPath!),
                              )
                            : null,
                        onTap: () => onOpenDetail?.call(item.id),
                        onSecondaryTap: () => onOpenDetail?.call(item.id),
                        onPlay: () => onOpenDetail?.call(item.id),
                        onWatchlist: _noop,
                        onMore: () => onOpenDetail?.call(item.id),
                      ),
                    )
                    .toList(),
        ),
      ],
    );
  }
}

class _TrendingTvSection extends StatelessWidget {
  const _TrendingTvSection({
    required this.items,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.onOpenDetail,
  });

  final List<SearchMediaItem> items;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (error != null && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Trending TV', onSeeAllPressed: _noop),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
                const SizedBox(height: AppSpacing.md),
                SelectableText(
                  error!,
                  style: const TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(label: 'Retry', onPressed: onRetry),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Trending TV', onSeeAllPressed: _noop),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveGrid(
          minItemWidth: 170,
          childAspectRatio: 0.66,
          children: isLoading
              ? List.generate(
                  6,
                  (index) => const PosterCard(title: '', isLoading: true),
                )
              : items
                    .map(
                      (item) => PosterCard(
                        title: item.title,
                        year: item.year > 0 ? item.yearLabel : null,
                        rating: item.rating > 0 ? item.ratingLabel : null,
                        subtitle: item.mediaTypeLabel,
                        imageProvider:
                            item.posterPath != null &&
                                item.posterPath!.isNotEmpty
                            ? NetworkImage(
                                TmdbImageBuilder.poster(item.posterPath!),
                              )
                            : null,
                        onTap: () => onOpenDetail?.call(item.id),
                        onSecondaryTap: () => onOpenDetail?.call(item.id),
                        onPlay: () => onOpenDetail?.call(item.id),
                        onWatchlist: _noop,
                        onMore: () => onOpenDetail?.call(item.id),
                      ),
                    )
                    .toList(),
        ),
      ],
    );
  }
}

class _TrendingAnimeSection extends StatelessWidget {
  const _TrendingAnimeSection();

  @override
  Widget build(BuildContext context) {
    // Hide completely until implemented per Android parity guidelines
    return const SizedBox.shrink();
  }
}

class _ProvidersSection extends StatelessWidget {
  const _ProvidersSection();

  @override
  Widget build(BuildContext context) {
    final providers = allProviders.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Studios', onSeeAllPressed: _noop),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveGrid(
          minItemWidth: 150,
          childAspectRatio: 0.9,
          children: providers.map((provider) {
            final logoPath = provider['logo_path'] as String?;
            final name = provider['name'] as String;
            return ProviderCard(
              name: name,
              logoImage: logoPath != null
                  ? NetworkImage(TmdbImageBuilder.logo(logoPath))
                  : null,
              onTap: () {},
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

void _noop() {}
