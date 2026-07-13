import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/network/image/tmdb_image_builder.dart';
import 'models/detail_models.dart';
import 'models/detail_route_args.dart';
import 'controllers/detail_controller.dart';

class DetailView extends StatefulWidget {
  const DetailView({
    super.key,
    required this.args,
    required this.controller,
    required this.onBack,
    required this.onOpenDetail,
  });

  final DetailRouteArgs args;
  final DetailController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenDetail;

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  final ScrollController _scrollController = ScrollController();
  DetailMedia? _media;
  double _watchProgress = 0;

  @override
  void initState() {
    super.initState();
    _syncMedia();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant DetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args != widget.args) {
      _syncMedia();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncMedia() {
    final m = widget.controller.media;
    if (m != null) {
      _media = m;
      _watchProgress = m.resumeProgress;
    }
  }

  void _onControllerChanged() {
    final m = widget.controller.media;
    if (m != null) {
      setState(() {
        _media = m;
        _watchProgress = m.resumeProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final status = widget.controller.status;
        final media = widget.controller.media;

        if (status == DetailStatus.loading || status == DetailStatus.retrying) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (status == DetailStatus.offline) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.wifiOff,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Offline', style: AppTypography.sectionTitle),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.controller.errorMessage ??
                            'No internet connection',
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: widget.controller.retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: AppSpacing.xl,
                  left: AppSpacing.xl,
                  child: _FloatingBackButton(onTap: widget.onBack),
                ),
              ],
            ),
          );
        }

