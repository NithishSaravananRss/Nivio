import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import 'data/mock_detail_catalog.dart';
import 'models/detail_models.dart';

class DetailView extends StatefulWidget {
  const DetailView({
    super.key,
    required this.mediaId,
    required this.onBack,
    required this.onOpenDetail,
  });

  final String mediaId;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenDetail;

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  final ScrollController _scrollController = ScrollController();
  DetailMediaTab _selectedTab = DetailMediaTab.overview;
  late DetailMedia _media = detailForId(widget.mediaId);
  int _selectedSeason = 1;
  int _selectedEpisode = 1;
  double _watchProgress = 0;

  @override
  void initState() {
    super.initState();
    _syncMedia(widget.mediaId);
  }

  @override
  void didUpdateWidget(covariant DetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _syncMedia(widget.mediaId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncMedia(String id) {
    _media = detailForId(id);
    _selectedTab = DetailMediaTab.overview;
    _selectedSeason = _media.seasons.isEmpty ? 1 : _media.seasons.first.number;
    _selectedEpisode = 1;
    _watchProgress = _media.resumeProgress;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = DetailMediaTab.values
        .where((tab) => _media.isSeries || tab != DetailMediaTab.episodes)
        .toList(growable: false);

    return DesktopScrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailHero(
              media: _media,
              watchProgress: _watchProgress,
              onBack: widget.onBack,
              onAction: _showActionFeedback,
              onToggleWatchlist: _toggleWatchlist,
            ),
            PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  _DetailTabs(
                    tabs: tabs,
                    selectedTab: _selectedTab,
                    onSelected: (tab) => setState(() => _selectedTab = tab),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildTabContent(),
                  const SizedBox(height: AppSpacing.massive),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_selectedTab) {
      DetailMediaTab.overview => _OverviewTab(media: _media),
      DetailMediaTab.episodes => _EpisodesTab(
        media: _media,
        selectedSeason: _selectedSeason,
        selectedEpisode: _selectedEpisode,
        onSeasonChanged: (season) => setState(() {
          _selectedSeason = season;
          _selectedEpisode = 1;
        }),
        onEpisodeSelected: (episode) => setState(() {
          _selectedEpisode = episode.number;
          _watchProgress = episode.progress;
        }),
      ),
      DetailMediaTab.cast => _PeopleRail(title: 'Cast', people: _media.cast),
      DetailMediaTab.crew => _CrewTab(crew: _media.crew),
      DetailMediaTab.related => _PosterRail(
        title: 'Related',
        items: _media.related,
        onOpenDetail: widget.onOpenDetail,
      ),
      DetailMediaTab.moreLikeThis => _PosterRail(
        title: 'More Like This',
        items: _media.moreLikeThis,
        onOpenDetail: widget.onOpenDetail,
      ),
    };
  }

  void _toggleWatchlist() {
    setState(() {
      _media = _media.copyWith(isInWatchlist: !_media.isInWatchlist);
    });
    _showActionFeedback(
      _media.isInWatchlist ? 'Added to watchlist' : 'Removed from watchlist',
    );
  }

  void _showActionFeedback(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum DetailMediaTab { overview, episodes, cast, crew, related, moreLikeThis }

extension _DetailMediaTabLabel on DetailMediaTab {
  String get label => switch (this) {
    DetailMediaTab.overview => 'Overview',
    DetailMediaTab.episodes => 'Episodes',
    DetailMediaTab.cast => 'Cast',
    DetailMediaTab.crew => 'Crew',
    DetailMediaTab.related => 'Related',
    DetailMediaTab.moreLikeThis => 'More Like This',
  };
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.media,
    required this.watchProgress,
    required this.onBack,
    required this.onAction,
    required this.onToggleWatchlist,
  });

  final DetailMedia media;
  final double watchProgress;
  final VoidCallback onBack;
  final ValueChanged<String> onAction;
  final VoidCallback onToggleWatchlist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(child: _BackdropArtwork(title: media.title)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.6),
                    AppColors.background,
                  ],
                  stops: const [0, 0.7, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xxl,
            left: AppSpacing.xxxl,
            child: _HeroBackButton(onBack: onBack),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 92, 48, 56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth,
                  minHeight: 560,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth >= AppBreakpoints.standard;
                    final posterWidth = isWide ? 380.0 : 260.0;
                    final poster = _PosterBlock(title: media.title);
                    final content = _HeroContent(
                      media: media,
                      watchProgress: watchProgress,
                      onAction: onAction,
                      onToggleWatchlist: onToggleWatchlist,
                    );

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: posterWidth, child: poster),
                          const SizedBox(height: AppSpacing.xxl),
                          content,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: posterWidth, child: poster),
                        const SizedBox(width: 56),
                        Expanded(child: content),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropArtwork extends StatelessWidget {
  const _BackdropArtwork({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.4,
              colors: [
                AppColors.primary.withValues(alpha: 0.20),
                AppColors.primary.withValues(alpha: 0.07),
                Colors.transparent,
              ],
              stops: const [0.0, 0.40, 1.0],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.62,
            heightFactor: 1,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.display.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.03),
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBackButton extends StatelessWidget {
  const _HeroBackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft, size: 28),
      color: AppColors.textPrimary,
      tooltip: 'Back',
      onPressed: onBack,
    );
  }
}

