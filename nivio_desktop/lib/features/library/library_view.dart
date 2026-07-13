import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import 'models/library_models.dart';
import 'services/library_data_service.dart';
import 'widgets/downloads_grid.dart';
import 'widgets/library_empty_state.dart';
import 'widgets/library_tabs.dart';
import 'widgets/release_timeline.dart';
import 'widgets/schedule_calendar.dart';
import 'widgets/watchlist_grid.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key, this.onOpenDetail});

  final ValueChanged<String>? onOpenDetail;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final ScrollController _scrollController = ScrollController();
  final LibraryScheduleService _scheduleService = LibraryScheduleService();
  final LibraryWatchlistService _watchlistService = LibraryWatchlistService();
  final LibraryDownloadsService _downloadsService = LibraryDownloadsService();

  LibraryTab _selectedTab = LibraryTab.schedule;
  late DateTime _focusedDate;
  late DateTime _selectedScheduleDate;
  bool _watchlistOnly = true;
  late Future<LibrarySectionResult<List<LibraryScheduleItem>>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _selectedScheduleDate = _focusedDate;
    _scheduleFuture = _loadSchedule();
  }

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
              _buildSelectedTab(),
              const SizedBox(height: AppSpacing.massive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTab() {
    return switch (_selectedTab) {
      LibraryTab.schedule => _ScheduleTab(
        focusedDate: _focusedDate,
        selectedDate: _selectedScheduleDate,
        watchlistOnly: _watchlistOnly,
        scheduleFuture: _scheduleFuture,
        onPreviousWeek: () => _moveWeek(-1),
        onNextWeek: () => _moveWeek(1),
        onPickMonth: _showMonthPicker,
        onDateSelected: (date) {
          setState(() {
            _focusedDate = date;
            _selectedScheduleDate = date;
            _scheduleFuture = _loadSchedule();
          });
        },
        onFilterChanged: (value) {
          setState(() {
            _watchlistOnly = value;
            _scheduleFuture = _loadSchedule();
          });
        },
        onRetry: () => setState(() => _scheduleFuture = _loadSchedule()),
        onOpenDetail: widget.onOpenDetail,
      ),
      LibraryTab.watchlist => _WatchlistTab(
        service: _watchlistService,
        onOpenDetail: widget.onOpenDetail,
      ),
      LibraryTab.downloads => _DownloadsTab(
        service: _downloadsService,
        onOpenDetail: widget.onOpenDetail,
      ),
    };
  }

  Future<LibrarySectionResult<List<LibraryScheduleItem>>> _loadSchedule() {
    return _scheduleService.fetchForDate(
      _selectedScheduleDate,
      watchlistOnly: _watchlistOnly,
    );
  }

  void _moveWeek(int direction) {
    setState(() {
      _focusedDate = _focusedDate.add(Duration(days: 7 * direction));
    });
  }

  Future<void> _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() {
      _focusedDate = picked;
      _selectedScheduleDate = picked;
      _scheduleFuture = _loadSchedule();
    });
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({
    required this.focusedDate,
    required this.selectedDate,
    required this.watchlistOnly,
    required this.scheduleFuture,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onPickMonth,
    required this.onDateSelected,
    required this.onFilterChanged,
    required this.onRetry,
    this.onOpenDetail,
  });

  final DateTime focusedDate;
  final DateTime selectedDate;
  final bool watchlistOnly;
  final Future<LibrarySectionResult<List<LibraryScheduleItem>>> scheduleFuture;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onPickMonth;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<bool> onFilterChanged;
  final VoidCallback onRetry;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.standard;
        final calendar = ScheduleCalendar(
          focusedDate: focusedDate,
          selectedDate: selectedDate,
          onPreviousWeek: onPreviousWeek,
          onNextWeek: onNextWeek,
          onPickMonth: onPickMonth,
          onDateSelected: onDateSelected,
        );
        final filters = _ScheduleFilters(
          watchlistOnly: watchlistOnly,
          onFilterChanged: onFilterChanged,
        );
        final timeline =
            FutureBuilder<LibrarySectionResult<List<LibraryScheduleItem>>>(
              future: scheduleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Loading schedule...');
                }
                final result = snapshot.data;
                if (snapshot.hasError || result == null || result.hasError) {
                  return _SectionError(
                    title: result?.isOffline == true
                        ? 'Schedule unavailable offline'
                        : 'Schedule failed to load',
                    message: 'Retry to refresh releases for the selected date.',
                    onRetry: onRetry,
                  );
                }
                return ReleaseTimeline(
                  releases: result.data ?? const [],
                  watchlistOnly: watchlistOnly,
                  onOpenDetail: onOpenDetail,
                );
              },
            );

        if (isWide) {
          return Row(
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
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            calendar,
            const SizedBox(height: AppSpacing.lg),
            filters,
            const SizedBox(height: AppSpacing.xxl),
            timeline,
          ],
        );
      },
    );
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
            if (selected) onFilterChanged(true);
          },
        ),
        ChoiceChip(
          label: const Text('Discover'),
          selected: !watchlistOnly,
          onSelected: (selected) {
            if (selected) onFilterChanged(false);
          },
        ),
      ],
    );
  }
}

class _WatchlistTab extends StatelessWidget {
  const _WatchlistTab({required this.service, this.onOpenDetail});

  final LibraryWatchlistService service;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<LibraryWatchlistItem>>(
      valueListenable: service.listenable(),
      builder: (context, box, _) {
        return FutureBuilder<LibrarySectionResult<List<LibraryWatchlistItem>>>(
          future: service.getItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView(message: 'Loading watchlist...');
            }
            final result = snapshot.data;
            if (snapshot.hasError || result == null || result.hasError) {
              return _SectionError(
                title: 'Watchlist failed to load',
                message: 'Retry to read your saved titles.',
                onRetry: () {},
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'My Watchlist',
                  subtitle:
                      'Saved locally and ready for cloud sync when account sync is available.',
                ),
                const SizedBox(height: AppSpacing.lg),
                WatchlistGrid(
                  items: result.data ?? const [],
                  service: service,
                  onOpenDetail: onOpenDetail,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab({required this.service, this.onOpenDetail});

  final LibraryDownloadsService service;
  final ValueChanged<String>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<LibraryDownloadItem>>(
      valueListenable: service.listenable(),
      builder: (context, box, _) {
        return FutureBuilder<LibrarySectionResult<List<LibraryDownloadItem>>>(
          future: service.getItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView(message: 'Loading downloads...');
            }
            final result = snapshot.data;
            if (snapshot.hasError || result == null || result.hasError) {
              return _SectionError(
                title: 'Downloads failed to load',
                message: 'Retry to read local download records.',
                onRetry: () {},
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Downloads',
                  subtitle: 'Active and completed local downloads',
                ),
                const SizedBox(height: AppSpacing.lg),
                DownloadsGrid(
                  downloads: result.data ?? const [],
                  service: service,
                  onOpenDetail: onOpenDetail,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LibraryEmptyState(title: title, message: message),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
