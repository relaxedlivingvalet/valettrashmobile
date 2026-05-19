import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valet/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('background is near-black, not pure black', () {
      expect(AppColors.background, isNot(const Color(0xFF000000)));
      expect(AppColors.background.red, lessThan(20));
      expect(AppColors.background.green, lessThan(20));
      expect(AppColors.background.blue, lessThan(20));
    });

    test('surface scale is progressively lighter than background', () {
      final bg = AppColors.background.computeLuminance();
      final s1 = AppColors.surface1.computeLuminance();
      final s2 = AppColors.surface2.computeLuminance();
      expect(s1, greaterThan(bg));
      expect(s2, greaterThan(s1));
    });

    test('all role accents are unified to brand blue', () {
      expect(AppColors.resident, AppColors.rlvBlue);
      expect(AppColors.worker, AppColors.rlvBlue);
      expect(AppColors.manager, AppColors.rlvBlue);
      expect(AppColors.owner, AppColors.rlvBlue);
    });

    test('brand blue is a blue-dominant color', () {
      expect(AppColors.rlvBlue.blue, greaterThan(AppColors.rlvBlue.red));
      expect(AppColors.rlvBlue.blue, greaterThan(AppColors.rlvBlue.green));
    });

    test('text primary has highest luminance of text colors', () {
      final primary = AppColors.textPrimary.computeLuminance();
      final secondary = AppColors.textSecondary.computeLuminance();
      final muted = AppColors.textMuted.computeLuminance();
      expect(primary, greaterThan(secondary));
      expect(primary, greaterThan(muted));
    });

    test('semantic colors are distinct from each other', () {
      expect(AppColors.success, isNot(AppColors.error));
      expect(AppColors.warning, isNot(AppColors.error));
      expect(AppColors.success, isNot(AppColors.warning));
    });
  });
}
