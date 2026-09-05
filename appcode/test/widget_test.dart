import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/theme/app_colors.dart';

void main() {
  test('brand palette matches the sanctuary theme', () {
    expect(AppColors.primary, const Color(0xFF6366F1));
    expect(AppColors.secondary, const Color(0xFFEC4899));
    expect(AppColors.background, const Color(0xFF0F172A));
    expect(AppColors.surface, const Color(0xFF1E293B));
  });
}
