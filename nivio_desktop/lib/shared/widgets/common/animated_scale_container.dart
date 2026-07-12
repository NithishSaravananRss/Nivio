import 'package:flutter/material.dart';

import '../../theme/index.dart';

class AnimatedScaleContainer extends StatelessWidget {
  const AnimatedScaleContainer({
    super.key,
    required this.child,
    this.scale = 1,
    this.duration = AppAnimation.hover,
    this.curve = AppAnimation.standard,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}
