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
        Color(0xFF221614),
        Color(0xFF1A1212),
        AppColors.background,
      ],
    PartnerScene.morning => const [
        Color(0xFF16141C),
        AppColors.background,
      ],
    PartnerScene.afternoon => const [
        Color(0xFF1A1410),
        AppColors.background,
      ],
    PartnerScene.evening => const [
        Color(0xFF1C1016),
        Color(0xFF161014),
        AppColors.background,
      ],
    PartnerScene.night => const [
        Color(0xFF0A0810),
        AppColors.background,
      ],
  };
}

/// Warm veil over the window painting so daylight skies don't blow out the room.
Color sceneVeil(PartnerScene scene) {
  return switch (scene) {
    PartnerScene.dawn => const Color(0x66241410),
    PartnerScene.morning => const Color(0x731C1820),
    PartnerScene.afternoon => const Color(0x6A24180C),
    PartnerScene.evening => const Color(0x4D141018),
    PartnerScene.night => const Color(0x3D100C14),
  };
}

/// Soft stage colors — skies that fade into the room, not boxed paintings.
class SceneLook {
  const SceneLook({
    required this.skyHi,
    required this.skyMid,
    required this.ground,
    required this.accent,
  });

  final Color skyHi;
  final Color skyMid;
  final Color ground;
  final Color accent;

  @override
  bool operator ==(Object other) =>
      other is SceneLook &&
      skyHi == other.skyHi &&
      skyMid == other.skyMid &&
      ground == other.ground &&
      accent == other.accent;

  @override
  int get hashCode => Object.hash(skyHi, skyMid, ground, accent);
}

SceneLook sceneLook(PartnerScene scene, {bool unpaired = false}) {
  if (unpaired) {
    return const SceneLook(
      skyHi: Color(0xFF3A3236),
      skyMid: Color(0xFF2A2226),
      ground: Color(0xFF2C2428),
      accent: Color(0xFFE8A090),
    );
  }
  return switch (scene) {
    PartnerScene.dawn => const SceneLook(
        skyHi: Color(0xFFF0B8A0),
        skyMid: Color(0xFF8A4A52),
        ground: Color(0xFF4A3030),
        accent: Color(0xFFF0C878),
      ),
    PartnerScene.morning => const SceneLook(
        skyHi: Color(0xFFB4D4F0),
        skyMid: Color(0xFF5A7A9A),
        ground: Color(0xFF3A5444),
        accent: Color(0xFFFFE08A),
      ),
    PartnerScene.afternoon => const SceneLook(
        skyHi: Color(0xFFE8C878),
        skyMid: Color(0xFFB07848),
        ground: Color(0xFF445434),
        accent: Color(0xFFFFE0A0),
      ),
    PartnerScene.evening => const SceneLook(
        skyHi: Color(0xFFE89070),
        skyMid: Color(0xFF6A3A58),
        ground: Color(0xFF3A2438),
        accent: Color(0xFFF0B878),
      ),
    PartnerScene.night => const SceneLook(
        skyHi: Color(0xFF4A5A88),
        skyMid: Color(0xFF1C1830),
        ground: Color(0xFF16141C),
        accent: Color(0xFFF0D8B0),
      ),
  };
}