class _PosterBlock extends StatelessWidget {
  const _PosterBlock({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppBreakpoints.posterRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
          border: Border.all(color: AppColors.glassStroke),
          boxShadow: AppShadows.hover,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceVariant,
              AppColors.primary.withValues(alpha: 0.18),
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.pageTitle.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.media,
    required this.watchProgress,
    required this.onAction,
    required this.onToggleWatchlist,
  });

  final DetailMedia media;
  final double watchProgress;
  final ValueChanged<String> onAction;
  final VoidCallback onToggleWatchlist;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = watchProgress > 0 ? 'Resume' : 'Play';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          media.title,
          style: AppTypography.display.copyWith(
            fontSize: 64,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (media.originalTitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(media.originalTitle!, style: AppTypography.title),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            MetadataBadge(label: media.releaseYear),
            MetadataBadge(label: media.runtime),
            RatingBadge(rating: media.rating.toStringAsFixed(1)),
            MetadataBadge(label: media.certification),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children:
              media.genres.map((genre) => GenreChip(label: genre)).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Text(
            media.overview,
            style: AppTypography.body.copyWith(height: 1.55),
          ),
        ),
        if (watchProgress > 0) ...[
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 420,
            child: LinearProgressIndicator(value: watchProgress.clamp(0, 1)),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            PrimaryButton(
              label: primaryLabel,
              icon: Icon(
                watchProgress > 0 ? LucideIcons.rotateCcw : LucideIcons.play,
              ),
              minimumSize: const Size(150, 48),
              onPressed: () => onAction(
                watchProgress > 0 ? 'Resuming playback' : 'Opening player',
              ),
            ),
            SecondaryButton(
              label: media.isInWatchlist ? 'Watchlisted' : 'Watchlist',
              icon: Icon(
                media.isInWatchlist ? LucideIcons.heartOff : LucideIcons.heart,
              ),
              minimumSize: const Size(132, 48),
              onPressed: onToggleWatchlist,
            ),
            SecondaryButton(
              label: 'Download',
              icon: const Icon(LucideIcons.download),
              minimumSize: const Size(132, 48),
              onPressed: () => onAction('Preparing download'),
            ),
            SecondaryButton(
              label: 'Share',
              icon: const Icon(LucideIcons.share2),
              minimumSize: const Size(112, 48),
              onPressed: () => onAction('Share link prepared'),
            ),
            SecondaryButton(
              label: 'Trailer',
              icon: const Icon(LucideIcons.circlePlay),
              minimumSize: const Size(118, 48),
              onPressed: () => onAction('Opening trailer'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _ChipGroup(title: 'Providers', values: media.providers),
        _ChipGroup(title: 'Languages', values: media.languages),
        _ChipGroup(title: 'Audio', values: media.audioTracks),
        _ChipGroup(title: 'Subtitles', values: media.subtitleTracks),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$title:', style: AppTypography.metadata),
          ...values.map((value) => MetadataBadge(label: value)),
        ],
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({
    required this.tabs,
    required this.selectedTab,
    required this.onSelected,
  });

  final List<DetailMediaTab> tabs;
  final DetailMediaTab selectedTab;
  final ValueChanged<DetailMediaTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<DetailMediaTab>(
        segments: [
          for (final tab in tabs)
            ButtonSegment(
              value: tab,
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  tab.label,
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
              ),
            ),
        ],
        selected: {selectedTab},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.media});

  final DetailMedia media;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Synopsis', media.overview),
      ('Tagline', media.tagline),
      ('Release Date', media.releaseDate),
      ('Runtime', media.runtime),
      ('Genres', media.genres.join(', ')),
      ('Production Companies', media.productionCompanies.join(', ')),
      ('Countries', media.countries.join(', ')),
      ('Languages', media.languages.join(', ')),
      ('Status', media.status),
      ('Vote Average', media.rating.toStringAsFixed(1)),
      ('Vote Count', media.voteCount.toString()),
      ('Popularity', media.popularity.toStringAsFixed(1)),
    ];

