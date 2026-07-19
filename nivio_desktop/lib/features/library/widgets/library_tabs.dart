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
    return SegmentedButton<LibraryTab>(
      segments: [
        const ButtonSegment(
          value: LibraryTab.schedule,
          icon: Icon(LucideIcons.calendarDays),
          label: Text('Schedule'),
        ),
        ButtonSegment(
          value: LibraryTab.newEpisodes,
          icon: const Icon(LucideIcons.bell),
          label: _TabLabelWithBadge(label: 'New', count: unreadEpisodeCount),
        ),
        const ButtonSegment(
          value: LibraryTab.watchlist,
          icon: Icon(LucideIcons.heart),
          label: Text('Watchlist'),
        ),
        const ButtonSegment(
          value: LibraryTab.downloads,
          icon: Icon(LucideIcons.download),
          label: Text('Downloads'),
        ),
      ],
      selected: {selectedTab},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(AppTypography.caption),
      ),
      onSelectionChanged: (selection) => onTabSelected(selection.first),
    );
  }
}

class _TabLabelWithBadge extends StatelessWidget {
  const _TabLabelWithBadge({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: AppSpacing.xs),
        Container(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.small)),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: AppTypography.metadata.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
