import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Static sidebar placeholder for future desktop navigation.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key, this.isCompact = false});

  final bool isCompact;

  static const _items = [
    _SidebarItem(icon: Icons.home_outlined, label: 'Home'),
    _SidebarItem(icon: Icons.search, label: 'Search'),
    _SidebarItem(icon: Icons.favorite_border, label: 'Watchlist'),
    _SidebarItem(icon: Icons.history, label: 'History'),
    _SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
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
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) => _SidebarButton(item: _items[index]),
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
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) =>
            _SidebarButton(item: _items[index], isCompact: true),
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({required this.item, this.isCompact = false});

  final _SidebarItem item;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(item.icon, size: AppSpacing.xl),
      label: Text(item.label, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: AppColors.textPrimary,
        minimumSize: Size(
          isCompact
              ? AppBreakpoints.sidebarCollapsedWidth + AppSpacing.massive
              : double.infinity,
          AppSpacing.huge + AppSpacing.xs,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
