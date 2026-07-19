import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/providers_data.dart';
import '../../core/network/image/tmdb_image_builder.dart';
import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import '../library/services/watchlist_sync_controller.dart';
import '../player/models/playback_request.dart';
import '../player/playback_request_factory.dart';
import '../providers/models/provider_models.dart';
import '../search/models/search_media_item.dart';
import 'controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.controller,
    this.onOpenDetail,
    this.onPlay,
    this.onOpenAllProviders,
    this.onOpenProvider,
  });

  final HomeController controller;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;
  final VoidCallback? onOpenAllProviders;
  final ValueChanged<StreamingProviderItem>? onOpenProvider;

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

                                        final watchlist =
                                            WatchlistSyncController.instance;
                                        return ListenableBuilder(
                                          listenable: watchlist,
                                          builder: (context, _) {
                                            final isInWatchlist = watchlist
                                                .isInWatchlist(item.id);
                                            return HeroBanner(
                                              item: item,
                                              primaryActionLabel: 'Play now',
                                              secondaryActionLabel:
                                                  isInWatchlist
                                                  ? 'In watchlist'
                                                  : 'Add to watchlist',
                                              onPrimaryAction: () =>
                                                  widget.onPlay?.call(
                                                    PlaybackRequestFactory.fromSearchItem(
                                                      item,
                                                    ),
                                                  ),
                                              onSecondaryAction: () => watchlist
                                                  .toggleSearchItem(item),
                                            );
                                          },
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
                      onPlay: widget.onPlay,
                    ),
                  ),

                  // 3. Providers
                  SectionPadding(
                    child: _ProvidersSection(
                      onOpenAllProviders: widget.onOpenAllProviders,
                      onOpenProvider: widget.onOpenProvider,
                    ),
                  ),

                  // 4. Recommended for You (hidden if history/recommendations are empty)
                  SectionPadding(
                    child: _MediaSection(
                      title: 'Recommended for You',
                      items: ctrl.recommendations,
                      isLoading: ctrl.isLoadingRecommendations,
                      error: ctrl.recommendationsError,
                      hideWhenEmpty: true,
                      onRetry: ctrl.retryRecommendations,
                      onOpenDetail: widget.onOpenDetail,
                      onPlay: widget.onPlay,
                    ),
                  ),

                  for (final sectionId in ctrl.visibleSectionOrder)
                    SectionPadding(
                      child: _MediaSection(
                        title:
                            HomeController.sectionTitles[sectionId] ??
                            sectionId,
                        items: ctrl.sections[sectionId]?.items ?? const [],
                        isLoading: ctrl.sections[sectionId]?.isLoading ?? true,
                        error: ctrl.sections[sectionId]?.error,
                        onRetry: () => ctrl.retrySection(sectionId),
                        onOpenDetail: widget.onOpenDetail,
                        onPlay: widget.onPlay,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.massive),
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
    this.onPlay,
  });

  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

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
            final mediaType = (item['mediaType'] ?? item['type'] ?? '')
                .toString()
                .toLowerCase();
            final isSeries = mediaType == 'tv' || mediaType == 'anime';
            final season = item['currentSeason'] ?? item['season'];
            final episode = item['currentEpisode'] ?? item['episode'];
            final rawProgress =
                (item['progressPercent'] as num?)?.toDouble() ??
                (item['progress'] as num?)?.toDouble() ??
                0;
            final progress = rawProgress > 1 ? rawProgress / 100 : rawProgress;
            final episodeLabel = isSeries && season != null && episode != null
                ? 'Season $season · Episode $episode'
                : 'Movie';

            final imagePath =
                (item['posterPath'] ??
                        item['poster_path'] ??
                        item['backdropPath'] ??
                        item['backdrop_path'])
                    ?.toString();
            final remainingSeconds =
                ((item['totalDurationSeconds'] as num?)?.toInt() ?? 0) -
                ((item['lastPositionSeconds'] as num?)?.toInt() ?? 0);
            final remainingMinutes = remainingSeconds > 0
                ? remainingSeconds ~/ 60
                : 0;

            return ContinueWatchingCard(
              title: title,
              episodeLabel: episodeLabel,
              trailingLabel: remainingMinutes > 0
                  ? '${remainingMinutes}m'
                  : null,
              posterLabel: title,
              imageProvider: imagePath != null && imagePath.isNotEmpty
                  ? NetworkImage(TmdbImageBuilder.backdrop(imagePath))
                  : null,
              progress: progress,
              onResume: id == null
                  ? null
                  : () =>
                        onPlay?.call(PlaybackRequestFactory.fromHistory(item)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.title,
    required this.items,
    required this.isLoading,
    this.error,
    this.hideWhenEmpty = false,
    this.onRetry,
    this.onOpenDetail,
    this.onPlay,
  });

  final String title;
  final List<SearchMediaItem> items;
  final bool isLoading;
  final String? error;
  final bool hideWhenEmpty;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<PlaybackRequest>? onPlay;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && error == null && items.isEmpty && hideWhenEmpty) {
      return const SizedBox.shrink();
    }

    if (error != null && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, onSeeAllPressed: _noop),
          const SizedBox(height: AppSpacing.lg),
          _SectionStatus(
            icon: Icons.warning_amber_rounded,
            message: error!,
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, onSeeAllPressed: _noop),
        const SizedBox(height: AppSpacing.lg),
        if (!isLoading && items.isEmpty)
          _SectionStatus(
            icon: Icons.movie_filter_outlined,
            message: 'No titles available right now.',
            actionLabel: 'Retry',
            onAction: onRetry,
          )
        else
          MediaRail(
            itemWidth: 180,
            height: 330,
            children: isLoading
                ? List.generate(
                    8,
                    (index) => const PosterCard(title: '', isLoading: true),
                  )
                : items.map((item) {
                    final watchlist = WatchlistSyncController.instance;
                    return ListenableBuilder(
                      listenable: watchlist,
                      builder: (context, _) {
                        final isInWatchlist = watchlist.isInWatchlist(item.id);
                        return PosterCard(
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
                          onPlay: () => onPlay?.call(
                            PlaybackRequestFactory.fromSearchItem(item),
                          ),
                          isInWatchlist: isInWatchlist,
                          onWatchlist: () => watchlist.toggleSearchItem(item),
                          onMore: () => onOpenDetail?.call(item.id),
                        );
                      },
                    );
                  }).toList(),
          ),
      ],
    );
  }
}

class _SectionStatus extends StatelessWidget {
  const _SectionStatus({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 40),
          const SizedBox(height: AppSpacing.md),
          SelectableText(
            message,
            style: const TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class _ProvidersSection extends StatelessWidget {
  const _ProvidersSection({this.onOpenAllProviders, this.onOpenProvider});

  final VoidCallback? onOpenAllProviders;
  final ValueChanged<StreamingProviderItem>? onOpenProvider;

  @override
  Widget build(BuildContext context) {
    final providers = allProviders.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Studios', onSeeAllPressed: onOpenAllProviders),
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
              onTap: () => onOpenProvider?.call(_providerFromMap(provider)),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

void _noop() {}

StreamingProviderItem _providerFromMap(Map<String, dynamic> provider) {
  return StreamingProviderItem(
    id: (provider['id'] as num).toInt(),
    name: provider['name'] as String,
    logoPath: provider['logo_path'] as String?,
  );
}
