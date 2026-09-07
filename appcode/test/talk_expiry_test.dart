import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:zer0mi1es/core/utils/talk_expiry.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  void expectAbout(Duration actual, Duration expected) {
    expect(
      actual.inMilliseconds,
      closeTo(expected.inMilliseconds, 2500),
    );
  }

  test('yes → +15 minutes', () {
    final now = DateTime.now().toUtc();
    expectAbout(
      talkReplyExpiry('yes').difference(now),
      const Duration(minutes: 15),
    );
  });

  test('soon / give_me_10 → +1 hour', () {
    final now = DateTime.now().toUtc();
    expectAbout(
      talkReplyExpiry('soon').difference(now),
      const Duration(hours: 1),
    );
    expectAbout(
      talkReplyExpiry('give_me_10').difference(now),
      const Duration(hours: 1),
    );
  });

  test('not_now → +2 hours', () {
    final now = DateTime.now().toUtc();
    expectAbout(
      talkReplyExpiry('not_now').difference(now),
      const Duration(hours: 2),
    );
  });

  test('tonight → next 6am in the given IANA zone', () {
    const iana = 'America/New_York';
    final location = tz.getLocation(iana);
    final localNow = tz.TZDateTime.now(location);
    var expected = tz.TZDateTime(
      location,
      localNow.year,
      localNow.month,
      localNow.day,
      6,
    );
    if (!localNow.isBefore(expected)) {
      expected = expected.add(const Duration(days: 1));
    }

    final expiry = talkReplyExpiry('tonight', iana: iana);
    final localExpiry = tz.TZDateTime.from(expiry, location);

    expect(localExpiry.hour, 6);
    expect(localExpiry.minute, 0);
    expect(localExpiry.second, 0);
    expect(expiry, expected.toUtc());
  });
}
