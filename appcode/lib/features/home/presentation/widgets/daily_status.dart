import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../providers/home_providers.dart';

class DailyStatus extends ConsumerWidget {
  const DailyStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasOutfit = ref.watch(outfitCompletedProvider).value ?? false;
    final hasPhoto = ref.watch(photoCompletedProvider).value ?? false;
    final hasQuestion = ref.watch(questionCompletedProvider).value ?? false;
    final isPaired = ref.watch(activeCoupleIdProvider).value != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RitualDot(
          icon: Icons.checkroom_outlined,
          label: 'Wear',
          done: hasOutfit,
          pulse: isPaired && !hasOutfit,
          onTap: () => _open(context, isPaired, AppRoutes.outfit),
        ),
        const SizedBox(width: 20),
        _RitualDot(
          icon: Icons.photo_camera_outlined,
          label: 'Photo',
          done: hasPhoto,
          pulse: isPaired && !hasPhoto,
          onTap: () => _open(context, isPaired, AppRoutes.dailyPhoto),
        ),
        const SizedBox(width: 20),
        _RitualDot(
          icon: Icons.quiz_outlined,
          label: 'Ask',
          done: hasQuestion,
          pulse: isPaired && !hasQuestion,
          onTap: () => _open(context, isPaired, AppRoutes.dailyQuestion),
        ),
      ],
    );
  }

  void _open(BuildContext context, bool isPaired, String route) {
    HapticFeedback.selectionClick();
    if (!isPaired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pair with your partner first')),
      );
      return;
    }
    context.push(route);
  }
}

class _RitualDot extends StatelessWidget {
  const _RitualDot({
    required this.icon,
    required this.label,
    required this.done,
    required this.onTap,
    this.pulse = false,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget dot = Material(
      color: done
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 22,
            color: done ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );

    if (pulse) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: AppMotion.slow,
            curve: AppMotion.curve,
          );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: done ? AppColors.primary : AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}