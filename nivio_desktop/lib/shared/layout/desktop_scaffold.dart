import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/services.dart';

import '../../features/details/detail_view.dart';
import '../../features/home/home_view.dart';
import '../../features/library/library_view.dart';
import '../../features/live_tv/live_tv_view.dart';
import '../../features/party/party_view.dart';
import '../../features/profile/profile_view.dart';
import '../../features/player/models/playback_request.dart';
import '../../features/player/resolving_player_screen.dart';
import '../../features/player/services/stream_resolver.dart';
import '../../features/player/playback_engine.dart';

import '../../core/interfaces/search_repository.dart';
import '../../core/interfaces/home_repository.dart';
import '../../core/interfaces/details_repository.dart';
import '../../features/search/controllers/search_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/details/controllers/detail_controller.dart';
import '../../features/details/models/detail_route_args.dart';
import '../../features/search/presentation/search_view.dart';
import '../../core/repositories/tmdb_search_repository.dart';
import '../../core/repositories/tmdb_home_repository.dart';
import '../../core/repositories/tmdb_details_repository.dart';
import '../../core/network/tmdb_client.dart';
import '../../core/constants.dart';
import '../theme/index.dart';
import 'desktop_sidebar.dart';
import 'desktop_topbar.dart';
import '../../core/interfaces/watch_history_repository.dart';
import '../../features/history/desktop_watch_history_repository.dart';

/// Permanent desktop shell used by future feature screens.
class DesktopScaffold extends StatefulWidget {
  final SearchRepository? searchRepository;
  final HomeRepository? homeRepository;
  final DetailsRepository? detailsRepository;
  final StreamResolver? streamResolver;
  final PlaybackEngineFactory? playbackEngineFactory;
  final WatchHistoryRepository? watchHistoryRepository;

  const DesktopScaffold({
    super.key,
    this.searchRepository,
    this.homeRepository,
    this.detailsRepository,
    this.streamResolver,
    this.playbackEngineFactory,
    this.watchHistoryRepository,
  });

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  static const int _homeIndex = 0;
  static const int _searchIndex = 1;
  static const int _libraryIndex = 2;
  static const int _liveTvIndex = 3;
  static const int _partyIndex = 4;
  static const int _profileIndex = 5;

  late final WatchHistoryRepository _watchHistoryRepository =
      widget.watchHistoryRepository ?? DesktopWatchHistoryRepository.instance;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchPageFocusNode = FocusNode();
  late final SearchController _searchStateController = SearchController(
    repository:
        widget.searchRepository ??
        TmdbSearchRepository(client: TmdbClient(apiKey: tmdbApiKey)),
  );

  late final HomeController _homeStateController = HomeController(
    repository:
        widget.homeRepository ??
        TmdbHomeRepository(client: TmdbClient(apiKey: tmdbApiKey)),
    watchHistoryRepository: _watchHistoryRepository,
  );

  late final DetailController _detailStateController = DetailController(
    repository:
        widget.detailsRepository ??
        TmdbDetailsRepository(client: TmdbClient(apiKey: tmdbApiKey)),
  );

  int _selectedIndex = _homeIndex;
  int _lastSidebarIndex = _homeIndex;
  bool _isSidebarExpanded = true;
  DetailRouteArgs? _detailRouteArgs;
  PlaybackRequest? _playbackRequest;

  @override
  void initState() {
    super.initState();
    _homeStateController.loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchPageFocusNode.dispose();
    _searchStateController.dispose();
    _homeStateController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
      _detailRouteArgs = null;
      _lastSidebarIndex = index;
    });

    if (index == _searchIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_searchPageFocusNode);
        }
      });
    }
  }

  void _focusGlobalSearch() {
    _selectDestination(_searchIndex);
  }

  void _clearFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _openDetail(String mediaId) {
    final parts = mediaId.split(':');
    if (parts.length >= 2) {
      final mediaType = parts[0];
      final id = int.tryParse(parts[1]) ?? 0;
      final args = DetailRouteArgs(mediaType: mediaType, mediaId: id);
      _detailStateController.loadDetail(args);
      setState(() {
        _detailRouteArgs = args;
      });
    }
  }

  void _closeDetail() {
    setState(() {
      _detailRouteArgs = null;
    });
  }

  void _openPlayback(PlaybackRequest request) {
    setState(() => _playbackRequest = request);
  }

  void _closePlayback() {
    setState(() => _playbackRequest = null);
  }

  @override
  Widget build(BuildContext context) {
    final playbackRequest = _playbackRequest;
    if (playbackRequest != null) {
      return ResolvingPlayerScreen(
        request: playbackRequest,
        resolver: widget.streamResolver,
        engineFactory: widget.playbackEngineFactory,
        watchHistoryRepository: _watchHistoryRepository,
        onClose: _closePlayback,
        onNextEpisode: _openPlayback,
      );
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.slash): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _focusGlobalSearch();
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _clearFocus();
              return null;
            },
          ),
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: AppBreakpoints.topbarHeight,
                  child: const DesktopTopbar(),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact =
                          constraints.maxWidth < AppBreakpoints.compactShell;

                      final content = _buildContent();

                      if (isCompact) {
                        return Column(
                          children: [
                            DesktopSidebar(
                              isCompact: true,
                              selectedIndex: _lastSidebarIndex,
                              onDestinationSelected: _selectDestination,
                            ),
                            Expanded(child: content),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          SizedBox(
                            width: _isSidebarExpanded
                                ? AppBreakpoints.sidebarExpandedWidth
                                : AppBreakpoints.sidebarCollapsedWidth,
                            child: DesktopSidebar(
                              isExpanded: _isSidebarExpanded,
                              selectedIndex: _lastSidebarIndex,
                              onToggleExpanded: () {
                                setState(() {
                                  _isSidebarExpanded = !_isSidebarExpanded;
                                });
                              },
                              onDestinationSelected: _selectDestination,
                            ),
                          ),
                          Expanded(child: content),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final detailRouteArgs = _detailRouteArgs;
    if (detailRouteArgs != null) {
      return DetailView(
        args: detailRouteArgs,
        controller: _detailStateController,
        onBack: _closeDetail,
        onOpenDetail: _openDetail,
        onPlay: _openPlayback,
        watchHistoryRepository: _watchHistoryRepository,
      );
    }

    return switch (_selectedIndex) {
      _homeIndex => HomeView(
        controller: _homeStateController,
        onOpenDetail: _openDetail,
        onPlay: _openPlayback,
      ),
      _libraryIndex => LibraryView(
        onOpenDetail: _openDetail,
        onPlay: _openPlayback,
        watchHistoryRepository: _watchHistoryRepository,
      ),
      _liveTvIndex => LiveTvView(onPlay: _openPlayback),
      _partyIndex => PartyView(onPlay: _openPlayback),
      _profileIndex => ProfileView(onOpenDetail: _openDetail),
      _searchIndex => SearchView(
        controller: _searchStateController,
        queryController: _searchController,
        searchFocusNode: _searchPageFocusNode,
        onOpenDetail: _openDetail,
        onPlay: _openPlayback,
      ),
      _ => HomeView(
        controller: _homeStateController,
        onOpenDetail: _openDetail,
        onPlay: _openPlayback,
      ),
    };
  }
}
