import 'package:flutter/material.dart';

import '../../theme/index.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 160,
    this.maxCrossAxisCount,
    this.mainAxisSpacing = AppSpacing.lg,
    this.crossAxisSpacing = AppSpacing.lg,
    this.childAspectRatio = AppBreakpoints.posterRatio,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int? maxCrossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final availableWidth = width.isFinite && width > 0 ? width : minItemWidth;
        var crossAxisCount = (availableWidth / minItemWidth).floor();
        crossAxisCount = crossAxisCount.clamp(1, maxCrossAxisCount ?? 12);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}
