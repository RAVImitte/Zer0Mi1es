import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radii.dart';

void showAffectionToast(
  BuildContext context, {
  required String emoji,
  required String label,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _AffectionToast(
      emoji: emoji,
      label: label,
      onFinished: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _AffectionToast extends StatefulWidget {
  const _AffectionToast({
    required this.emoji,
    required this.label,
    required this.onFinished,
  });

  final String emoji;
  final String label;
  final VoidCallback onFinished;

  @override
  State<_AffectionToast> createState() => _AffectionToastState();
}

class _AffectionToastState extends State<_AffectionToast> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.72),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.surface,
                ),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: AppMotion.fast, curve: AppMotion.curve)
              .moveY(begin: 8, end: 0, duration: AppMotion.base, curve: AppMotion.curve)
              .then(delay: const Duration(milliseconds: 1600))
              .fadeOut(duration: AppMotion.base, curve: AppMotion.curve),
        ),
      ),
    );
  }
}