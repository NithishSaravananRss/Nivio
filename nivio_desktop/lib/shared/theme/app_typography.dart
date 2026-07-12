import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text style tokens for the desktop design system.
abstract final class AppTypography {
  static const String fontFamily = 'Satoshi';

  static const TextStyle display = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle pageTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle metadata = TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: display,
    displayMedium: pageTitle,
    displaySmall: sectionTitle,
    headlineMedium: sectionTitle,
    titleLarge: title,
    titleMedium: title,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: title,
    labelMedium: metadata,
    labelSmall: metadata,
  );
}
