import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/utils/partner_scene.dart';

void main() {
  group('sceneForHour', () {
    test('hour 5 is dawn', () {
      expect(sceneForHour(5), PartnerScene.dawn);
    });

    test('hour 8 is day', () {
      expect(sceneForHour(8), PartnerScene.day);
    });

    test('hour 17 is dusk', () {
      expect(sceneForHour(17), PartnerScene.dusk);
    });

    test('hour 21 is night', () {
      expect(sceneForHour(21), PartnerScene.night);
    });

    test('hour 0 is night', () {
      expect(sceneForHour(0), PartnerScene.night);
    });
  });
}