    return _InfoPanel(
      children: [
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: 0,
          children:
              rows
                  .map(
                    (row) => SizedBox(
                      width: 400,
                      child: _InfoRow(label: row.$1, value: row.$2),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _EpisodesTab extends StatelessWidget {
  const _EpisodesTab({
    required this.media,
    required this.selectedSeason,
    required this.selectedEpisode,
    required this.onSeasonChanged,
    required this.onEpisodeSelected,
  });

  final DetailMedia media;
  final int selectedSeason;
  final int selectedEpisode;
  final ValueChanged<int> onSeasonChanged;
  final ValueChanged<DetailEpisode> onEpisodeSelected;

  @override
  Widget build(BuildContext context) {
    final season = media.seasons.firstWhere(
      (item) => item.number == selectedSeason,
      orElse: () => media.seasons.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionHeader(title: 'Episodes')),
            DropdownButton<int>(
              value: season.number,
              items: media.seasons
                  .map(
                    (season) => DropdownMenuItem(
                      value: season.number,
                      child: Text(season.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onSeasonChanged(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final episode in season.episodes)
          _EpisodeCard(
            episode: episode,
            selected: episode.number == selectedEpisode,
            onSelected: () => onEpisodeSelected(episode),
          ),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.episode,
    required this.selected,
    required this.onSelected,
  });

  final DetailEpisode episode;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: HoverCard(
        onTap: onSelected,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              SizedBox(
                width: 240,
                child: AspectRatio(
                  aspectRatio: AppBreakpoints.landscapeRatio,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.image,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episode ${episode.number} · ${episode.title}',
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${episode.runtime} · ${episode.status}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(episode.overview, style: AppTypography.body),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: episode.progress.clamp(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleRail extends StatelessWidget {
  const _PeopleRail({required this.title, required this.people});

  final String title;
  final List<DetailPerson> people;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, index) => _PersonCard(person: people[index]),
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});

  final DetailPerson person;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.user,
                  color: AppColors.textMuted,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            person.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title,
          ),
          Text(
            person.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _CrewTab extends StatelessWidget {
  const _CrewTab({required this.crew});

  final DetailCrew crew;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      children: [
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: 0,
          children: [
            SizedBox(
              width: 400,
              child: _InfoRow(label: 'Director', value: crew.director),
            ),
            SizedBox(
              width: 400,
              child: _InfoRow(label: 'Writer', value: crew.writer),
            ),
            SizedBox(
              width: 400,
              child: _InfoRow(label: 'Producer', value: crew.producer),
            ),
            SizedBox(
              width: 400,
              child: _InfoRow(label: 'Composer', value: crew.composer),
            ),
            SizedBox(
              width: 400,
              child: _InfoRow(label: 'Editor', value: crew.editor),
            ),
            SizedBox(
              width: 400,
              child: _InfoRow(label: 'Production', value: crew.production),
            ),
          ],
        ),
      ],
    );
  }
}

class _PosterRail extends StatelessWidget {
  const _PosterRail({
    required this.title,
    required this.items,
    required this.onOpenDetail,
  });

  final String title;
  final List<DetailPosterItem> items;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 390,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 190,
                child: PosterCard(
                  title: item.title,
                  year: item.year,
                  rating: item.rating,
                  subtitle: item.subtitle,
                  onTap: () => onOpenDetail(item.id),
                  onPlay: () => onOpenDetail(item.id),
                  onSecondaryTap: () => onOpenDetail(item.id),
                  onWatchlist: () {},
                  onMore: () => onOpenDetail(item.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(label, style: AppTypography.metadata),
          ),
          Expanded(child: Text(value, style: AppTypography.body)),
        ],
      ),
    );
  }
}
