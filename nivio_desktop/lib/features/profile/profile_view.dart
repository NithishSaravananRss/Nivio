import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../shared/theme/index.dart';
import '../../shared/widgets/feedback/error_view.dart';
import '../../shared/widgets/feedback/loading_view.dart';
import '../library/models/library_models.dart';
import '../library/services/library_data_service.dart';
import '../library/services/library_persistence.dart';
import '../settings/settings_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.onOpenDetail,
    this.onHomeLayoutChanged,
  });

  final ValueChanged<String> onOpenDetail;
  final VoidCallback? onHomeLayoutChanged;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _controller = _ProfileController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _query = '';

  static const List<_ProfileCategory> _categories = [
    _ProfileCategory('Profile & Activity', LucideIcons.circleUserRound, null),
    _ProfileCategory('Playback', LucideIcons.play, 'playback'),
    _ProfileCategory('Subtitle Appearance', LucideIcons.subtitles, 'subtitles'),
    _ProfileCategory('Downloads', LucideIcons.download, 'downloads'),
    _ProfileCategory('Content Feed', LucideIcons.rows3, 'home'),
    _ProfileCategory('Episode Alerts', LucideIcons.bell, 'episodes'),
    _ProfileCategory('App & Updates', LucideIcons.info, 'app'),
    _ProfileCategory('Data & Account', LucideIcons.database, 'data'),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onProfileChanged);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.removeListener(_onProfileChanged);
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return switch (state.status) {
      _ProfileStatus.loading => const LoadingView(
        title: 'Loading Profile',
        message: 'Reading local account, activity, and library data.',
      ),
      _ProfileStatus.error => ErrorView(
        title: 'Profile unavailable',
        message: state.error ?? 'Unable to load profile data.',
        onRetry: _controller.load,
      ),
      _ProfileStatus.ready => _ProfileContent(
        state: state,
        categories: _categories,
        selectedCategoryIndex: _selectedCategoryIndex,
        query: _query,
        searchController: _searchController,
        onCategorySelected: (index) {
          setState(() {
            _selectedCategoryIndex = index;
            _query = '';
            _searchController.clear();
          });
        },
        onQueryChanged: (value) => setState(() => _query = value.trim()),
        onOpenDetail: widget.onOpenDetail,
        onHomeLayoutChanged: widget.onHomeLayoutChanged,
      ),
    };
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.state,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.query,
    required this.searchController,
    required this.onCategorySelected,
    required this.onQueryChanged,
    required this.onOpenDetail,
    this.onHomeLayoutChanged,
  });

  final _ProfileState state;
  final List<_ProfileCategory> categories;
  final int selectedCategoryIndex;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onOpenDetail;
  final VoidCallback? onHomeLayoutChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.background],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          final selectedCategory = categories[selectedCategoryIndex];
          final activeFilter = query.isEmpty ? selectedCategory.filter : null;
          final content = _ProfileCategoryContent(
            state: state,
            showActivity: query.isEmpty
                ? selectedCategory.filter == null
                : _matchesProfileQuery(query),
            settingsSectionFilter: activeFilter,
            settingsQuery: query,
            onOpenDetail: onOpenDetail,
            onHomeLayoutChanged: onHomeLayoutChanged,
          );

          if (!desktop) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(
                          watchlistCount: state.watchlist.length,
                          historyCount: state.history.length,
                          completedCount: state.completedCount,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _ProfileSearchField(
                          controller: searchController,
                          query: query,
                          onChanged: onQueryChanged,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ProfileCategoryWrap(
                          categories: categories,
                          selectedIndex: selectedCategoryIndex,
                          onSelected: onCategorySelected,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(child: content),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.massive),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 280,
                child: _ProfileCategoryRail(
                  state: state,
                  categories: categories,
                  selectedIndex: selectedCategoryIndex,
                  searchController: searchController,
                  query: query,
                  onCategorySelected: onCategorySelected,
                  onQueryChanged: onQueryChanged,
                  showSearch: false,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query.isEmpty
                            ? selectedCategory.label
                            : 'Search Results',
                        style: AppTypography.pageTitle,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: _ProfileDesktopContentCard(
                            key: ValueKey(
                              '${selectedCategory.label}-${query.hashCode}',
                            ),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _matchesProfileQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return 'profile activity watchlist watched completed history account guest'
        .contains(normalized);
  }
}

class _ProfileCategory {
  const _ProfileCategory(this.label, this.icon, this.filter);

  final String label;
  final IconData icon;
  final String? filter;
}

class _ProfileCategoryRail extends StatelessWidget {
  const _ProfileCategoryRail({
    required this.state,
    required this.categories,
    required this.selectedIndex,
    required this.searchController,
    required this.query,
    required this.onCategorySelected,
    required this.onQueryChanged,
    this.showSearch = true,
  });

  final _ProfileState state;
  final List<_ProfileCategory> categories;
  final int selectedIndex;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<String> onQueryChanged;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(
              watchlistCount: state.watchlist.length,
              historyCount: state.history.length,
              completedCount: state.completedCount,
              compact: true,
            ),
            if (showSearch) ...[
              const SizedBox(height: AppSpacing.xl),
              _ProfileSearchField(
                controller: searchController,
                query: query,
                onChanged: onQueryChanged,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  return _ProfileCategoryButton(
                    category: categories[index],
                    selected: query.isEmpty && selectedIndex == index,
                    onTap: () => onCategorySelected(index),
                    showIcon: showSearch,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCategoryWrap extends StatelessWidget {
  const _ProfileCategoryWrap({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ProfileCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var index = 0; index < categories.length; index++)
          _ProfileCategoryButton(
            category: categories[index],
            selected: selectedIndex == index,
            onTap: () => onSelected(index),
          ),
      ],
    );
  }
}

class _ProfileCategoryButton extends StatelessWidget {
  const _ProfileCategoryButton({
    required this.category,
    required this.selected,
    required this.onTap,
    this.showIcon = true,
  });

  final _ProfileCategory category;
  final bool selected;
  final VoidCallback onTap;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  category.icon,
                  size: 18,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSearchField extends StatelessWidget {
  const _ProfileSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      cursorColor: AppColors.textPrimary,
      decoration: InputDecoration(
        hintText: 'Search profile settings...',
        prefixIcon: const Icon(LucideIcons.search, size: 19),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(LucideIcons.x, size: 18),
              ),
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
      ),
    );
  }
}

class _ProfileCategoryContent extends StatelessWidget {
  const _ProfileCategoryContent({
    required this.state,
    required this.showActivity,
    required this.settingsSectionFilter,
    required this.settingsQuery,
    required this.onOpenDetail,
    this.onHomeLayoutChanged,
  });

  final _ProfileState state;
  final bool showActivity;
  final String? settingsSectionFilter;
  final String settingsQuery;
  final ValueChanged<String> onOpenDetail;
  final VoidCallback? onHomeLayoutChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showActivity) ...[
          _SummaryGrid(state: state, onOpenDetail: onOpenDetail),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (settingsSectionFilter != null || settingsQuery.trim().isNotEmpty)
          SettingsView(
            embedded: true,
            showHeader: false,
            sectionFilter: settingsSectionFilter,
            query: settingsQuery,
            onHomeLayoutChanged: onHomeLayoutChanged,
          ),
      ],
    );
  }
}

