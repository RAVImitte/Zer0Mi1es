import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/utils/color_parser.dart';
import '../../../avatar/presentation/avatar_view_model.dart';
import '../../../avatar/presentation/widgets/dynamic_person_avatar.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../../outfit/presentation/providers/outfit_providers.dart';

class PartnerPresence extends ConsumerWidget {
  const PartnerPresence({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationState = ref.watch(avatarViewModelProvider);
    final statusText = _statusWord(animationState);
    final avatarColor = _statusColor(animationState);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.biggest.shortestSide * 0.72).clamp(180.0, 280.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AvatarBubble(size: size, avatarColor: avatarColor, scale: _scale(animationState)),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: AppMotion.base,
              child: Text(
                statusText,
                key: ValueKey(statusText),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }

  double _scale(AnimationState state) {
    return switch (state) {
      AnimationState.reaction => 1.08,
      AnimationState.talking => 1.04,
      _ => 1.0,
    };
  }

  String _statusWord(AnimationState state) {
    return switch (state) {
      AnimationState.idle => 'Here',
      AnimationState.reaction => 'Love',
      AnimationState.talking => 'Talk',
      AnimationState.playing => 'Play',
      AnimationState.petting => 'Soft',
      AnimationState.feeding => 'Care',
      AnimationState.sleeping => 'Night',
      AnimationState.walking => 'Walk',
      AnimationState.sitting || AnimationState.resting => 'Rest',
      AnimationState.moodHappy => 'Happy',
      AnimationState.moodSad => 'Sad',
      AnimationState.moodDevastated => 'Heavy',
      AnimationState.moodOverwhelmed => 'Much',
      AnimationState.moodExcited => 'Spark',
      AnimationState.moodTired => 'Tired',
    };
  }

  Color _statusColor(AnimationState state) {
    return switch (state) {
      AnimationState.reaction => AppColors.affection,
      AnimationState.talking => AppColors.primary,
      AnimationState.sleeping => const Color(0xFF4338CA),
      AnimationState.moodHappy || AnimationState.moodExcited => const Color(0xFFFBBF24),
      AnimationState.moodSad || AnimationState.moodTired => AppColors.textSecondary,
      AnimationState.moodDevastated => const Color(0xFF64748B),
      AnimationState.moodOverwhelmed => const Color(0xFFFB923C),
      _ => AppColors.primary,
    };
  }
}

class _AvatarBubble extends ConsumerWidget {
  const _AvatarBubble({
    required this.size,
    required this.avatarColor,
    required this.scale,
  });

  final double size;
  final Color avatarColor;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationState = ref.watch(avatarViewModelProvider);
    final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
    final outfitAsync = activeCoupleId != null
        ? ref.watch(partnerOutfitProvider(activeCoupleId))
        : const AsyncValue<Map<String, dynamic>?>.data(null);
    final isBunny = ref.watch(partnerRoleProvider).value == CoupleRole.bunny;

    Color topColor = avatarColor.withValues(alpha: 0.2);
    Color bottomColor = avatarColor.withValues(alpha: 0.2);
    final outfitValue = outfitAsync.value;
    if (outfitValue != null) {
      final parsedTop = parseHexColor(outfitValue['top_color'] as String);
      final parsedBottom = parseHexColor(outfitValue['bottom_color'] as String);
      if (parsedTop != Colors.transparent) topColor = parsedTop;
      if (parsedBottom != Colors.transparent) bottomColor = parsedBottom;
    }

    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.curve,
      transform: Matrix4.identity()..scale(scale),
      transformAlignment: Alignment.center,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(color: avatarColor.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withValues(alpha: 0.22),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (activeCoupleId == null)
            GestureDetector(
              onTap: () => context.push(AppRoutes.couple),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: size * 0.18, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Pair',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () =>
                  ref.read(avatarViewModelProvider.notifier).resetToIdle(),
              child: DynamicPersonAvatar(
                state: animationState,
                topColor: topColor,
                bottomColor: bottomColor,
                isBunny: isBunny,
                size: size * 0.72,
              ),
            ),
          if (activeCoupleId != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: _SelfChip(coupleId: activeCoupleId),
            ),
        ],
      ),
    );
  }
}

class _SelfChip extends ConsumerWidget {
  const _SelfChip({required this.coupleId});

  final String coupleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMyBunny = ref.watch(myRoleProvider).value == CoupleRole.bunny;
    final outfitAsync = ref.watch(myOutfitProvider(coupleId));
    Color myTop = AppColors.primary.withValues(alpha: 0.2);
    Color myBottom = AppColors.primary.withValues(alpha: 0.2);
    final mine = outfitAsync.value;
    if (mine != null) {
      final t = parseHexColor(mine['top_color'] as String);
      final b = parseHexColor(mine['bottom_color'] as String);
      if (t != Colors.transparent) myTop = t;
      if (b != Colors.transparent) myBottom = b;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline),
      ),
      child: ClipOval(
        child: DynamicPersonAvatar(
          state: AnimationState.resting,
          topColor: myTop,
          bottomColor: myBottom,
          isBunny: isMyBunny,
          size: 48,
        ),
      ),
    );
  }
}