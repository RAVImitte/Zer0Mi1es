import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/theme/app_colors.dart';

void main() {
  test('brand palette matches the sanctuary theme', () {
    expect(AppColors.primary, const Color(0xFFD4A5C0));
    expect(AppColors.secondary, const Color(0xFFE07A8A));
    expect(AppColors.background, const Color(0xFF121018));
    expect(AppColors.surface, const Color(0xFF1C1824));
  });
}