class _ProfileDesktopContentCard extends StatelessWidget {
  const _ProfileDesktopContentCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Material(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.watchlistCount,
    required this.historyCount,
    required this.completedCount,
    this.compact = false,
  });

  final int watchlistCount;
  final int historyCount;
  final int completedCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout = compact || constraints.maxWidth < 760;
        if (compact) {
          return Column(
            children: [
              const _Avatar(size: 76, iconSize: 36),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Nivio Guest',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Guest account',
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ],
          );
        }

        final stats = _StatsStrip(
          stats: [
            _StatData(
              'Watchlist',
              watchlistCount.toString(),
              LucideIcons.bookmark,
            ),
            _StatData('Watched', historyCount.toString(), LucideIcons.history),
            _StatData(
              'Completed',
              completedCount.toString(),
              LucideIcons.badgeCheck,
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.xl,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _Avatar(),
                SizedBox(
                  width: compactLayout ? constraints.maxWidth : 360,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nivio Guest', style: AppTypography.display),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Guest account', style: AppTypography.body),
                    ],
                  ),
                ),
                if (!compactLayout)
                  SizedBox(
                    width: (constraints.maxWidth - 560).clamp(420, 620),
                    child: stats,
                  ),
              ],
            ),
            if (compactLayout) ...[
              const SizedBox(height: AppSpacing.xl),
              stats,
            ],
          ],
        );
      },
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.state, required this.onOpenDetail});

  final _ProfileState state;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 780 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          childAspectRatio: columns == 1 ? 2.8 : 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ActivityPanel(
              title: 'Recent Activity',
              emptyTitle: 'No recent activity',
              emptyMessage: 'Recently watched titles will appear here.',
              entries: state.history.take(4).toList(),
              onOpenDetail: onOpenDetail,
            ),
            _WatchlistPanel(
              items: state.watchlist.take(6).toList(),
              totalCount: state.watchlist.length,
              onOpenDetail: onOpenDetail,
            ),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: AppTypography.title)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.entries,
    required this.onOpenDetail,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final List<_HistoryEntry> entries;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      icon: LucideIcons.clock3,
      child: entries.isEmpty
          ? _InlineEmpty(title: emptyTitle, message: emptyMessage)
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _MediaRow(
                  title: entry.title,
                  subtitle: entry.subtitle,
                  posterPath: entry.posterPath,
                  trailing: '${(entry.progress * 100).clamp(0, 100).round()}%',
                  onTap: () =>
                      onOpenDetail('${entry.mediaType}:${entry.tmdbId}'),
                );
              },
            ),
    );
  }
}

