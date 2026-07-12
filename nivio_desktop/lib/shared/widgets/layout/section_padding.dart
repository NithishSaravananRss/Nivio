import 'package:flutter/material.dart';

import '../../theme/index.dart';

class SectionPadding extends StatelessWidget {
  const SectionPadding({super.key, required this.child, this.vertical = AppSpacing.xxl});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding(MediaQuery.sizeOf(context).width),
        vertical: vertical,
      ),
      child: child,
    );
  }
}

double _horizontalPadding(double width) {
  if (AppBreakpoints.isUltraWide(width)) {
    return AppSpacing.massive;
  }
  if (AppBreakpoints.isLarge(width)) {
    return AppSpacing.xxxl;
  }
  if (AppBreakpoints.isStandard(width)) {
    return AppSpacing.xxl;
  }
  return AppSpacing.xl;
}
