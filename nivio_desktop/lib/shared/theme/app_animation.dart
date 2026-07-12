import 'package:flutter/animation.dart';

/// Animation tokens for desktop interactions.
abstract final class AppAnimation {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 260);
  static const Duration hover = fast;
  static const Duration dialog = Duration(milliseconds: 220);
  static const Duration sidebar = medium;

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve linear = Curves.linear;
}
