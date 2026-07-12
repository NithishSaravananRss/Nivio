import 'package:flutter/material.dart';

/// Subtle shadow tokens for dark desktop surfaces.
abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> hover = [
    BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> popover = [
    BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static const List<BoxShadow> dialog = [
    BoxShadow(color: Color(0x99000000), blurRadius: 32, offset: Offset(0, 18)),
  ];
}
