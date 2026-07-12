import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes the approved Daily Meal brand colors', () {
    expect(AppColors.ink, const Color(0xFF202124));
    expect(AppColors.muted, const Color(0xFF74746F));
    expect(AppColors.line, const Color(0xFFE4E1D8));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.canvas, const Color(0xFFF4F3EF));
    expect(AppColors.canvasStrong, const Color(0xFFECE9DF));
    expect(AppColors.green, const Color(0xFF8BA58A));
    expect(AppColors.greenDark, const Color(0xFF4F6F3D));
    expect(AppColors.yellow, const Color(0xFFF6DE68));
    expect(AppColors.red, const Color(0xFFE65B55));
    expect(AppColors.blue, const Color(0xFF65A9D7));
  });

  test('uses Material 3 and the Daily Meal canvas', () {
    final theme = AppTheme.light();

    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, AppColors.canvas);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'WorkSans');
    expect(theme.colorScheme.primary, AppColors.green);
  });
}
