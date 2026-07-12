import 'package:flutter/material.dart';

import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.onOpenDetail});

  final ValueChanged<String>? onOpenDetail;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionPadding(
                vertical: AppSpacing.xxl,
                child: HeroBanner(
                  title: 'Blackout City',
                  overview:
                      'A damaged ex-courier crosses a neon city to deliver a memory vault that every faction wants, while an old promise pulls him back into the frame.',
                  rating: 'TV-MA',
                  year: '2026',
                  runtime: '2h 18m',
                  genres: ['Action', 'Sci-Fi', 'Thriller'],
                  primaryActionLabel: 'Play now',
                  secondaryActionLabel: 'Add to watchlist',
                  posterLabel: 'Blackout\nCity',
                  backdropLabel: 'Blackout City',
                ),
              ),
              SectionPadding(
                child: _ContinueWatchingSection(
                  onOpenDetail: widget.onOpenDetail,
                ),
              ),
              SectionPadding(
                child: _TrendingSection(onOpenDetail: widget.onOpenDetail),
              ),
              const SectionPadding(child: _ProvidersSection()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection({this.onOpenDetail});

  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
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
          children: [
            ContinueWatchingCard(
              title: 'The Last Circuit',
              episodeLabel: 'Season 2 · Episode 4',
              posterLabel: 'The Last Circuit',
              progress: 0.62,
              onResume: () => onOpenDetail?.call('night-protocol'),
            ),
            ContinueWatchingCard(
              title: 'Moon Harbor',
              episodeLabel: 'Season 1 · Episode 9',
              posterLabel: 'Moon Harbor',
              progress: 0.34,
              onResume: () => onOpenDetail?.call('moon-harbor'),
            ),
            ContinueWatchingCard(
              title: 'Shatterline',
              episodeLabel: 'Episode 11',
              posterLabel: 'Shatterline',
              progress: 0.79,
              onResume: () => onOpenDetail?.call('sky-forge'),
            ),
            ContinueWatchingCard(
              title: 'Arcadia Drift',
              episodeLabel: 'Season 3 · Episode 2',
              posterLabel: 'Arcadia Drift',
              progress: 0.48,
              onResume: () => onOpenDetail?.call('signal-lost'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendingSection extends StatelessWidget {
  const _TrendingSection({this.onOpenDetail});

  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Trending Movies', onSeeAllPressed: _noop),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveGrid(
          minItemWidth: 170,
          childAspectRatio: 0.66,
          children: [
            PosterCard(
              title: 'Signal Lost',
              year: '2026',
              rating: '8.4',
              subtitle: 'Action · Drama',
              onTap: () => onOpenDetail?.call('signal-lost'),
              onSecondaryTap: () => onOpenDetail?.call('signal-lost'),
              onPlay: () => onOpenDetail?.call('signal-lost'),
              onWatchlist: _noop,
              onMore: () => onOpenDetail?.call('signal-lost'),
            ),
            PosterCard(
              title: 'Midnight Harbor',
              year: '2025',
              rating: '7.9',
              subtitle: 'Mystery · Thriller',
              onTap: () => onOpenDetail?.call('midnight-harbor'),
              onSecondaryTap: () => onOpenDetail?.call('midnight-harbor'),
              onPlay: () => onOpenDetail?.call('midnight-harbor'),
              onWatchlist: _noop,
              onMore: () => onOpenDetail?.call('midnight-harbor'),
            ),
            PosterCard(
              title: 'Zero Day',
              year: '2026',
              rating: '8.1',
              subtitle: 'Sci-Fi · Action',
              onTap: () => onOpenDetail?.call('zero-day'),
              onSecondaryTap: () => onOpenDetail?.call('zero-day'),
              onPlay: () => onOpenDetail?.call('zero-day'),
              onWatchlist: _noop,
              onMore: () => onOpenDetail?.call('zero-day'),
            ),
            PosterCard(
              title: 'Glass Orbit',
              year: '2024',
              rating: '7.5',
              subtitle: 'Adventure · Sci-Fi',
              onTap: () => onOpenDetail?.call('glass-orbit'),
              onSecondaryTap: () => onOpenDetail?.call('glass-orbit'),
              onPlay: () => onOpenDetail?.call('glass-orbit'),
              onWatchlist: _noop,
              onMore: () => onOpenDetail?.call('glass-orbit'),
            ),
            PosterCard(
              title: 'Cold Front',
              year: '2025',
              rating: '8.0',
              subtitle: 'Crime · Thriller',
              onTap: () => onOpenDetail?.call('cold-front'),
              onSecondaryTap: () => onOpenDetail?.call('cold-front'),
              onPlay: () => onOpenDetail?.call('cold-front'),
              onWatchlist: _noop,
              onMore: () => onOpenDetail?.call('cold-front'),
            ),
            PosterCard(
              title: 'Northbound',
              year: '2024',
              rating: '7.7',
              subtitle: 'Adventure · Drama',
              onTap: () => onOpenDetail?.call('northbound'),
              onSecondaryTap: () => onOpenDetail?.call('northbound'),
              onPlay: () => onOpenDetail?.call('northbound'),
              onWatchlist: _noop,
              onMore: () => onOpenDetail?.call('northbound'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        const SectionHeader(title: 'Trending TV', onSeeAllPressed: _noop),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveGrid(
          minItemWidth: 170,
          childAspectRatio: 0.66,
          children: [
            PosterCard(
              title: 'Night Protocol',
              year: '2026',
              rating: '8.5',
              subtitle: 'TV · Crime',
              onTap: () => onOpenDetail?.call('night-protocol'),
              onSecondaryTap: () => onOpenDetail?.call('night-protocol'),
              onPlay: () => onOpenDetail?.call('night-protocol'),
              onWatchlist: _noop,
              onMore: () => onOpenDetail?.call('night-protocol'),
            ),
            PosterCard(
              title: 'Halo Signal',
              year: '2025',
              rating: '8.0',
              subtitle: 'TV · Sci-Fi',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
            PosterCard(
              title: 'Archive West',
              year: '2024',
              rating: '7.8',
              subtitle: 'TV · Drama',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
            PosterCard(
              title: 'After Hours',
              year: '2026',
              rating: '8.2',
              subtitle: 'TV · Comedy',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
            PosterCard(
              title: 'Signal House',
              year: '2025',
              rating: '7.6',
              subtitle: 'TV · Thriller',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
            PosterCard(
              title: 'Lunar Grid',
              year: '2024',
              rating: '8.1',
              subtitle: 'TV · Action',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        const SectionHeader(title: 'Trending Anime', onSeeAllPressed: _noop),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveGrid(
          minItemWidth: 170,
          childAspectRatio: 0.66,
          children: [
            PosterCard(
              title: 'Sky Forge',
              year: '2026',
              rating: '9.0',
              subtitle: 'Anime · Action',
              onTap: () => onOpenDetail?.call('sky-forge'),
              onSecondaryTap: () => onOpenDetail?.call('sky-forge'),
              onPlay: () => onOpenDetail?.call('sky-forge'),
              onWatchlist: _noop,
              onMore: () => onOpenDetail?.call('sky-forge'),
            ),
            PosterCard(
              title: 'Violet Loop',
              year: '2025',
              rating: '8.7',
              subtitle: 'Anime · Sci-Fi',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
            PosterCard(
              title: 'Redline Bloom',
              year: '2024',
              rating: '8.5',
              subtitle: 'Anime · Adventure',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
            PosterCard(
              title: 'Echo Garden',
              year: '2026',
              rating: '8.3',
              subtitle: 'Anime · Fantasy',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
            PosterCard(
              title: 'Nova Tides',
              year: '2024',
              rating: '8.2',
              subtitle: 'Anime · Drama',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
            PosterCard(
              title: 'Neon Relay',
              year: '2025',
              rating: '8.4',
              subtitle: 'Anime · Action',
              onTap: _noop,
              onSecondaryTap: _noop,
              onPlay: _noop,
              onWatchlist: _noop,
              onMore: _noop,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProvidersSection extends StatelessWidget {
  const _ProvidersSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Popular Providers', onSeeAllPressed: _noop),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveGrid(
          minItemWidth: 150,
          childAspectRatio: 0.9,
          children: const [
            ProviderCard(name: 'Netflix', label: 'Mock provider'),
            ProviderCard(name: 'Prime Video', label: 'Mock provider'),
            ProviderCard(name: 'Disney+', label: 'Mock provider'),
            ProviderCard(name: 'Apple TV', label: 'Mock provider'),
            ProviderCard(name: 'Crunchyroll', label: 'Mock provider'),
            ProviderCard(name: 'Hulu', label: 'Mock provider'),
            ProviderCard(name: 'Plex', label: 'Mock provider'),
            ProviderCard(name: 'YouTube', label: 'Mock provider'),
            ProviderCard(name: 'Sun NXT', label: 'Mock provider'),
          ],
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

void _noop() {}
