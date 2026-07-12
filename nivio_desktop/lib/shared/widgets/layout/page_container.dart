import 'package:flutter/material.dart';

import '../../theme/index.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child, this.maxWidth = AppBreakpoints.contentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
