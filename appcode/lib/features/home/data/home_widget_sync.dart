import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/color_parser.dart';
import '../../../core/utils/partner_scene.dart';
import '../../avatar/presentation/avatar_view_model.dart';
import '../../avatar/presentation/widgets/dynamic_person_avatar.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../../outfit/presentation/providers/outfit_providers.dart';
import '../presentation/providers/partner_scene_provider.dart';
import '../presentation/providers/partner_status_provider.dart';

const _androidWidget = 'com.example.zer0mi1es.PartnerWidgetProvider';

Timer? _syncDebounce;

String _firstName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return 'Partner';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _moodLine(String? mood) {
  return switch (mood) {
    'Happy' => '😊 Happy',
    'Sad' => '😢 Sad',
    'Devastated' => '💔 Heavy',
    'Overwhelmed' => '😮 Overwhelmed',
    'Excited' => '🤩 Excited',
    'Tired' => '😴 Tired',
    _ => '',
  };
}

Color _sceneFill(PartnerScene scene) {
  return switch (scene) {
    PartnerScene.dawn => const Color(0xFF4C2C3A),
    PartnerScene.day => const Color(0xFF152038),
    PartnerScene.dusk => const Color(0xFF3B1F4A),
    PartnerScene.night => const Color(0xFF070B16),
  };
}

void cancelHomeWidgetSync() {
  _syncDebounce?.cancel();
  _syncDebounce = null;
}

void scheduleHomeWidgetSync(WidgetRef ref) {
  _syncDebounce?.cancel();
  _syncDebounce = Timer(const Duration(milliseconds: 350), () {
    syncHomeWidget(ref);
  });
}

/// Snapshot on name / mood / scene / outfit / sleep. Skip talk and kisses —
/// those must never appear on the home-screen widget.
void bindHomeWidgetListeners(WidgetRef ref) {
  ref.listen(partnerNameProvider, (previous, next) {
    if (previous?.asData?.value != next.asData?.value) {
      scheduleHomeWidgetSync(ref);
    }
  });
  ref.listen(partnerStatusProvider, (previous, next) {
    final prev = previous?.unwrapPrevious().asData?.value;
    final curr = next.unwrapPrevious().asData?.value;
    if (prev?.mood != curr?.mood) {
      scheduleHomeWidgetSync(ref);
    }
  });
  ref.listen(partnerSceneProvider, (previous, next) {
    if (previous?.asData?.value != next.asData?.value) {
      scheduleHomeWidgetSync(ref);
    }
  });
  ref.listen(avatarViewModelProvider, (previous, next) {
    final wasAsleep = previous == AnimationState.sleeping;
    final isAsleep = next == AnimationState.sleeping;
    if (wasAsleep != isAsleep) {
      scheduleHomeWidgetSync(ref);
    }
  });
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (coupleId != null) {
    ref.listen(partnerOutfitProvider(coupleId), (previous, next) {
      final prev = previous?.asData?.value;
      final curr = next.asData?.value;
      if (prev?['top_color'] != curr?['top_color'] ||
          prev?['bottom_color'] != curr?['bottom_color']) {
        scheduleHomeWidgetSync(ref);
      }
    });
  }
}

Future<void> syncHomeWidget(WidgetRef ref) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

  try {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId('group.com.example.zer0mi1es');
    }

    final name = _firstName(ref.read(partnerNameProvider).value);
    final status =
        ref.read(partnerStatusProvider).unwrapPrevious().asData?.value;
    final scene =
        ref.read(partnerSceneProvider).unwrapPrevious().asData?.value ??
            PartnerScene.day;
    final coupleId = ref.read(activeCoupleIdProvider).value;
    final isBunny =
        ref.read(partnerRoleProvider).value == CoupleRole.bunny;
    final isSleeping =
        ref.read(avatarViewModelProvider) == AnimationState.sleeping;

    Color top = const Color(0xFF6366F1).withValues(alpha: 0.4);
    Color bottom = const Color(0xFF6366F1).withValues(alpha: 0.4);
    if (coupleId != null) {
      final outfit = ref.read(partnerOutfitProvider(coupleId)).value;
      if (outfit != null) {
        final parsedTop = parseHexColor(outfit['top_color'] as String);
        final parsedBottom = parseHexColor(outfit['bottom_color'] as String);
        if (parsedTop != Colors.transparent) top = parsedTop;
        if (parsedBottom != Colors.transparent) bottom = parsedBottom;
      }
    }

    final mood = status?.mood;
    final isHappy = mood == 'Happy' || mood == 'Excited';
    final isSad =
        mood == 'Sad' || mood == 'Devastated' || mood == 'Tired';

    await HomeWidget.saveWidgetData<String>('widget_name', name);
    await HomeWidget.saveWidgetData<String>('widget_mood', _moodLine(mood));
    await HomeWidget.saveWidgetData<String>('widget_scene', sceneLabel(scene));

    await HomeWidget.renderFlutterWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 160,
          height: 160,
          child: ColoredBox(
            color: _sceneFill(scene),
            child: CustomPaint(
              size: const Size(160, 160),
              painter: PersonPainter(
                topColor: top,
                bottomColor: bottom,
                isBunny: isBunny,
                isSleeping: isSleeping,
                isHappy: isHappy,
                isSad: isSad,
              ),
            ),
          ),
        ),
      ),
      key: 'widget_avatar',
      logicalSize: const Size(160, 160),
    );

    await HomeWidget.updateWidget(
      qualifiedAndroidName: _androidWidget,
      iOSName: 'PartnerWidget',
    );
  } catch (e) {
    debugPrint('Home widget sync failed: $e');
  }
}
