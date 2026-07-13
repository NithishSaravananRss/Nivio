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
  });

  final List<Widget> children;
  final double itemWidth;
  final double height;
  final double spacing;
  final ScrollController? controller;

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
    return SizedBox(
      height: widget.height,
      child: DesktopScrollbar(
        controller: _controller,
        child: ListView.separated(
          controller: _controller,
          primary: false,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: widget.children.length,
          separatorBuilder: (_, _) => SizedBox(width: widget.spacing),
          itemBuilder: (context, index) =>
              SizedBox(width: widget.itemWidth, child: widget.children[index]),
        ),
      ),
    );
  }
}
