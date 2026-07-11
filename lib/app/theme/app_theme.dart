import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.light,
          surface: AppColors.surface,
          error: AppColors.red,
        ).copyWith(
          primary: AppColors.green,
          onPrimary: AppColors.black,
          secondary: AppColors.greenDark,
          tertiary: AppColors.yellow,
          onSurface: AppColors.ink,
          outline: AppColors.muted,
          outlineVariant: AppColors.line,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'WorkSans',
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: AppColors.greenDark.withValues(alpha: 0.16),
      hoverColor: AppColors.green.withValues(alpha: 0.12),
    );
  }
}
