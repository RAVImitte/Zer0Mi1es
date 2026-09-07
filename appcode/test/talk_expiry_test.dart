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

  test('tonight at 05:59 → today 6am in the given IANA zone', () {
    const iana = 'America/New_York';
    final location = tz.getLocation(iana);
    final now = tz.TZDateTime(location, 2026, 9, 7, 5, 59);
    final expected = tz.TZDateTime(location, 2026, 9, 7, 6);

    final expiry = talkReplyExpiry('tonight', iana: iana, now: now);
    final localExpiry = tz.TZDateTime.from(expiry, location);

    expect(localExpiry.hour, 6);
    expect(localExpiry.minute, 0);
    expect(localExpiry.second, 0);
    expect(localExpiry.year, 2026);
    expect(localExpiry.month, 9);
    expect(localExpiry.day, 7);
    expect(expiry, expected.toUtc());
  });

  test('tonight at 06:00 → tomorrow 6am in the given IANA zone', () {
    const iana = 'America/New_York';
    final location = tz.getLocation(iana);
    final now = tz.TZDateTime(location, 2026, 9, 7, 6);
    final expected = tz.TZDateTime(location, 2026, 9, 8, 6);

    final expiry = talkReplyExpiry('tonight', iana: iana, now: now);
    final localExpiry = tz.TZDateTime.from(expiry, location);

    expect(localExpiry.hour, 6);
    expect(localExpiry.minute, 0);
    expect(localExpiry.second, 0);
    expect(localExpiry.year, 2026);
    expect(localExpiry.month, 9);
    expect(localExpiry.day, 8);
    expect(expiry, expected.toUtc());
  });
}
