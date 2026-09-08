import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/theme/app_colors.dart';

void main() {
  test('brand palette matches the sanctuary theme', () {
    expect(AppColors.primary, const Color(0xFFE8A090));
    expect(AppColors.secondary, const Color(0xFFE25C7A));
    expect(AppColors.background, const Color(0xFF141014));
    expect(AppColors.surface, const Color(0xFF231C21));
  });
}
