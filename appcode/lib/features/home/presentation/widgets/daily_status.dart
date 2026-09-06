import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radii.dart';
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
    final doneCount =
        [hasOutfit, hasPhoto, hasQuestion].where((v) => v).length;

    return Column(
      children: [
        Row(
          children: [
            Text('Today', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 10),
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < doneCount
                      ? AppColors.primary
                      : AppColors.hairline,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _RitualChip(
              icon: AppIcons.outfit,
              label: 'Outfit',
              done: hasOutfit,
              pulse: isPaired && !hasOutfit,
              onTap: () => _open(context, isPaired, AppRoutes.outfit),
            ),
            const SizedBox(width: 8),
            _RitualChip(
              icon: AppIcons.photo,
              label: 'Photo',
              done: hasPhoto,
              pulse: isPaired && !hasPhoto,
              onTap: () => _open(context, isPaired, AppRoutes.dailyPhoto),
            ),
            const SizedBox(width: 8),
            _RitualChip(
              icon: AppIcons.question,
              label: 'Question',
              done: hasQuestion,
              pulse: isPaired && !hasQuestion,
              onTap: () => _open(context, isPaired, AppRoutes.dailyQuestion),
            ),
          ],
        ),
      ],
    );
  }

  void _open(BuildContext context, bool isPaired, String route) {
    HapticFeedback.selectionClick();
    if (!isPaired) {
      context.push(AppRoutes.couple);
      return;
    }
    context.push(route);
  }
}

class _RitualChip extends StatelessWidget {
  const _RitualChip({
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
    Widget chip = Material(
      color: done
          ? AppColors.primary.withValues(alpha: 0.16)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Semantics(
          button: true,
          label: done ? '$label, done' : label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: done ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: done
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (pulse && !MediaQuery.disableAnimationsOf(context)) {
      chip = chip
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
            duration: AppMotion.slow,
            curve: AppMotion.curve,
          );
    }
    return Expanded(child: chip);
  }
}