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

String sceneLine(PartnerScene scene) {
  return switch (scene) {
    PartnerScene.dawn => 'Still waking',
    PartnerScene.day => 'Here with you',
    PartnerScene.dusk => 'Winding down',
    PartnerScene.night => 'Quiet hours',
  };
}

List<Color> sceneWash(PartnerScene scene) {
  return switch (scene) {
    PartnerScene.dawn => const [
        Color(0xFF2A1A22),
        Color(0xFF4A3038),
        AppColors.background,
      ],
    PartnerScene.day => const [
        Color(0xFF1A1824),
        AppColors.background,
      ],
    PartnerScene.dusk => const [
        Color(0xFF241828),
        Color(0xFF3A2438),
        AppColors.background,
      ],
    PartnerScene.night => const [
        Color(0xFF0C0A10),
        AppColors.background,
      ],
  };
}