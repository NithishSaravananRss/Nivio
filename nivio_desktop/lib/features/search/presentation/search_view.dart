import 'dart:async';

import 'package:flutter/material.dart' hide SearchController;

import '../../../shared/theme/index.dart';
import '../../../shared/widgets/widgets.dart';
import '../controllers/search_controller.dart';
import '../models/search_media_item.dart';
import '../widgets/search_filter_panel.dart';
import '../widgets/search_toolbar.dart';

class SearchView extends StatefulWidget {
  const SearchView({
    super.key,
    required this.controller,
    required this.queryController,
    required this.searchFocusNode,
    this.onOpenDetail,
  });

  final SearchController controller;
  final TextEditingController queryController;
  final FocusNode searchFocusNode;
  final ValueChanged<String>? onOpenDetail;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final ScrollController _resultsScrollController = ScrollController();
  bool _filtersVisible = true;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
    _resultsScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_resultsScrollController.hasClients) return;
    if (_resultsScrollController.position.pixels >=
        _resultsScrollController.position.maxScrollExtent - 500) {
      unawaited(widget.controller.loadMore());
    }
  }

  @override
  void dispose() {
    _resultsScrollController.removeListener(_onScroll);
    _resultsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= AppBreakpoints.standard;

        return SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _horizontalPadding(constraints.maxWidth),
              vertical: AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth,
                ),
                child: AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, _) {
                    final showFilters = _filtersVisible;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Search', style: AppTypography.pageTitle),
                        const SizedBox(height: AppSpacing.lg),
                        SearchToolbar(
                          controller: widget.controller,
                          queryController: widget.queryController,
                          searchFocusNode: widget.searchFocusNode,
                          onToggleFilters: () {
                            if (!wideLayout) {
                              setState(
                                () => _filtersVisible = !_filtersVisible,
                              );
                            }
                          },
                          filtersVisible: showFilters,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (widget.controller.query.isEmpty &&
                            widget.controller.recentSearches.isNotEmpty) ...[
                          _RecentSearchesRow(
                            searches: widget.controller.recentSearches,
                            onClear: widget.controller.clearRecentSearches,
                            onSelected: (value) {
                              widget.queryController.text = value;
                              widget.controller.setQuery(value);
                              widget.controller.submitQuery();
                              FocusScope.of(
                                context,
                              ).requestFocus(widget.searchFocusNode);
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, innerConstraints) {
                              final canUseSidePanel =
                                  showFilters &&
                                  wideLayout &&
                                  innerConstraints.maxWidth >=
                                      AppBreakpoints.standard;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (canUseSidePanel) ...[
                                    SizedBox(
                                      width: 300,
                                      child: SingleChildScrollView(
                                        child: SearchFilterPanel(
                                          controller: widget.controller,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xl),
                                  ] else if (showFilters && !wideLayout) ...[
                                    SizedBox(
                                      width: 240,
                                      child: SingleChildScrollView(
                                        child: SearchFilterPanel(
                                          controller: widget.controller,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                  ],
                                  Expanded(
                                    child: _SearchResultsPane(
                                      controller: widget.controller,
                                      scrollController:
                                          _resultsScrollController,
                                      onOpenDetail: widget.onOpenDetail,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _horizontalPadding(double width) {
    if (AppBreakpoints.isUltraWide(width)) {
      return AppSpacing.massive;
    }
    if (AppBreakpoints.isLarge(width)) {
      return AppSpacing.xxxl;
    }
    if (AppBreakpoints.isStandard(width)) {
      return AppSpacing.xxl;
    }
    return AppSpacing.xl;
  }
}

class _RecentSearchesRow extends StatelessWidget {
  const _RecentSearchesRow({
    required this.searches,
    required this.onSelected,
    required this.onClear,
  });

  final List<String> searches;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent searches', style: AppTypography.title),
            ),
            GhostButton(
              label: 'Clear',
              onPressed: onClear,
              minimumSize: const Size(0, 34),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ResponsiveWrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: searches
              .map(
                (search) => GenreChip(
                  label: search,
                  onPressed: () => onSelected(search),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SearchResultsPane extends StatelessWidget {
  const _SearchResultsPane({
    required this.controller,
    required this.scrollController,
    this.onOpenDetail,
  });

  final SearchController controller;
  final ScrollController scrollController;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final showLoading = controller.isLoading && controller.results.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${controller.results.length} results',
                  style: AppTypography.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                controller.hasActiveFilters ? 'Filtered' : 'All titles',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppAnimation.fast,
              child: _buildBody(showLoading),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool showLoading) {
    if (showLoading) {
      return controller.viewMode == SearchViewMode.grid
          ? const _LoadingGrid()
          : const _LoadingList();
    }

    if (controller.hasError) {
      return ErrorView(
        title: 'Search failed',
        message: controller.errorMessage ?? 'Something went wrong.',
        onRetry: controller.retry,
      );
    }

    if (controller.results.isEmpty) {
      return EmptyState(
        title: controller.query.isEmpty
            ? 'Start searching'
            : 'No results found',
        message: controller.query.isEmpty
            ? 'Search movies, shows, and anime using the field above.'
            : 'Try a different title or loosen the filters.',
      );
    }

    if (controller.viewMode == SearchViewMode.list) {
      return DesktopScrollbar(
        controller: scrollController,
        child: ListView.separated(
          controller: scrollController,
          itemCount:
              controller.results.length + (controller.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == controller.results.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _SearchResultListItem(
              item: controller.results[index],
              onOpenDetail: onOpenDetail,
            );
          },
        ),
      );
    }

    return DesktopScrollbar(
      controller: scrollController,
      child: MediaGrid(
        controller: scrollController,
        itemCount:
            controller.results.length + (controller.isLoadingMore ? 1 : 0),
        minItemWidth: 240,
        itemBuilder: (context, index) {
          if (index == controller.results.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _SearchResultPosterCard(
            item: controller.results[index],
            onOpenDetail: onOpenDetail,
          );
        },
      ),
    );
  }
}

class _SearchResultPosterCard extends StatelessWidget {
  const _SearchResultPosterCard({required this.item, this.onOpenDetail});

  final SearchMediaItem item;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      title: item.title,
      year: item.yearLabel,
      rating: item.ratingLabel,
      subtitle:
          '${item.mediaTypeLabel} · ${item.languageLabel} · ${item.provider}',
      posterPath: item.posterPath,
      onTap: () => onOpenDetail?.call(item.id),
      onPlay: () => onOpenDetail?.call(item.id),
      onWatchlist: () {},
      onMore: () {},
    );
  }
}

class _SearchResultListItem extends StatelessWidget {
  const _SearchResultListItem({required this.item, this.onOpenDetail});

  final SearchMediaItem item;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return LandscapeCard(
      title: item.title,
      subtitle: item.overview,
      metadata: [
        item.yearLabel,
        item.ratingLabel,
        item.mediaTypeLabel,
        item.languageLabel,
        item.provider,
      ],
      semanticLabel:
          '${item.title}, ${item.yearLabel}, ${item.ratingLabel} rating, ${item.languageLabel}, ${item.provider}',
      onTap: () => onOpenDetail?.call(item.id),
      onSecondaryTap: () => onOpenDetail?.call(item.id),
      onDoubleTap: () => onOpenDetail?.call(item.id),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return MediaGrid(
      itemCount: 12,
      minItemWidth: 240,
      itemBuilder: (context, index) => const PosterSkeleton(),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) =>
          const SizedBox(height: 160, child: LandscapeSkeleton()),
    );
  }
}
