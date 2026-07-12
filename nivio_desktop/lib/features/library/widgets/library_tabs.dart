import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../shared/theme/index.dart';

enum LibraryTab { schedule, watchlist, downloads }

class LibraryTabs extends StatelessWidget {
  const LibraryTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final LibraryTab selectedTab;
  final ValueChanged<LibraryTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LibraryTab>(
      segments: const [
        ButtonSegment(
          value: LibraryTab.schedule,
          icon: Icon(LucideIcons.calendarDays),
          label: Text('Schedule'),
        ),
        ButtonSegment(
          value: LibraryTab.watchlist,
          icon: Icon(LucideIcons.heart),
          label: Text('Watchlist'),
        ),
        ButtonSegment(
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
