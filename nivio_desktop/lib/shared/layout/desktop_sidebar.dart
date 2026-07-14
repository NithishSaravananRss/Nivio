import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../theme/index.dart';
import '../widgets/buttons/icon_action_button.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    this.isCompact = false,
    this.isExpanded = true,
    this.selectedIndex = 0,
    this.onToggleExpanded,
    this.onDestinationSelected,
  });

  final bool isCompact;
  final bool isExpanded;
  final int selectedIndex;
  final VoidCallback? onToggleExpanded;
  final ValueChanged<int>? onDestinationSelected;

  static const _primaryItems = [
    _SidebarItem(icon: LucideIcons.house, label: 'Home', index: 0),
    _SidebarItem(icon: LucideIcons.search, label: 'Search', index: 1),
    _SidebarItem(icon: LucideIcons.libraryBig, label: 'Library', index: 2),
    _SidebarItem(icon: LucideIcons.tv, label: 'Live TV', index: 3),
    _SidebarItem(icon: LucideIcons.partyPopper, label: 'Party', index: 4),
  ];

  static const _bottomItems = [
    _SidebarItem(icon: LucideIcons.user, label: 'Profile', index: 5),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: isCompact
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderSubtle),
          bottom: isCompact
              ? const BorderSide(color: AppColors.borderSubtle)
              : BorderSide.none,
        ),
      ),
      child: isCompact ? _buildCompactNav(context) : _buildSidebarNav(context),
    );
  }

  Widget _buildSidebarNav(BuildContext context) {
    final showLabels = isExpanded;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(
            isExpanded: showLabels,
            onToggleExpanded: onToggleExpanded,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final item in _primaryItems) ...[
            _SidebarButton(
              item: item,
              showLabel: showLabels,
              isSelected: item.index == selectedIndex,
              onPressed: onDestinationSelected == null
                  ? null
                  : () => onDestinationSelected!(item.index),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const Spacer(),
          if (_bottomItems.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            for (final item in _bottomItems) ...[
              _SidebarButton(
                item: item,
                showLabel: showLabels,
                isSelected: item.index == selectedIndex,
                onPressed: onDestinationSelected == null
                    ? null
                    : () => onDestinationSelected!(item.index),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompactNav(BuildContext context) {
    return SizedBox(
      height: AppBreakpoints.topbarHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: _primaryItems.length + _bottomItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final items = [..._primaryItems, ..._bottomItems];
          final item = items[index];
          return _SidebarButton(
            item: item,
            isCompact: true,
            showLabel: false,
            isSelected: item.index == selectedIndex,
            onPressed: onDestinationSelected == null
                ? null
                : () => onDestinationSelected!(item.index),
          );
        },
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isExpanded)
          Expanded(
            child: Text(
              'Nivio',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
            ),
          )
        else
          const Spacer(),
        IconActionButton(
          icon: Icon(
            isExpanded ? LucideIcons.panelLeftClose : LucideIcons.panelLeftOpen,
          ),
          semanticLabel: isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
          tooltip: isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
          onPressed: onToggleExpanded,
        ),
      ],
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.item,
    this.isCompact = false,
    this.showLabel = true,
    this.isSelected = false,
    this.onPressed,
  });

  final _SidebarItem item;
  final bool isCompact;
  final bool showLabel;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final button = TextButton.icon(
      onPressed: onPressed,
      icon: Icon(item.icon, size: AppSpacing.xl),
      label: showLabel
          ? Text(item.label, overflow: TextOverflow.ellipsis)
          : const SizedBox.shrink(),
      style: TextButton.styleFrom(
        backgroundColor: isSelected
            ? AppColors.sidebarSelected
            : Colors.transparent,
        alignment: showLabel ? Alignment.centerLeft : Alignment.center,
        foregroundColor: AppColors.textPrimary,
        minimumSize: Size(
          isCompact
              ? AppBreakpoints.sidebarCollapsedWidth
              : showLabel
              ? double.infinity
              : AppBreakpoints.sidebarCollapsedWidth - AppSpacing.lg,
          AppSpacing.huge + AppSpacing.xs,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? AppSpacing.lg : AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(
            color: isSelected ? AppColors.borderStrong : Colors.transparent,
          ),
        ),
      ),
    );

    return Tooltip(message: item.label, child: button);
  }
}

class _SidebarItem {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final String label;
  final int index;
}
