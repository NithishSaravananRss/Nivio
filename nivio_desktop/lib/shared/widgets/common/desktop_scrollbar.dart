import 'package:flutter/material.dart';

import '../../theme/index.dart';

class DesktopScrollbar extends StatelessWidget {
  const DesktopScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thumbVisibility = true,
  });

  final Widget child;
  final ScrollController? controller;
  final bool thumbVisibility;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      thumbVisibility: controller != null ? thumbVisibility : false,
      interactive: true,
      thickness: AppSpacing.sm,
      radius: const Radius.circular(AppRadius.pill),
      child: child,
    );
  }
}
