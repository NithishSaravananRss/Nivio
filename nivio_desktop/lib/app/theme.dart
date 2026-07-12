import 'package:flutter/material.dart';

/// Defines the baseline dark Material 3 theme for Nivio Desktop.
ThemeData buildNivioDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF34D399),
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF101214),
  );
}
