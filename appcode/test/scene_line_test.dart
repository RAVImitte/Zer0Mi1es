import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/utils/partner_scene.dart';

void main() {
  test('sceneLine is atmosphere, not a clock label', () {
    expect(sceneLine(PartnerScene.dawn), 'The house is still');
    expect(sceneLine(PartnerScene.day), 'Right here');
    expect(sceneLine(PartnerScene.dusk), 'The light is going');
    expect(sceneLine(PartnerScene.night), 'The room is quiet');
  });
}
