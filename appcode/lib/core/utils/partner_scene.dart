import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PartnerScene { dawn, morning, afternoon, evening, night }

PartnerScene sceneForHour(int hour) {
  if (hour >= 5 && hour < 8) return PartnerScene.dawn;
  if (hour >= 8 && hour < 12) return PartnerScene.morning;
  if (hour >= 12 && hour < 17) return PartnerScene.afternoon;
  if (hour >= 17 && hour < 21) return PartnerScene.evening;
  return PartnerScene.night;
}

String sceneLabel(PartnerScene scene) {
  return switch (scene) {
    PartnerScene.dawn => 'Dawn',
    PartnerScene.morning => 'Morning',
    PartnerScene.afternoon => 'Afternoon',
    PartnerScene.evening => 'Evening',
    PartnerScene.night => 'Night',
  };
}

String sceneAsset(PartnerScene scene, {bool unpaired = false}) {
  if (unpaired) return 'assets/scenes/unlit.jpg';
  return switch (scene) {
    PartnerScene.dawn => 'assets/scenes/dawn.jpg',
    PartnerScene.morning => 'assets/scenes/morning.jpg',
    PartnerScene.afternoon => 'assets/scenes/afternoon.jpg',
    PartnerScene.evening => 'assets/scenes/evening.jpg',
    PartnerScene.night => 'assets/scenes/night.jpg',
  };
}

List<Color> sceneWash(PartnerScene scene) {
  return switch (scene) {
    PartnerScene.dawn => const [
        Color(0xFF2A1A18),
        Color(0xFF4A2E2A),
        AppColors.background,
      ],
    PartnerScene.morning => const [
        Color(0xFF1C1820),
        AppColors.background,
      ],
    PartnerScene.afternoon => const [
        Color(0xFF241810),
        AppColors.background,
      ],
    PartnerScene.evening => const [
        Color(0xFF24141C),
        Color(0xFF3A1E28),
        AppColors.background,
      ],
    PartnerScene.night => const [
        Color(0xFF0C0A10),
        AppColors.background,
      ],
  };
}