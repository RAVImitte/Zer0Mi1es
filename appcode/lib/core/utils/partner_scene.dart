import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PartnerScene { dawn, day, dusk, night }

PartnerScene sceneForHour(int hour) {
  if (hour >= 5 && hour < 8) return PartnerScene.dawn;
  if (hour >= 8 && hour < 17) return PartnerScene.day;
  if (hour >= 17 && hour < 21) return PartnerScene.dusk;
  return PartnerScene.night;
}

String sceneLabel(PartnerScene scene) {
  return switch (scene) {
    PartnerScene.dawn => 'Dawn',
    PartnerScene.day => 'Day',
    PartnerScene.dusk => 'Dusk',
    PartnerScene.night => 'Night',
  };
}

List<Color> sceneWash(PartnerScene scene) {
  return switch (scene) {
    PartnerScene.dawn => const [
        Color(0xFF1B1324),
        Color(0xFF4C2C3A),
        AppColors.background,
      ],
    PartnerScene.day => const [
        Color(0xFF152038),
        AppColors.background,
      ],
    PartnerScene.dusk => const [
        Color(0xFF1A1540),
        Color(0xFF3B1F4A),
        AppColors.background,
      ],
    PartnerScene.night => const [
        Color(0xFF070B16),
        Color(0xFF0F172A),
      ],
  };
}