import 'package:flutter/material.dart';

import '../../theme/index.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.minItemWidth = 170,
    this.mainAxisSpacing = AppSpacing.lg,
    this.crossAxisSpacing = AppSpacing.lg,
    this.childAspectRatio = AppBreakpoints.posterRatio,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final double minItemWidth;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: minItemWidth,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
