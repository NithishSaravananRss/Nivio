import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/services.dart';

import '../../features/details/detail_view.dart';
import '../../features/home/home_view.dart';
import '../../features/library/library_view.dart';
import '../../features/search/controllers/mock_search_repository.dart';
import '../../features/search/controllers/search_controller.dart';
import '../../features/search/presentation/search_view.dart';
import '../widgets/feedback/empty_state.dart';
import '../theme/index.dart';
import 'desktop_sidebar.dart';
import 'desktop_topbar.dart';

/// Permanent desktop shell used by future feature screens.
class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({super.key});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  static const int _homeIndex = 0;
  static const int _libraryIndex = 1;
  static const int _liveTvIndex = 2;
  static const int _partyIndex = 3;
  static const int _profileIndex = 4;
  static const int _settingsIndex = 5;
  static const int _searchIndex = -1;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _topbarSearchFocusNode = FocusNode();
  final FocusNode _searchPageFocusNode = FocusNode();
  late final SearchController _searchStateController = SearchController(
    repository: MockSearchRepository(),
  );

  int _selectedIndex = _homeIndex;
  int _lastSidebarIndex = _homeIndex;
  bool _isSidebarExpanded = true;
  String? _detailMediaId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _topbarSearchFocusNode.dispose();
    _searchPageFocusNode.dispose();
    _searchStateController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
      _detailMediaId = null;
      if (index != _searchIndex) {
        _lastSidebarIndex = index;
      }
    });

    if (index == _searchIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_searchPageFocusNode);
        }
      });
    }
  }

  void _handleSearchSubmitted(String value) {
    if (_selectedIndex != _searchIndex) {
      _selectDestination(_searchIndex);
    }
    _searchStateController.submitQuery();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_searchPageFocusNode);
      }
    });
  }

  void _focusGlobalSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_topbarSearchFocusNode);
      }
    });
  }

  void _clearFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _openDetail(String mediaId) {
    setState(() {
      _detailMediaId = mediaId;
    });
  }

  void _closeDetail() {
    setState(() {
      _detailMediaId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  child: DesktopTopbar(
                    searchController: _searchController,
                    searchFocusNode: _topbarSearchFocusNode,
                    onSearchChanged: _searchStateController.setQuery,
                    onSearchSubmitted: _handleSearchSubmitted,
                  ),
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
    final detailMediaId = _detailMediaId;
    if (detailMediaId != null) {
      return DetailView(
        mediaId: detailMediaId,
        onBack: _closeDetail,
        onOpenDetail: _openDetail,
      );
    }

    return switch (_selectedIndex) {
      _homeIndex => HomeView(onOpenDetail: _openDetail),
      _libraryIndex => LibraryView(onOpenDetail: _openDetail),
      _liveTvIndex => const EmptyState(
        title: 'Live TV',
        message: 'Live TV will be loaded here.',
      ),
      _partyIndex => const EmptyState(
        title: 'Party',
        message: 'Watch party tools will be loaded here.',
      ),
      _profileIndex => const EmptyState(
        title: 'Profile',
        message: 'Profile details will be loaded here.',
      ),
      _settingsIndex => const EmptyState(
        title: 'Settings',
        message: 'Desktop settings will be loaded here.',
      ),
      _searchIndex => SearchView(
        controller: _searchStateController,
        queryController: _searchController,
        searchFocusNode: _searchPageFocusNode,
        onOpenDetail: _openDetail,
      ),
      _ => const HomeView(),
    };
  }
}
