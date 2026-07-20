import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../theme/index.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    this.isCompact = false,
    this.isExpanded = true,
    this.selectedIndex = 0,
    this.onToggleExpanded,
    this.onItemHoverChanged,
    this.onDestinationSelected,
  });

  static const double preferredWidth = 92;
  static const double expandedWidth = 236;

  final bool isCompact;
  final bool isExpanded;
  final int selectedIndex;
  final VoidCallback? onToggleExpanded;
  final ValueChanged<bool>? onItemHoverChanged;
  final ValueChanged<int>? onDestinationSelected;

  static const _items = [
    _SidebarItem(icon: LucideIcons.house, label: 'Home', index: 0),
    _SidebarItem(icon: LucideIcons.search, label: 'Search', index: 1),
    _SidebarItem(icon: LucideIcons.libraryBig, label: 'Library', index: 2),
    _SidebarItem(icon: LucideIcons.tvMinimal, label: 'Live TV', index: 3),
    _SidebarItem(icon: LucideIcons.partyPopper, label: 'Party', index: 4),
    _SidebarItem(icon: LucideIcons.circleUserRound, label: 'Profile', index: 5),
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onItemHoverChanged?.call(true),
      onExit: (_) => onItemHoverChanged?.call(false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xF203050A),
              Color(0xD903050A),
              Color(0x8C03050A),
              Color(0x3303050A),
              Colors.transparent,
            ],
            stops: [0, 0.42, 0.68, 0.88, 1],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 36,
              spreadRadius: -8,
              offset: Offset(14, 0),
            ),
          ],
        ),
        child: SizedBox(
          width: isExpanded ? expandedWidth : preferredWidth,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? AppSpacing.lg : AppSpacing.md,
                vertical: AppSpacing.xxxl,
              ),
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      _SidebarIconButton(
                        item: _items[i],
                        selected: _items[i].index == selectedIndex,
                        expanded: isExpanded,
                        order: i.toDouble(),
                        onPressed: onDestinationSelected == null
                            ? null
                            : () => onDestinationSelected!(_items[i].index),
                      ),
                      if (i != _items.length - 1)
                        const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarIconButton extends StatefulWidget {
  const _SidebarIconButton({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.order,
    this.onPressed,
  });

  final _SidebarItem item;
  final bool selected;
  final bool expanded;
  final double order;
  final VoidCallback? onPressed;

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered || _focused;
    final color = active ? AppColors.textPrimary : AppColors.textMuted;

    return FocusTraversalOrder(
      order: NumericFocusOrder(widget.order),
      child: Tooltip(
        message: widget.item.label,
        waitDuration: const Duration(milliseconds: 350),
        child: FocusableActionDetector(
          onShowHoverHighlight: (value) {
            setState(() => _hovered = value);
          },
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          child: Semantics(
            button: true,
            selected: widget.selected,
            label: widget.item.label,
            child: _SidebarTapTarget(
              item: widget.item,
              selected: widget.selected,
              expanded: widget.expanded,
              hovered: _hovered,
              focused: _focused,
              color: color,
              onPressed: widget.onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarTapTarget extends StatelessWidget {
  const _SidebarTapTarget({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.hovered,
    required this.focused,
    required this.color,
    this.onPressed,
  });

  final _SidebarItem item;
  final bool selected;
  final bool expanded;
  final bool hovered;
  final bool focused;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final active = selected || hovered || focused;
    final buttonWidth = expanded ? 184.0 : 56.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('desktop_sidebar_${item.index}'),
        onTap: onPressed,
        mouseCursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: AnimatedScale(
          scale: active ? 1.07 : 1,
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: AppAnimation.hover,
            curve: AppAnimation.standard,
            width: buttonWidth,
            height: 48,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(
              left: expanded ? AppSpacing.md : 4,
              right: expanded ? AppSpacing.md : 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: focused
                  ? Border.all(color: Colors.white.withValues(alpha: 0.36))
                  : null,
            ),
            child: Stack(
              children: [
                _SelectionBloom(visible: active),
                _ActiveEdge(visible: selected),
                ClipRect(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _NavIconHalo(
                        icon: item.icon,
                        color: color,
                        active: active,
                      ),
                      Flexible(
                        child: _SidebarLabel(
                          label: item.label,
                          expanded: expanded,
                          color: color,
                          selected: selected,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIconHalo extends StatelessWidget {
  const _NavIconHalo({
    required this.icon,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.hover,
      curve: AppAnimation.standard,
      width: 48,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Color(0x66FFFFFF),
                  blurRadius: 24,
                  spreadRadius: -14,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            Icon(icon, size: 25, color: color.withValues(alpha: 0.18)),
          Icon(icon, size: 22, color: color),
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel({
    required this.label,
    required this.expanded,
    required this.color,
    required this.selected,
  });

  final String label;
  final bool expanded;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: AppAnimation.sidebar,
        curve: AppAnimation.emphasized,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: expanded ? 112 : 0,
          child: AnimatedOpacity(
            opacity: expanded ? 1 : 0,
            duration: AppAnimation.sidebar,
            curve: AppAnimation.standard,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTypography.title.copyWith(
                  fontSize: 15,
                  letterSpacing: 0,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                  shadows: selected
                      ? const [Shadow(color: Color(0x99FFFFFF), blurRadius: 18)]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionBloom extends StatelessWidget {
  const _SelectionBloom({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: AppAnimation.hover,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment.centerLeft,
                radius: 1.15,
                colors: [
                  Color(0x22FFFFFF),
                  Color(0x120A84FF),
                  Color(0x00000000),
                ],
                stops: [0, 0.48, 1],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveEdge extends StatelessWidget {
  const _ActiveEdge({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 12,
      bottom: 12,
      child: AnimatedContainer(
        duration: AppAnimation.hover,
        curve: AppAnimation.standard,
        width: visible ? 3 : 0,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: visible
              ? const [
                  BoxShadow(
                    color: Color(0xAAFFFFFF),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
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