class _WatchlistPanel extends StatelessWidget {
  const _WatchlistPanel({
    required this.items,
    required this.totalCount,
    required this.onOpenDetail,
  });

  final List<LibraryWatchlistItem> items;
  final int totalCount;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Watchlist',
      icon: LucideIcons.bookmark,
      child: items.isEmpty
          ? const _InlineEmpty(
              title: 'Watchlist is empty',
              message: 'Saved movies and shows will appear here.',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _MediaRow(
                        title: item.title,
                        subtitle: _typeLabel(item.mediaType),
                        posterPath: item.posterPath,
                        trailing: item.voteAverage?.toStringAsFixed(1),
                        onTap: () =>
                            onOpenDetail('${item.mediaType}:${item.id}'),
                      );
                    },
                  ),
                ),
                if (totalCount > items.length)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+${totalCount - items.length} more saved',
                        style: AppTypography.caption,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// Retained for the library data model, but intentionally not shown in Profile.
// ignore: unused_element
class _DownloadsPanel extends StatelessWidget {
  const _DownloadsPanel({required this.downloads});

  final List<_DownloadSummaryItem> downloads;

  @override
  Widget build(BuildContext context) {
    final completed = downloads
        .where((item) => item.status == LibraryDownloadStatus.completed)
        .length;
    final active = downloads
        .where(
          (item) =>
              item.status == LibraryDownloadStatus.pending ||
              item.status == LibraryDownloadStatus.downloading ||
              item.status == LibraryDownloadStatus.extracting,
        )
        .length;
    final failed = downloads
        .where((item) => item.status == LibraryDownloadStatus.failed)
        .length;
    final bytes = downloads.fold<int>(
      0,
      (sum, item) => sum + (item.fileSizeBytes ?? 0),
    );

    return _Panel(
      title: 'Downloads',
      icon: LucideIcons.download,
      child: downloads.isEmpty
          ? const _InlineEmpty(
              title: 'No downloads',
              message: 'Local download status will appear here.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _MiniMetric(label: 'Completed', value: '$completed'),
                    _MiniMetric(label: 'Active', value: '$active'),
                    _MiniMetric(label: 'Failed', value: '$failed'),
                    _MiniMetric(label: 'Storage', value: _formatBytes(bytes)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView.separated(
                    itemCount: downloads.take(4).length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = downloads[index];
                      return _MediaRow(
                        title: item.displayTitle,
                        subtitle: _downloadStatusLabel(item.status),
                        posterPath: item.posterPath,
                        trailing:
                            item.status == LibraryDownloadStatus.downloading
                            ? '${(item.progress * 100).round()}%'
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ignore: unused_element
class _LibraryBreakdownPanel extends StatelessWidget {
  const _LibraryBreakdownPanel({required this.state});

  final _ProfileState state;

  @override
  Widget build(BuildContext context) {
    final movies = state.watchlist
        .where((item) => item.mediaType.toLowerCase() == 'movie')
        .length;
    final shows = state.watchlist
        .where((item) => item.mediaType.toLowerCase() != 'movie')
        .length;
    return _Panel(
      title: 'Library Summary',
      icon: LucideIcons.library,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LargeMetric(
            label: 'Saved titles',
            value: '${state.watchlist.length}',
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MiniMetric(label: 'Movies', value: '$movies'),
              _MiniMetric(label: 'Shows', value: '$shows'),
              _MiniMetric(
                label: 'Downloads',
                value: '${state.downloads.length}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            state.watchlist.isEmpty
                ? 'Your library is ready for saved titles.'
                : 'Newest saved: ${state.watchlist.first.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AccountInfoPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'Account Information',
      icon: LucideIcons.userRoundCog,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Status', value: 'Guest'),
          _InfoRow(label: 'Email', value: 'Not signed in'),
          _InfoRow(label: 'Sync', value: 'Local only'),
          _InfoRow(
            label: 'Authentication',
            value: 'Desktop sign-in unavailable',
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.historyCount,
    required this.watchlistCount,
    required this.downloadCount,
  });

  final int historyCount;
  final int watchlistCount;
  final int downloadCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: AppColors.success),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Guest mode stores $historyCount watched, $watchlistCount saved, and $downloadCount downloaded records on this desktop.',
                style: AppTypography.body,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(LucideIcons.logIn),
              label: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.title,
    required this.subtitle,
    this.posterPath,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? posterPath;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.small),
              child: SizedBox(
                width: 42,
                height: 58,
                child: _PosterImage(path: posterPath),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(trailing!, style: AppTypography.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _posterUrl(path);
    if (imageUrl == null) {
      return const ColoredBox(
        color: AppColors.surfaceVariant,
        child: Icon(LucideIcons.film, color: AppColors.textMuted, size: 18),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.surfaceVariant,
        child: Icon(LucideIcons.film, color: AppColors.textMuted, size: 18),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 104, this.iconSize = 46});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Icon(
        LucideIcons.userRound,
        color: AppColors.textPrimary,
        size: iconSize,
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.stats});

  final List<_StatData> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: stats
          .map((stat) => SizedBox(width: 132, child: _StatTile(stat: stat)))
          .toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stat.icon, color: AppColors.textMuted, size: 18),
            const SizedBox(height: AppSpacing.md),
            Text(stat.value, style: AppTypography.pageTitle),
            Text(stat.label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.inbox, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: AppTypography.title),
            Text(label, style: AppTypography.metadata),
          ],
        ),
      ),
    );
  }
}

class _LargeMetric extends StatelessWidget {
  const _LargeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.display),
        Text(label, style: AppTypography.caption),
      ],
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: AppTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileController extends ChangeNotifier {
  _ProfileState state = const _ProfileState.loading();

  final _watchlistService = LibraryWatchlistService();
  final _downloadsService = LibraryDownloadsService();
  final List<ValueListenable<dynamic>> _listenables = [];
  Box<String>? _historyBox;

  Future<void> load() async {
    state = const _ProfileState.loading();
    notifyListeners();

    try {
      await LibraryPersistence.init();
      _historyBox ??= await Hive.openBox<String>('watch_history');
      _attachBoxListeners();
      state = _ProfileState.ready(
        watchlist: await _loadWatchlist(),
        downloads: await _loadDownloads(),
        history: _loadHistory(),
      );
    } catch (error) {
      state = _ProfileState.error(error.toString());
    }
    notifyListeners();
  }

  Future<List<LibraryWatchlistItem>> _loadWatchlist() async {
    final result = await _watchlistService.getItems();
    if (result.hasError) throw result.error!;
    return result.data ?? const [];
  }

  Future<List<_DownloadSummaryItem>> _loadDownloads() async {
    final result = await _downloadsService.getItems();
    if (result.hasError) throw result.error!;
    return (result.data ?? const <LibraryDownloadItem>[])
        .map(
          (item) => _DownloadSummaryItem(
            item: item,
            fileSizeBytes: _downloadsService.fileSizeBytes(item),
          ),
        )
        .toList();
  }

  List<_HistoryEntry> _loadHistory() {
    final box = _historyBox;
    if (box == null) return const [];
    final entries = <_HistoryEntry>[];
    for (final encoded in box.values) {
      final parsed = _HistoryEntry.tryParse(encoded);
      if (parsed != null) entries.add(parsed);
    }
    entries.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
    return entries;
  }

  void _attachBoxListeners() {
    if (_listenables.isNotEmpty) return;
    final history = _historyBox;
    if (LibraryPersistence.isReady) {
      _listenables.add(_watchlistService.listenable());
      _listenables.add(_downloadsService.listenable());
    }
    if (history != null) _listenables.add(history.listenable());
    for (final listenable in _listenables) {
      listenable.addListener(_reloadFromBoxes);
    }
  }

  void _reloadFromBoxes() {
    if (state.status != _ProfileStatus.ready) return;
    final watchlist = LibraryPersistence.isReady
        ? (LibraryPersistence.watchlistBox.values.toList()
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt)))
        : <LibraryWatchlistItem>[];
    final downloads = LibraryPersistence.isReady
        ? (LibraryPersistence.downloadsBox.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        : <LibraryDownloadItem>[];
    state = _ProfileState.ready(
      watchlist: watchlist,
      downloads: downloads
          .map(
            (item) => _DownloadSummaryItem(
              item: item,
              fileSizeBytes: _downloadsService.fileSizeBytes(item),
            ),
          )
          .toList(),
      history: _loadHistory(),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final listenable in _listenables) {
      listenable.removeListener(_reloadFromBoxes);
    }
    super.dispose();
  }
}

enum _ProfileStatus { loading, ready, error }

class _ProfileState {
  const _ProfileState._({
    required this.status,
    this.watchlist = const [],
    this.downloads = const [],
    this.history = const [],
    this.error,
  });

