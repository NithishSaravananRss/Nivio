import 'package:flutter/material.dart';

import '../../theme/index.dart';
import '../common/desktop_scrollbar.dart';

class MediaRail extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DesktopScrollbar(
        controller: controller,
        child: ListView.separated(
          controller: controller,
          primary: false,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: children.length,
          separatorBuilder: (_, _) => SizedBox(width: spacing),
          itemBuilder: (context, index) => SizedBox(width: itemWidth, child: children[index]),
        ),
      ),
    );
  }
}
