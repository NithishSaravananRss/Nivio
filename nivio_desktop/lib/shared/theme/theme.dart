import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the dark Material 3 desktop theme for Nivio.
ThemeData buildNivioDesktopTheme({Color accentColor = AppColors.primary}) {
  final secondaryColor = Color.lerp(accentColor, Colors.white, 0.22)!;
  final selectionFill = accentColor.withValues(alpha: 0.2);

  final colorScheme = ColorScheme.dark(
    primary: accentColor,
    onPrimary: AppColors.textPrimary,
    secondary: secondaryColor,
    onSecondary: AppColors.textPrimary,
    error: AppColors.danger,
    onError: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainer: AppColors.surfaceVariant,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.borderSubtle,
  );

  final roundedMedium = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.medium),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTypography.fontFamily,
    colorScheme: colorScheme,
    splashFactory: InkRipple.splashFactory,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: AppTypography.textTheme,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.disabledFill,
        disabledForegroundColor: AppColors.disabledText,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        shape: roundedMedium,
        textStyle: AppTypography.title,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.disabledText,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: roundedMedium,
        textStyle: AppTypography.title,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glassFill,
      hoverColor: AppColors.hover,
      hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
      labelStyle: AppTypography.body,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.glassStroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: BorderSide(color: accentColor),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppColors.borderStrong;
        }
        return AppColors.borderSubtle;
      }),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      thickness: WidgetStateProperty.all(AppSpacing.sm),
      radius: const Radius.circular(AppRadius.pill),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      textStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
      waitDuration: const Duration(milliseconds: 450),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.overlay,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      titleTextStyle: AppTypography.pageTitle,
      contentTextStyle: AppTypography.body,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentColor,
      linearTrackColor: AppColors.surfaceVariant,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSubtle,
      thickness: 1,
      space: 1,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.sidebarBackground,
      selectedIconTheme: IconThemeData(color: accentColor),
      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle: AppTypography.metadata.copyWith(
        color: AppColors.textPrimary,
      ),
      unselectedLabelTextStyle: AppTypography.metadata,
      indicatorColor: AppColors.sidebarSelected,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accentColor,
      selectionColor: selectionFill,
      selectionHandleColor: accentColor,
    ),
    focusColor: selectionFill,
    hoverColor: AppColors.hover,
    splashColor: selectionFill,
    highlightColor: AppColors.hover,
  );
}
