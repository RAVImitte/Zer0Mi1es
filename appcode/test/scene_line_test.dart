import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/utils/partner_scene.dart';

void main() {
  test('sceneLine is atmosphere, not a clock label', () {
    expect(sceneLine(PartnerScene.dawn), 'Still waking');
    expect(sceneLine(PartnerScene.day), 'Here with you');
    expect(sceneLine(PartnerScene.dusk), 'Winding down');
    expect(sceneLine(PartnerScene.night), 'Quiet hours');
  });
}
