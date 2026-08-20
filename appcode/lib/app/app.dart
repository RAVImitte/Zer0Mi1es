import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routing/router.dart';
import '../core/theme/app_theme.dart';

class Zer0Mi1esApp extends ConsumerWidget {
  const Zer0Mi1esApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Zer0Mi1es',
      theme: AppTheme.darkTheme, // We start with a dark theme for a dynamic, premium aesthetic
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
