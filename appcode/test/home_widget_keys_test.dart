import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/features/home/data/home_widget_sync.dart';

void main() {
  test('syncHomeWidget writes only presence keys', () {
    expect(homeWidgetWrittenKeys, {
      'widget_name',
      'widget_mood',
      'widget_scene',
      'widget_avatar',
    });
    expect(
      homeWidgetWrittenKeys.intersection({
        'talk',
        'kiss',
        'love_drop',
        'signal',
      }),
      isEmpty,
    );
  });
}
