import 'package:flutter/material.dart';

import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/downloads_grid.dart';
import 'widgets/library_empty_state.dart';
import 'widgets/library_tabs.dart';
import 'widgets/release_timeline.dart';
import 'widgets/schedule_calendar.dart';
import 'widgets/watchlist_grid.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final ScrollController _scrollController = ScrollController();
  LibraryTab _selectedTab = LibraryTab.schedule;
  String _selectedMonth = 'January 2026';
  DateTime _selectedScheduleDate = DateTime(2026, 1, 15);
  bool _watchlistOnly = true;
  String _watchlistSort = 'Recently Added';

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
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(
                title: 'Library',
                subtitle: 'Schedule, watchlist, and downloads',
                trailing: LibraryTabs(
                  selectedTab: _selectedTab,
                  onTabSelected: (tab) => setState(() => _selectedTab = tab),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _LibraryTabContent(
                selectedTab: _selectedTab,
                selectedMonth: _selectedMonth,
                selectedScheduleDate: _selectedScheduleDate,
                watchlistOnly: _watchlistOnly,
                watchlistSort: _watchlistSort,
                onMonthChanged: (value) => setState(() {
                  _selectedMonth = value;
                  _selectedScheduleDate = _dateForMonth(
                    value,
                    _selectedScheduleDate.day,
                  );
                }),
                onScheduleDateChanged: (value) =>
                    setState(() => _selectedScheduleDate = value),
                onScheduleFilterChanged: (value) =>
                    setState(() => _watchlistOnly = value),
                onWatchlistSortChanged: (value) =>
                    setState(() => _watchlistSort = value),
              ),
              const SizedBox(height: AppSpacing.massive),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _dateForMonth(String month, int day) {
    final monthIndex = switch (month) {
      'February 2026' => 2,
      'March 2026' => 3,
      _ => 1,
    };
    final clampedDay = monthIndex == 2 && day > 28 ? 28 : day;
    return DateTime(2026, monthIndex, clampedDay);
  }
}

class _LibraryTabContent extends StatelessWidget {
  const _LibraryTabContent({
    required this.selectedTab,
    required this.selectedMonth,
    required this.selectedScheduleDate,
    required this.watchlistOnly,
    required this.watchlistSort,
    required this.onMonthChanged,
    required this.onScheduleDateChanged,
    required this.onScheduleFilterChanged,
    required this.onWatchlistSortChanged,
  });

  final LibraryTab selectedTab;
  final String selectedMonth;
  final DateTime selectedScheduleDate;
  final bool watchlistOnly;
  final String watchlistSort;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<DateTime> onScheduleDateChanged;
  final ValueChanged<bool> onScheduleFilterChanged;
  final ValueChanged<String> onWatchlistSortChanged;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTab) {
      LibraryTab.schedule => _ScheduleTab(
        selectedMonth: selectedMonth,
        selectedDate: selectedScheduleDate,
        watchlistOnly: watchlistOnly,
        onMonthChanged: onMonthChanged,
        onDateSelected: onScheduleDateChanged,
        onFilterChanged: onScheduleFilterChanged,
      ),
      LibraryTab.watchlist => _WatchlistTab(
        selectedSort: watchlistSort,
        onSortChanged: onWatchlistSortChanged,
      ),
      LibraryTab.downloads => const _DownloadsTab(),
    };
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({
    required this.selectedMonth,
    required this.selectedDate,
    required this.watchlistOnly,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.onFilterChanged,
  });

  final String selectedMonth;
  final DateTime selectedDate;
  final bool watchlistOnly;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<bool> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.standard;
        final calendar = ScheduleCalendar(
          selectedMonth: selectedMonth,
          selectedDate: selectedDate,
          onMonthChanged: onMonthChanged,
          onDateSelected: onDateSelected,
        );
        final filters = _ScheduleFilters(
          watchlistOnly: watchlistOnly,
          onFilterChanged: onFilterChanged,
        );
        final timeline = ReleaseTimeline(
          releases: _filteredScheduleReleases(selectedDate, watchlistOnly),
          watchlistOnly: watchlistOnly,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 420,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        calendar,
                        const SizedBox(height: AppSpacing.lg),
                        filters,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxl),
                  Expanded(child: timeline),
                ],
              )
            else ...[
              calendar,
              const SizedBox(height: AppSpacing.lg),
              filters,
              const SizedBox(height: AppSpacing.xxl),
              timeline,
            ],
          ],
        );
      },
    );
  }

  List<ScheduleRelease> _filteredScheduleReleases(
    DateTime selectedDate,
    bool watchlistOnly,
  ) {
    return _mockScheduleReleases
        .where((release) {
          final sameDay =
              release.releaseDate.year == selectedDate.year &&
              release.releaseDate.month == selectedDate.month &&
              release.releaseDate.day == selectedDate.day;
          return sameDay && (!watchlistOnly || release.isInWatchlist);
        })
        .toList(growable: false);
  }
}

