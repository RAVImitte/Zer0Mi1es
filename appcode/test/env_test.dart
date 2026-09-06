import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/config/env.dart';

void main() {
  group('envIsConfigured', () {
    test('empty url is not configured', () {
      expect(envIsConfigured('', 'anon-key'), isFalse);
    });

    test('empty key is not configured', () {
      expect(envIsConfigured('https://abc.supabase.co', ''), isFalse);
    });

    test('placeholder url is not configured', () {
      expect(
        envIsConfigured('https://placeholder.supabase.co', 'anon-key'),
        isFalse,
      );
    });

    test('real url and key is configured', () {
      expect(
        envIsConfigured('https://abc.supabase.co', 'anon-key'),
        isTrue,
      );
    });
  });
}
