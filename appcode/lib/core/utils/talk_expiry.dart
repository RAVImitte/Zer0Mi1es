import 'package:timezone/timezone.dart' as tz;

DateTime talkReplyExpiry(
  String status, {
  String iana = 'UTC',
  DateTime? now,
}) {
  final clock = (now ?? DateTime.now()).toUtc();
  switch (status) {
    case 'yes':
      return clock.add(const Duration(minutes: 15));
    case 'soon':
    case 'give_me_10':
      return clock.add(const Duration(hours: 1));
    case 'not_now':
    case 'cant_today':
      return clock.add(const Duration(hours: 2));
    case 'tonight':
      return _nextSixAm(iana, now: now);
    default:
      return clock.add(const Duration(hours: 12));
  }
}

DateTime _nextSixAm(String iana, {DateTime? now}) {
  tz.Location location;
  try {
    location = tz.getLocation(iana);
  } catch (_) {
    location = tz.UTC;
  }
  final local = now == null
      ? tz.TZDateTime.now(location)
      : tz.TZDateTime.from(now.toUtc(), location);
  var six = tz.TZDateTime(location, local.year, local.month, local.day, 6);
  if (!local.isBefore(six)) {
    six = six.add(const Duration(days: 1));
  }
  return six.toUtc();
}