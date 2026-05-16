import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final flexScheme = FlexColorScheme.dark(
      primary: AppColors.resident,
      primaryContainer: AppColors.surface2,
      secondary: AppColors.worker,
      secondaryContainer: AppColors.surface2,
      tertiary: AppColors.manager,
      tertiaryContainer: AppColors.surface2,
      surface: AppColors.surface1,
      scaffoldBackground: AppColors.background,
      error: AppColors.error,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 12,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        blendOnColors: true,
        useMaterial3Typography: true,
        cardRadius: 14.0,
        inputDecoratorRadius: 10.0,
        inputDecoratorIsFilled: true,
        inputDecoratorFillColor: AppColors.surface2,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorBorderWidth: 1.0,
        inputDecoratorFocusedBorderWidth: 2.0,
        elevatedButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
        textButtonRadius: 8.0,
        bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        bottomNavigationBarUnselectedLabelSchemeColor: SchemeColor.onSurfaceVariant,
        bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
        bottomNavigationBarUnselectedIconSchemeColor: SchemeColor.onSurfaceVariant,
        bottomNavigationBarBackgroundSchemeColor: SchemeColor.surface,
        bottomNavigationBarElevation: 0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
    );

    return flexScheme.toTheme.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface1,
      dividerColor: AppColors.border,
      textTheme: AppTypography.textTheme,
      primaryTextTheme: AppTypography.textTheme,
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
