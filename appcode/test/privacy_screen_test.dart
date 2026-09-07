import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/constants/app_constants.dart';
import 'package:zer0mi1es/core/theme/app_theme.dart';
import 'package:zer0mi1es/features/legal/presentation/privacy_screen.dart';

void main() {
  testWidgets('PrivacyScreen summarizes couple-scoped facts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const PrivacyScreen(),
      ),
    );

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Two people only'), findsOneWidget);
    expect(find.textContaining('row-level security'), findsOneWidget);
    expect(find.textContaining('24-hour'), findsWidgets);
    expect(find.textContaining('not sell'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Support'), 200);
    expect(find.textContaining('DELETE'), findsOneWidget);
    expect(find.textContaining(SupportContact.email), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
  });
}
