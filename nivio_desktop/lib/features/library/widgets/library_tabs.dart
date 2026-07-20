import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../shared/theme/index.dart';

enum LibraryTab { schedule, newEpisodes, watchlist, downloads }

class LibraryTabs extends StatelessWidget {
  const LibraryTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.unreadEpisodeCount = 0,
  });

  final LibraryTab selectedTab;
  final ValueChanged<LibraryTab> onTabSelected;
  final int unreadEpisodeCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _LibraryTabButton(
              tab: LibraryTab.schedule,
              selectedTab: selectedTab,
              icon: LucideIcons.calendarDays,
              label: 'Schedule',
              onTap: onTabSelected,
            ),
            _LibraryTabButton(
              tab: LibraryTab.newEpisodes,
              selectedTab: selectedTab,
              icon: LucideIcons.bell,
              label: 'New',
              badgeCount: unreadEpisodeCount,
              onTap: onTabSelected,
            ),
            _LibraryTabButton(
              tab: LibraryTab.watchlist,
              selectedTab: selectedTab,
              icon: LucideIcons.heart,
              label: 'Watchlist',
              onTap: onTabSelected,
            ),
            _LibraryTabButton(
              tab: LibraryTab.downloads,
              selectedTab: selectedTab,
              icon: LucideIcons.download,
              label: 'Downloads',
              onTap: onTabSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTabButton extends StatelessWidget {
  const _LibraryTabButton({
    required this.tab,
    required this.selectedTab,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final LibraryTab tab;
  final LibraryTab selectedTab;
  final IconData icon;
  final String label;
  final int badgeCount;
  final ValueChanged<LibraryTab> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedTab == tab;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: () => onTap(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 36,
          constraints: const BoxConstraints(minWidth: 112),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: selected
                  ? AppColors.secondary
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                _TabBadge(count: badgeCount, selected: selected),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.22)
            : AppColors.selectionFill,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppTypography.metadata.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
