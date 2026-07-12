import 'package:flutter/material.dart';

import '../../theme/index.dart';

class AnimatedFadeContainer extends StatelessWidget {
  const AnimatedFadeContainer({
    super.key,
    required this.child,
    this.visible = true,
    this.duration = AppAnimation.fast,
    this.curve = AppAnimation.standard,
  });

  final Widget child;
  final bool visible;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: curve,
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}
