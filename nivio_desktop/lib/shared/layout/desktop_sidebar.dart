import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: isCompact
              ? BorderSide.none
              : BorderSide(color: colorScheme.outlineVariant),
          bottom: isCompact
              ? BorderSide(color: colorScheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      child: isCompact ? _buildCompactNav(context) : _buildSidebarNav(context),
    );
  }

  Widget _buildSidebarNav(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) => _SidebarButton(item: _items[index]),
    );
  }

  Widget _buildCompactNav(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: () {},
      icon: Icon(item.icon, size: 20),
      label: Text(item.label, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: colorScheme.onSurface,
        minimumSize: Size(isCompact ? 120 : double.infinity, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
