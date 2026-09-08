import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/partner_scene.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scene = sceneForHour(DateTime.now().hour);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sceneWash(scene),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _TwoWindowsMark(),
              const SizedBox(height: 28),
              Text(
                'Zero Miles',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontFamily: AppTheme.displayFamily,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _slow ? 1 : 0,
                duration: const Duration(milliseconds: 280),
                child: Text(
                  'Opening your room…',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TwoWindowsMark extends StatelessWidget {
  const _TwoWindowsMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pane(const Color(0xFFE8C9A0)),
          const SizedBox(width: 8),
          _pane(const Color(0xFF2A2450)),
        ],
      ),
    );
  }

  Widget _pane(Color fill) {
    return Container(
      width: 32,
      height: 52,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(8),
        ),
        border: Border.all(color: AppColors.hairline),
      ),
    );
  }
}