import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/features/home/data/home_widget_sync.dart';

void main() {
  test('syncHomeWidget writes only presence keys', () {
    const presenceKeys = {
      'widget_name',
      'widget_mood',
      'widget_scene',
      'widget_avatar',
    };
    expect(homeWidgetWrittenKeys, presenceKeys);
    expect(
      homeWidgetWrittenKeys.intersection({
        'talk',
        'kiss',
        'love_drop',
        'signal',
      }),
      isEmpty,
    );

    final source = File('lib/features/home/data/home_widget_sync.dart')
        .readAsStringSync();
    expect(
      RegExp(r'for\s*\(\s*final\s+\w+\s+in\s+homeWidgetWrittenKeys\s*\)')
          .hasMatch(source),
      isTrue,
    );

    final writeArgs = <String>{
      ...RegExp(r'saveWidgetData(?:<[^>]+>)?\(\s*([^,\s]+)')
          .allMatches(source)
          .map((m) => m.group(1)!),
      ...RegExp(r'renderFlutterWidget\s*\([\s\S]*?\bkey:\s*([^,\s]+)')
          .allMatches(source)
          .map((m) => m.group(1)!),
    };
    const allowedWriteArgs = {
      'key',
      'homeWidgetNameKey',
      'homeWidgetMoodKey',
      'homeWidgetSceneKey',
      'homeWidgetAvatarKey',
      "'widget_name'",
      "'widget_mood'",
      "'widget_scene'",
      "'widget_avatar'",
      '"widget_name"',
      '"widget_mood"',
      '"widget_scene"',
      '"widget_avatar"',
    };
    expect(writeArgs.difference(allowedWriteArgs), isEmpty);
  });
}
