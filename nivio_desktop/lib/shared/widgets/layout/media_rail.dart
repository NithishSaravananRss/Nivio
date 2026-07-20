import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../common/desktop_scrollbar.dart';

class MediaRail extends StatefulWidget {
  const MediaRail({
    super.key,
    required this.children,
    this.itemWidth = 320,
    this.height = 240,
    this.spacing = AppSpacing.lg,
    this.controller,
    this.thumbVisibility = false,
  });

  final List<Widget> children;
  final double itemWidth;
  final double height;
  final double spacing;
  final ScrollController? controller;
  final bool thumbVisibility;

  @override
  State<MediaRail> createState() => _MediaRailState();
}

class _MediaRailState extends State<MediaRail> {
  late final ScrollController _fallbackController = ScrollController();

  ScrollController get _controller => widget.controller ?? _fallbackController;

  @override
  void dispose() {
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rail = ListView.separated(
      controller: _controller,
      primary: false,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      itemCount: widget.children.length,
      separatorBuilder: (_, _) => SizedBox(width: widget.spacing),
      itemBuilder: (context, index) =>
          SizedBox(width: widget.itemWidth, child: widget.children[index]),
    );

    return SizedBox(
      height: widget.height,
      child: widget.thumbVisibility
          ? DesktopScrollbar(controller: _controller, child: rail)
          : rail,
    );
  }
}