class _ScheduleFilters extends StatelessWidget {
  const _ScheduleFilters({
    required this.watchlistOnly,
    required this.onFilterChanged,
  });

  final bool watchlistOnly;
  final ValueChanged<bool> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('My Watchlist'),
          selected: watchlistOnly,
          onSelected: (selected) {
            if (selected) {
              onFilterChanged(true);
            }
          },
        ),
        ChoiceChip(
          label: const Text('Discover'),
          selected: !watchlistOnly,
          onSelected: (selected) {
            if (selected) {
              onFilterChanged(false);
            }
          },
        ),
      ],
    );
  }
}

final List<ScheduleRelease> _mockScheduleReleases = [
  ScheduleRelease(
    title: 'Sky Forge',
    mediaType: 'anime',
    releaseDate: DateTime(2026, 1, 15, 18, 30),
    episodeNumber: 8,
    seasonNumber: 1,
    hasPreciseTime: true,
    isInWatchlist: true,
  ),
  ScheduleRelease(
    title: 'Night Protocol',
    mediaType: 'tv',
    releaseDate: DateTime(2026, 1, 15, 12),
    episodeNumber: 5,
    seasonNumber: 2,
    isInWatchlist: false,
  ),
  ScheduleRelease(
    title: 'Archive West',
    mediaType: 'tv',
    releaseDate: DateTime(2026, 1, 22, 12),
    episodeNumber: 1,
    seasonNumber: 3,
    isInWatchlist: true,
  ),
  ScheduleRelease(
    title: 'Moon Harbor',
    mediaType: 'tv',
    releaseDate: DateTime(2026, 1, 27, 12),
    episodeNumber: 11,
    seasonNumber: 1,
    isInWatchlist: true,
  ),
  ScheduleRelease(
    title: 'Glass Orbit',
    mediaType: 'movie',
    releaseDate: DateTime(2026, 1, 28, 12),
    isInWatchlist: false,
  ),
  ScheduleRelease(
    title: 'Neon Relay',
    mediaType: 'anime',
    releaseDate: DateTime(2026, 1, 30, 20),
    episodeNumber: 6,
    seasonNumber: 1,
    hasPreciseTime: true,
    isInWatchlist: false,
  ),
];

class _WatchlistTab extends StatelessWidget {
  const _WatchlistTab({
    required this.selectedSort,
    required this.onSortChanged,
  });

  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionHeader(
                title: 'Watchlist',
                subtitle: 'Saved titles from your library',
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            DropdownButton<String>(
              value: selectedSort,
              items: const [
                DropdownMenuItem(
                  value: 'Recently Added',
                  child: Text('Recently Added'),
                ),
                DropdownMenuItem(value: 'Title', child: Text('Title')),
                DropdownMenuItem(
                  value: 'Release Date',
                  child: Text('Release Date'),
                ),
                DropdownMenuItem(value: 'Rating', child: Text('Rating')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSortChanged(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const WatchlistGrid(),
        const SizedBox(height: AppSpacing.xxl),
        const LibraryEmptyState(
          title: 'Your watchlist can appear here',
          message:
              'Mock data is shown above until watchlist storage is connected.',
        ),
      ],
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Downloads',
          subtitle: 'Active and completed downloads',
        ),
        SizedBox(height: AppSpacing.lg),
        DownloadsGrid(),
        SizedBox(height: AppSpacing.xxl),
        LibraryEmptyState(
          title: 'No queued downloads',
          message: 'Completed and in-progress mock downloads are listed above.',
        ),
      ],
    );
  }
}
