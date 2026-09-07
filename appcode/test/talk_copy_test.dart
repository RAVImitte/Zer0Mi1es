import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/utils/talk_copy.dart';

void main() {
  group('incomingTalkTitle', () {
    test('names the request type', () {
      expect(incomingTalkTitle('Gwen', 'call'), 'Gwen wants to call');
      expect(
        incomingTalkTitle('Gwen', 'video_call'),
        'Gwen wants to video chat',
      );
      expect(incomingTalkTitle('Gwen', 'text'), 'Gwen wants to text');
      expect(incomingTalkTitle('Gwen', 'other'), 'Gwen wants to text');
    });
  });

  group('outgoingTalkTitle', () {
    test('names the reply', () {
      expect(outgoingTalkTitle('Gwen', 'yes'), 'Gwen said okay');
      expect(
        outgoingTalkTitle('Gwen', 'soon'),
        'Gwen will be there in a bit',
      );
      expect(
        outgoingTalkTitle('Gwen', 'give_me_10'),
        'Gwen will be there in a bit',
      );
      expect(outgoingTalkTitle('Gwen', 'tonight'), 'Gwen said tonight');
      expect(outgoingTalkTitle('Gwen', 'not_now'), 'Gwen can’t right now');
      expect(outgoingTalkTitle('Gwen', 'cant_today'), 'Gwen can’t right now');
      expect(outgoingTalkTitle('Gwen', 'other'), 'Gwen replied');
    });
  });
}