        if (status == DetailStatus.apiError || status == DetailStatus.error) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Error Loading Details',
                        style: AppTypography.sectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Text(
                          widget.controller.errorMessage ?? 'An error occurred',
                          style: AppTypography.body,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: widget.controller.retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: AppSpacing.xl,
                  left: AppSpacing.xl,
                  child: _FloatingBackButton(onTap: widget.onBack),
                ),
              ],
            ),
          );
        }

        if (media == null || status == DetailStatus.empty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                const Center(child: Text('No details found')),
                Positioned(
                  top: AppSpacing.xl,
                  left: AppSpacing.xl,
                  child: _FloatingBackButton(onTap: widget.onBack),
                ),
              ],
            ),
          );
        }

        _media = media;
        _watchProgress = media.resumeProgress;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              DesktopScrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HeroSection(
                        title: media.title,
                        backdropPath: media.backdropPath,
                        poster: _HeroPoster(
                          title: media.title,
                          posterPath: media.posterPath,
                        ),
                        content: _HeroDetailsContent(
                          media: media,
                          watchProgress: _watchProgress,
                          onAction: _showActionFeedback,
                          onToggleWatchlist: _toggleWatchlist,
                        ),
                      ),
                      PageContainer(
                        child: _DetailStoryFlow(
                          media: media,
                          crew: _getCrewList(media),
                          onOpenDetail: widget.onOpenDetail,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.xl,
                left: AppSpacing.xl,
                child: _FloatingBackButton(onTap: widget.onBack),
              ),
            ],
          ),
        );
      },
    );
  }

  List<DetailPerson> _getCrewList(DetailMedia media) {
    return [
      if (media.crew.director != 'N/A')
        DetailPerson(name: media.crew.director, role: 'Director'),
      if (media.crew.writer != 'N/A')
        DetailPerson(name: media.crew.writer, role: 'Writer'),
      if (media.crew.producer != 'N/A')
        DetailPerson(name: media.crew.producer, role: 'Producer'),
      if (media.crew.composer != 'N/A')
        DetailPerson(name: media.crew.composer, role: 'Music'),
      if (media.crew.editor != 'N/A')
        DetailPerson(name: media.crew.editor, role: 'Cinematography'),
    ];
  }

  void _toggleWatchlist() {
    final media = _media;
    if (media == null) return;

    setState(() {
      _media = media.copyWith(isInWatchlist: !media.isInWatchlist);
    });
    _showActionFeedback(
      _media!.isInWatchlist ? 'Added to watchlist' : 'Removed from watchlist',
    );
  }

  void _showActionFeedback(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FloatingBackButton extends StatefulWidget {
  const _FloatingBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FloatingBackButton> createState() => _FloatingBackButtonState();
}

class _FloatingBackButtonState extends State<_FloatingBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? AppColors.primary
                : Colors.black.withValues(alpha: 0.5),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.borderSubtle,
              width: 1.5,
            ),
            boxShadow: AppShadows.hover,
          ),
          child: Icon(
            Icons.arrow_back,
            color: _isHovered ? AppColors.background : AppColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _HeroDetailsContent extends StatelessWidget {
  const _HeroDetailsContent({
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
    final primaryGenre = media.genres.take(2).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          media.title,
          style: AppTypography.display.copyWith(
            fontSize: 76,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 0.94,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _InlineMetadata(
          items: [
            media.rating.toStringAsFixed(1),
            media.releaseYear,
            media.mediaType.label,
            media.runtime,
            if (media.languages.isNotEmpty) media.languages.first,
            ...primaryGenre,
          ],
        ),
        if (media.overview.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _ExpandableSynopsis(
              text: media.overview,
              collapsedLines: 4,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.86),
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StreamingActionButton(
              onTap: () => onAction('Starting playback...'),
              icon: Icons.play_arrow,
              label: 'Play',
              type: StreamingActionButtonType.primary,
            ),
            StreamingActionButton(
              onTap: onToggleWatchlist,
              icon: media.isInWatchlist ? Icons.check : Icons.add,
              label: media.isInWatchlist ? 'In Watchlist' : 'Watchlist',
              type: StreamingActionButtonType.secondary,
            ),
            StreamingActionButton(
              onTap: () => onAction('Opening trailer...'),
              icon: Icons.movie_outlined,
              label: 'Trailer',
              type: StreamingActionButtonType.secondary,
            ),
            StreamingActionButton(
              onTap: () => onAction('Downloading...'),
              icon: Icons.download,
              tooltip: 'Download',
              type: StreamingActionButtonType.iconOnly,
            ),
            StreamingActionButton(
              onTap: () => onAction('Link copied to clipboard!'),
              icon: Icons.share,
              tooltip: 'Share',
              type: StreamingActionButtonType.iconOnly,
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineMetadata extends StatelessWidget {
  const _InlineMetadata({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.trim().isNotEmpty && item.trim() != 'N/A')
        .toList(growable: false);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < visibleItems.length; i++) ...[
          if (i > 0)
            Text(
              '|',
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          Text(
            visibleItems[i],
            style: AppTypography.body.copyWith(
              color: i == 0 ? AppColors.primary : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroPoster extends StatefulWidget {
  const _HeroPoster({required this.title, this.posterPath});

  final String title;
  final String? posterPath;

  @override
  State<_HeroPoster> createState() => _HeroPosterState();
}

class _HeroPosterState extends State<_HeroPoster> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final imageProvider =
        (widget.posterPath != null && widget.posterPath!.isNotEmpty)
        ? NetworkImage(TmdbImageBuilder.poster(widget.posterPath!))
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.035 : 1,
        duration: AppAnimation.hover,
        curve: AppAnimation.standard,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.68 : 0.52),
                blurRadius: _isHovered ? 46 : 34,
                spreadRadius: -4,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: AppBreakpoints.posterRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: imageProvider == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            widget.title,
                            maxLines: 3,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableSynopsis extends StatefulWidget {
  const _ExpandableSynopsis({
    required this.text,
    required this.style,
    this.collapsedLines = 4,
  });

  final String text;
  final TextStyle style;
  final int collapsedLines;

  @override
  State<_ExpandableSynopsis> createState() => _ExpandableSynopsisState();
}

class _ExpandableSynopsisState extends State<_ExpandableSynopsis> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            if (_expanded) {
              return const LinearGradient(
                colors: [Colors.white, Colors.white],
              ).createShader(bounds);
            }
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white,
                Colors.white.withValues(alpha: 0.18),
              ],
              stops: const [0, 0.72, 1],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Text(
            widget.text,
            maxLines: _expanded ? null : widget.collapsedLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.fade,
            style: widget.style,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show Less' : 'Read More',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailStoryFlow extends StatelessWidget {
  const _DetailStoryFlow({
    required this.media,
    required this.crew,
    required this.onOpenDetail,
  });

  final DetailMedia media;
  final List<DetailPerson> crew;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final recommendations = _mergedRecommendations(media);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.massive),
        _FadeInSection(
          delay: const Duration(milliseconds: 80),
          child: _AboutAndMetadataSection(media: media),
        ),
        if (media.cast.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.massive),
          _FadeInSection(
            delay: const Duration(milliseconds: 150),
            child: PersonCarousel(
              title: 'Cast',
              itemCount: media.cast.length,
              height: 276,
              itemWidth: 140,
              itemBuilder: (context, index) {
                final person = media.cast[index];
                return PersonCard(
                  title: person.name,
                  subtitle: person.role,
                  profilePath: person.profilePath,
                );
              },
            ),
          ),
        ],
        if (crew.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.massive),
          _FadeInSection(
            delay: const Duration(milliseconds: 220),
            child: _CrewSection(crew: crew),
          ),
        ],
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.massive),
          _FadeInSection(
            delay: const Duration(milliseconds: 290),
            child: MediaCarousel(
              title: 'You May Also Like',
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final item = recommendations[index];
                return MediaCard(
                  title: item.title,
                  posterPath: item.posterPath,
                  year: item.year,
                  rating: item.rating,
                  subtitle: item.subtitle,
                  onTap: () => onOpenDetail(item.id),
                  onPlay: () => onOpenDetail(item.id),
                  onMore: () => onOpenDetail(item.id),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }

  List<DetailPosterItem> _mergedRecommendations(DetailMedia media) {
    final seen = <String>{};
    final items = <DetailPosterItem>[];

    for (final item in [...media.related, ...media.moreLikeThis]) {
      if (seen.add(item.id)) {
        items.add(item);
      }
      if (items.length == 20) break;
    }

    return items;
  }
}

class _CrewSection extends StatelessWidget {
  const _CrewSection({required this.crew});

  final List<DetailPerson> crew;

  @override
  Widget build(BuildContext context) {
    return _EditorialSection(
      title: 'Crew',
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: [
          for (final person in crew)
            SizedBox(
              width: 240,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceVariant.withValues(alpha: 0.7),
                      border: Border.all(
                        color: AppColors.borderSubtle.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      _crewIcon(person.role),
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          person.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _crewIcon(String role) {
    return switch (role) {
      'Director' => LucideIcons.clapperboard,
      'Writer' => LucideIcons.penLine,
      'Producer' => LucideIcons.badgeCheck,
      'Music' => LucideIcons.music,
      'Cinematography' => LucideIcons.camera,
      _ => LucideIcons.user,
    };
  }
}

class _AboutAndMetadataSection extends StatelessWidget {
  const _AboutAndMetadataSection({required this.media});

  final DetailMedia media;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 980;
        final about = _EditorialSection(
          title: 'About',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (media.tagline.isNotEmpty) ...[
                Text(
                  '"${media.tagline}"',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                media.overview.isEmpty
                    ? 'Synopsis unavailable.'
                    : media.overview,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                  fontSize: 16,
                  height: 1.65,
                ),
              ),
              if (media.providers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                ProviderRow(providers: media.providers),
              ],
            ],
          ),
        );

        final details = _EditorialSection(
          title: 'Details',
          child: _InfoGrid(
            items: [
              _InfoItem('Runtime', media.runtime),
              _InfoItem('Release', media.releaseDate),
              _InfoItem('Language', media.languages.join(', ')),
              _InfoItem('Country', media.productionCountries.join(', ')),
              _InfoItem('Genres', media.genres.join(', ')),
              _InfoItem('Status', media.status),
              _InfoItem('Studios', media.productionCompanies.join(', ')),
              _InfoItem('Homepage', media.homepage ?? ''),
              _InfoItem('IMDb', media.imdbId ?? ''),
            ],
          ),
        );

        if (!useColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              about,
              const SizedBox(height: AppSpacing.massive),
              details,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: about),
            const SizedBox(width: 56),
            Expanded(flex: 5, child: details),
          ],
        );
      },
    );
  }
}

class _EditorialSection extends StatelessWidget {
  const _EditorialSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.sectionTitle.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where(
          (item) => item.value.trim().isNotEmpty && item.value.trim() != 'N/A',
        )
        .toList(growable: false);

    if (visibleItems.isEmpty) {
      return Text(
        'Details unavailable.',
        style: AppTypography.body.copyWith(color: AppColors.textMuted),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 460 ? 2 : 1;
        return Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.lg,
          children: [
            for (final item in visibleItems)
              SizedBox(
                width: columns == 2
                    ? (constraints.maxWidth - AppSpacing.xl) / 2
                    : constraints.maxWidth,
                child: _InfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final value = item.value.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label.toUpperCase(),
          style: AppTypography.metadata.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.88),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String value;
}

class _FadeInSection extends StatefulWidget {
  const _FadeInSection({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeInSection> createState() => _FadeInSectionState();
}

class _FadeInSectionState extends State<_FadeInSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AppAnimation.standard,
    );
    _offset = Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: AppAnimation.emphasized),
        );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