  const _ProfileState.loading() : this._(status: _ProfileStatus.loading);

  const _ProfileState.error(String error)
    : this._(status: _ProfileStatus.error, error: error);

  const _ProfileState.ready({
    required List<LibraryWatchlistItem> watchlist,
    required List<_DownloadSummaryItem> downloads,
    required List<_HistoryEntry> history,
  }) : this._(
         status: _ProfileStatus.ready,
         watchlist: watchlist,
         downloads: downloads,
         history: history,
       );

  final _ProfileStatus status;
  final List<LibraryWatchlistItem> watchlist;
  final List<_DownloadSummaryItem> downloads;
  final List<_HistoryEntry> history;
  final String? error;

  int get completedCount => history.where((entry) => entry.isCompleted).length;

  List<_HistoryEntry> get continueWatching => history
      .where((entry) => !entry.isCompleted)
      .take(10)
      .toList(growable: false);
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.currentSeason,
    required this.currentEpisode,
    required this.progress,
    required this.lastWatchedAt,
    required this.isCompleted,
    this.posterPath,
  });

  final int tmdbId;
  final String mediaType;
  final String title;
  final int currentSeason;
  final int currentEpisode;
  final double progress;
  final DateTime lastWatchedAt;
  final bool isCompleted;
  final String? posterPath;

  String get subtitle {
    final date = DateFormat.yMMMd().add_jm().format(lastWatchedAt);
    if (mediaType == 'tv' || mediaType == 'anime') {
      return 'S$currentSeason E$currentEpisode | $date';
    }
    return date;
  }

  static _HistoryEntry? tryParse(String encoded) {
    try {
      final decoded = _decodeHistoryJson(encoded);
      return _HistoryEntry(
        tmdbId: decoded['tmdbId'] as int,
        mediaType: decoded['mediaType']?.toString() ?? 'movie',
        title: decoded['title']?.toString() ?? 'Untitled',
        currentSeason: (decoded['currentSeason'] as num?)?.toInt() ?? 0,
        currentEpisode: (decoded['currentEpisode'] as num?)?.toInt() ?? 0,
        progress: (decoded['progressPercent'] as num?)?.toDouble() ?? 0,
        lastWatchedAt: _parseDate(decoded['lastWatchedAt']),
        isCompleted: decoded['isCompleted'] == true,
        posterPath: decoded['posterPath']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}

class _DownloadSummaryItem {
  const _DownloadSummaryItem({required this.item, this.fileSizeBytes});

  final LibraryDownloadItem item;
  final int? fileSizeBytes;

  String? get posterPath {
    final parts = item.posterPath?.split('|||') ?? const [];
    if (parts.isEmpty) return null;
    return parts.length > 1 ? parts.last : parts.first;
  }

  String get displayTitle {
    final parts = item.title.split('|||');
    if (parts.length > 1) return '${parts.first} - ${parts.last}';
    return item.title;
  }

  LibraryDownloadStatus get status => item.status;
  double get progress => item.progress;
}

class _StatData {
  const _StatData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

Map<String, dynamic> _decodeHistoryJson(String encoded) {
  final decoded = jsonDecode(encoded);
  if (decoded is! Map) return const {};
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}

DateTime _parseDate(Object? raw) {
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is Map) {
    final seconds = (raw['_seconds'] as num?)?.toInt();
    final nanos = (raw['_nanoseconds'] as num?)?.toInt() ?? 0;
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + nanos ~/ 1000000,
      );
    }
  }
  return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime(1970);
}

String _typeLabel(String mediaType) {
  return switch (mediaType.toLowerCase()) {
    'tv' => 'TV Show',
    'anime' => 'Anime',
    'movie' => 'Movie',
    _ => mediaType,
  };
}

String _downloadStatusLabel(LibraryDownloadStatus status) {
  return switch (status) {
    LibraryDownloadStatus.pending => 'Pending',
    LibraryDownloadStatus.downloading => 'Downloading',
    LibraryDownloadStatus.completed => 'Completed',
    LibraryDownloadStatus.failed => 'Failed',
    LibraryDownloadStatus.paused => 'Paused',
    LibraryDownloadStatus.extracting => 'Extracting',
  };
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(unit < 2 ? 0 : 1)} ${units[unit]}';
}

String? _posterUrl(String? path) {
  final value = path?.trim();
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  return 'https://image.tmdb.org/t/p/w200$value';
}
