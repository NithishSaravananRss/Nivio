import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/network/image/tmdb_image_builder.dart';
import '../../core/interfaces/watch_history_repository.dart';
import '../../shared/models/stream_result.dart';
import '../library/services/watchlist_sync_controller.dart';
import '../library/models/library_models.dart';
import '../library/services/library_persistence.dart';
import '../player/models/playback_request.dart';
import '../player/playback_request_factory.dart';
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
    required this.onPlay,
    required this.watchHistoryRepository,
  });

  final DetailRouteArgs args;
  final DetailController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenDetail;
  final ValueChanged<PlaybackRequest> onPlay;
  final WatchHistoryRepository watchHistoryRepository;

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  final ScrollController _scrollController = ScrollController();
  final WatchlistSyncController _watchlistController =
      WatchlistSyncController.instance;
  DetailMedia? _media;
  double _watchProgress = 0;
  int _selectedSeason = 1;
  int _resumeEpisode = 1;

  @override
  void initState() {
    super.initState();
    _syncMedia();
    widget.controller.addListener(_onControllerChanged);
    _watchlistController.addListener(_onWatchlistChanged);
    if (widget.watchHistoryRepository case final Listenable listenable) {
      listenable.addListener(_onHistoryChanged);
    }
    unawaited(_syncWatchProgress());
  }

  @override
  void didUpdateWidget(covariant DetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args != widget.args) {
      _syncMedia();
      unawaited(_syncWatchProgress());
    }
    if (oldWidget.watchHistoryRepository != widget.watchHistoryRepository) {
      if (oldWidget.watchHistoryRepository case final Listenable listenable) {
        listenable.removeListener(_onHistoryChanged);
      }
      if (widget.watchHistoryRepository case final Listenable listenable) {
        listenable.addListener(_onHistoryChanged);
      }
      unawaited(_syncWatchProgress());
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _watchlistController.removeListener(_onWatchlistChanged);
    if (widget.watchHistoryRepository case final Listenable listenable) {
      listenable.removeListener(_onHistoryChanged);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _syncMedia() {
    final m = widget.controller.media;
    if (m != null) {
      _media = _withWatchlistState(m);
      _watchProgress = m.resumeProgress;
      if (m.seasons.isNotEmpty) {
        _selectedSeason = _firstPlayableSeason(m);
      }
    }
  }

  void _onHistoryChanged() => unawaited(_syncWatchProgress());

  Future<void> _syncWatchProgress() async {
    final history = await widget.watchHistoryRepository.getWatchProgress(
      mediaId: widget.args.mediaId,
      mediaType: widget.args.mediaType,
    );
    if (!mounted || history == null) return;
    final position = (history['lastPositionSeconds'] as num?)?.toDouble() ?? 0;
    final duration = (history['totalDurationSeconds'] as num?)?.toDouble() ?? 0;
    final completed = history['isCompleted'] == true;
    final season = (history['currentSeason'] as num?)?.toInt() ?? 1;
    final episode = (history['currentEpisode'] as num?)?.toInt() ?? 1;
    final shouldLoadSeason =
        _media?.isSeries == true && _selectedSeason != season;
    setState(() {
      _watchProgress = completed || duration <= 0
          ? 0
          : (position / duration).clamp(0.0, 1.0);
      _resumeEpisode = episode;
      if (_media?.isSeries == true) _selectedSeason = season;
    });
    if (shouldLoadSeason) {
      widget.controller.loadSeasonEpisodes(widget.args.mediaId, season);
    }
  }

  void _onControllerChanged() {
    final m = widget.controller.media;
    if (m != null) {
      setState(() {
        _media = _withWatchlistState(m);
        if (m.seasons.isNotEmpty &&
            !m.seasons.any((season) => season.number == _selectedSeason)) {
          _selectedSeason = _firstPlayableSeason(m);
        }
      });
      unawaited(_syncWatchProgress());
    }
  }

  void _onWatchlistChanged() {
    final media = _media;
    if (media == null || !mounted) return;
    final inWatchlist = _watchlistController.isInWatchlist(media.id);
    if (media.isInWatchlist == inWatchlist) return;
    setState(() {
      _media = media.copyWith(isInWatchlist: inWatchlist);
    });
  }

  DetailMedia _withWatchlistState(DetailMedia media) {
    return media.copyWith(
      isInWatchlist: _watchlistController.isInWatchlist(media.id),
    );
  }

  int _firstPlayableSeason(DetailMedia media) {
    return media.seasons
        .firstWhere(
          (season) => season.number > 0,
          orElse: () => media.seasons.first,
        )
        .number;
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

        final displayMedia = _media?.id == media.id
            ? _media!
            : _withWatchlistState(media);
        _media = displayMedia;
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
                        title: displayMedia.title,
                        backdropPath: displayMedia.backdropPath,
                        poster: _HeroPoster(
                          title: displayMedia.title,
                          posterPath: displayMedia.posterPath,
                        ),
                        content: _HeroDetailsContent(
                          media: displayMedia,
                          watchProgress: _watchProgress,
                          onAction: _showActionFeedback,
                          onPlay: () => _playMedia(
                            season: displayMedia.isSeries
                                ? _selectedSeason
                                : null,
                            episode: displayMedia.isSeries
                                ? _resumeEpisode
                                : null,
                          ),
                          onToggleWatchlist: _toggleWatchlist,
                          onTrailer: _openTrailer,
                          onShare: _shareMedia,
                          onDownload: () => _queueDownload(displayMedia),
                          onMoreLikeThis: _scrollToMoreLikeThis,
                        ),
                      ),
                      PageContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (displayMedia.isSeries)
                              _EpisodePlaybackSection(
                                media: displayMedia,
                                controller: widget.controller,
                                selectedSeason: _selectedSeason,
                                onSeasonSelected: _selectSeason,
                                onPlayEpisode: (episode) => _playMedia(
                                  season: _selectedSeason,
                                  episode: episode.number,
                                ),
                                onDownloadEpisode: (episode) => _queueDownload(
                                  displayMedia,
                                  season: _selectedSeason,
                                  episode: episode.number,
                                ),
                              ),
                            _DetailStoryFlow(
                              media: displayMedia,
                              crew: _getCrewList(displayMedia),
                              onOpenDetail: widget.onOpenDetail,
                              onPlay: widget.onPlay,
                            ),
                          ],
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

  Future<void> _toggleWatchlist() async {
    final media = _media;
    if (media == null) return;

    await _watchlistController.toggleDetailMedia(media);
    final isInWatchlist = _watchlistController.isInWatchlist(media.id);
    if (!mounted) return;
    setState(() => _media = media.copyWith(isInWatchlist: isInWatchlist));
    _showActionFeedback(
      isInWatchlist ? 'Added to watchlist' : 'Removed from watchlist',
    );
  }

  Future<void> _shareMedia() async {
    final media = _media;
    if (media == null) return;
    final type = media.mediaType.label.toLowerCase();
    final deepLink = 'nivio://open/media/${media.id}?type=$type';
    final text =
        'Check out "${media.title}" on Nivio.\n\n${media.overview}\n\n$deepLink';
    await Clipboard.setData(ClipboardData(text: text));
    _showActionFeedback('Share link copied');
  }

  Future<void> _openTrailer() async {
    final media = _media;
    if (media == null || media.trailers.isEmpty) {
      _showActionFeedback('Trailer unavailable');
      return;
    }
    final url = 'https://www.youtube.com/watch?v=${media.trailers.first}';
    final result = StreamResult(
      url: url,
      quality: 'Auto',
      provider: 'YouTube Trailer',
      isDirect: false,
      isIframe: true,
    );
    widget.onPlay(
      PlaybackRequest(
        mediaId: 'trailer:${media.id}',
        title: '${media.title} Trailer',
        mediaType: media.mediaType == DetailMediaType.anime
            ? PlaybackMediaType.anime
            : PlaybackMediaType.movie,
        posterPath: media.backdropPath ?? media.posterPath,
        source: url,
        streamResult: result,
      ),
    );
  }

  Future<void> _queueDownload(
    DetailMedia media, {
    int? season,
    int? episode,
  }) async {
    await LibraryPersistence.init();
    final id = _numericMediaId(media);
    if (id == null) {
      _showActionFeedback('Download unavailable for this title');
      return;
    }
    final downloadId = [
      media.mediaType.label.toLowerCase(),
      id,
      if (season != null) 's$season',
      if (episode != null) 'e$episode',
    ].join('_');
    final title = episode == null
        ? media.title
        : '${media.title}|||S$season E$episode';
    final existing = LibraryPersistence.downloadsBox.get(downloadId);
    if (existing != null) {
      _showActionFeedback('Already in downloads');
      return;
    }
    await LibraryPersistence.downloadsBox.put(
      downloadId,
      LibraryDownloadItem(
        id: downloadId,
        mediaId: id,
        title: title,
        mediaType: media.mediaType.label.toLowerCase(),
        savePath: '',
        createdAt: DateTime.now(),
        posterPath: media.posterPath,
        season: season,
        episode: episode,
      ),
    );
    _showActionFeedback('Added to downloads');
  }

  void _scrollToMoreLikeThis() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 520),
      curve: AppAnimation.emphasized,
    );
  }

  int? _numericMediaId(DetailMedia media) {
    final raw = media.id.contains(':') ? media.id.split(':').last : media.id;
    return int.tryParse(raw);
  }

  void _playMedia({int? season, int? episode}) {
    final media = _media;
    if (media == null) return;
    widget.onPlay(
      PlaybackRequestFactory.fromDetail(
        media,
        season: season,
        episode: episode,
      ),
    );
  }

  void _selectSeason(int season) {
    setState(() {
      _selectedSeason = season;
      _resumeEpisode = 1;
      _watchProgress = 0;
    });
    widget.controller.loadSeasonEpisodes(widget.args.mediaId, season);
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
    required this.onPlay,
    required this.onToggleWatchlist,
    required this.onTrailer,
    required this.onShare,
    required this.onDownload,
    required this.onMoreLikeThis,
  });

  final DetailMedia media;
  final double watchProgress;
  final ValueChanged<String> onAction;
  final VoidCallback onPlay;
  final VoidCallback onToggleWatchlist;
  final VoidCallback onTrailer;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onMoreLikeThis;

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
              onTap: onPlay,
              icon: Icons.play_arrow,
              label: watchProgress > 0 ? 'Resume' : 'Play',
              type: StreamingActionButtonType.primary,
            ),
            StreamingActionButton(
              onTap: onToggleWatchlist,
              icon: media.isInWatchlist
                  ? Icons.favorite
                  : Icons.favorite_border,
              label: media.isInWatchlist ? 'Favorite' : 'Favorite',
              type: StreamingActionButtonType.secondary,
            ),
            StreamingActionButton(
              onTap: onTrailer,
              icon: Icons.movie_outlined,
              label: 'Trailer',
              type: StreamingActionButtonType.secondary,
            ),
            StreamingActionButton(
              onTap: onMoreLikeThis,
              icon: Icons.auto_awesome,
              label: 'More Like This',
              type: StreamingActionButtonType.secondary,
            ),
            StreamingActionButton(
              onTap: onDownload,
              icon: Icons.download,
              tooltip: 'Download',
              type: StreamingActionButtonType.iconOnly,
            ),
            StreamingActionButton(
              onTap: onShare,
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

class _EpisodePlaybackSection extends StatefulWidget {
  const _EpisodePlaybackSection({
    required this.media,
    required this.controller,
    required this.selectedSeason,
    required this.onSeasonSelected,
    required this.onPlayEpisode,
    required this.onDownloadEpisode,
  });

  final DetailMedia media;
  final DetailController controller;
  final int selectedSeason;
  final ValueChanged<int> onSeasonSelected;
  final ValueChanged<DetailEpisode> onPlayEpisode;
  final ValueChanged<DetailEpisode> onDownloadEpisode;

  @override
  State<_EpisodePlaybackSection> createState() =>
      _EpisodePlaybackSectionState();
}

class _EpisodePlaybackSectionState extends State<_EpisodePlaybackSection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.controller.episodes
        .where((episode) {
          if (_query.isEmpty) return true;
          final query = _query.toLowerCase();
          return episode.title.toLowerCase().contains(query) ||
              episode.overview.toLowerCase().contains(query) ||
              episode.number.toString().contains(query);
        })
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.massive),
      child: _EditorialSection(
        title: 'Episodes',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (widget.media.seasons.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: widget.selectedSeason,
                        dropdownColor: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        items: [
                          for (final season in widget.media.seasons)
                            DropdownMenuItem(
                              value: season.number,
                              child: Text(season.name),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _searchController.clear();
                            setState(() => _query = '');
                            widget.onSeasonSelected(value);
                          }
                        },
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search episodes',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                      filled: true,
                      fillColor: const Color(0x1FFFFFFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: Color(0x26FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.controller.isLoadingEpisodes)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (widget.controller.episodesError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Episodes unavailable: ${widget.controller.episodesError}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off,
                        color: AppColors.textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No episodes match "$_query"',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final episode in filtered)
                _EpisodeCard(
                  media: widget.media,
                  episode: episode,
                  onPlay: () => widget.onPlayEpisode(episode),
                  onDownload: () => widget.onDownloadEpisode(episode),
                ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.media,
    required this.episode,
    required this.onPlay,
    required this.onDownload,
  });

  final DetailMedia media;
  final DetailEpisode episode;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final still = episode.stillPath ?? media.backdropPath ?? media.posterPath;
    final stillUrl = TmdbImageBuilder.still(still, size: 'w300');
    final isCurrent = episode.progress > 0 && episode.progress < 0.95;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.13)
            : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.borderSubtle,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 148,
                  height: 84,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (stillUrl.isNotEmpty)
                        Image.network(
                          stillUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: AppColors.surfaceVariant),
                        )
                      else
                        const ColoredBox(color: AppColors.surfaceVariant),
                      Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCurrent ? Icons.equalizer : Icons.play_arrow,
                            color: isCurrent ? AppColors.primary : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      if (episode.progress > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: episode.progress.clamp(0, 1),
                            color: AppColors.primary,
                            backgroundColor: Colors.white24,
                            minHeight: 3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isCurrent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            'E${episode.number} - ${episode.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              color: isCurrent
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (episode.runtime.isNotEmpty)
                      Text(
                        episode.runtime,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (episode.overview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        episode.overview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Download episode ${episode.number}',
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailStoryFlow extends StatelessWidget {
  const _DetailStoryFlow({
    required this.media,
    required this.crew,
    required this.onOpenDetail,
    required this.onPlay,
  });

  final DetailMedia media;
  final List<DetailPerson> crew;
  final ValueChanged<String> onOpenDetail;
  final ValueChanged<PlaybackRequest> onPlay;

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
                  onPlay: () => onPlay(
                    PlaybackRequestFactory.fromCompositeId(item.id, item.title),
                  ),
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
