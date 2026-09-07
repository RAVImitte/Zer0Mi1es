import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_parser.dart';
import '../../../avatar/domain/avatar_event.dart';
import '../../../avatar/presentation/couple_scene_view_model.dart';
import '../../../avatar/presentation/widgets/layered_person_avatar.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../../outfit/presentation/providers/outfit_providers.dart';

class PartnerPresence extends ConsumerWidget {
  const PartnerPresence({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(coupleSceneProvider);
    final roleAsync = ref.watch(myRoleProvider);
    final myRole = roleAsync.unwrapPrevious().value;
    final coupleId = ref.watch(activeCoupleIdProvider).value;
    final partnerName = ref.watch(partnerNameProvider).value ?? 'Partner';

    if (coupleId != null && myRole == null) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final iAmLeft = myRole != CoupleRole.bunny;

    return LayoutBuilder(
      builder: (context, constraints) {
        const labelBand = 46.0;
        final byHeight =
            (constraints.maxHeight - labelBand).clamp(96.0, 200.0);
        final byWidth = (constraints.maxWidth * 0.42).clamp(96.0, 200.0);
        final avatarSize = math.min(byHeight, byWidth);
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Seat(
                      leftSeat: true,
                      isMe: iAmLeft,
                      label: iAmLeft ? 'You' : partnerName,
                      caption: scene.leftMood,
                      state: scene.left,
                      isBunny: false,
                      coupleId: coupleId,
                      size: avatarSize,
                      unpairedEmpty: coupleId == null && !iAmLeft,
                    ),
                  ),
                  Expanded(
                    child: _Seat(
                      leftSeat: false,
                      isMe: !iAmLeft,
                      label: iAmLeft ? partnerName : 'You',
                      caption: scene.rightMood,
                      state: scene.right,
                      isBunny: true,
                      coupleId: coupleId,
                      size: avatarSize,
                      unpairedEmpty: coupleId == null && iAmLeft,
                    ),
                  ),
                ],
              ),
              if (scene.drop != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _DropFlight(
                      key: ValueKey(scene.drop!.playId),
                      drop: scene.drop!,
                      avatarSize: avatarSize,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Seat extends ConsumerWidget {
  const _Seat({
    required this.leftSeat,
    required this.isMe,
    required this.label,
    required this.caption,
    required this.state,
    required this.isBunny,
    required this.coupleId,
    required this.size,
    required this.unpairedEmpty,
  });

  final bool leftSeat;
  final bool isMe;
  final String label;
  final String? caption;
  final AnimationState state;
  final bool isBunny;
  final String? coupleId;
  final double size;
  final bool unpairedEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glow = _statusColor(state);

    if (unpairedEmpty) {
      return GestureDetector(
        onTap: () => context.push(AppRoutes.couple),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline, width: 1.5),
              ),
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Invite them',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    Color top = glow.withValues(alpha: 0.2);
    Color bottom = glow.withValues(alpha: 0.2);
    if (coupleId != null) {
      final outfit = isMe
          ? ref.watch(myOutfitProvider(coupleId!)).value
          : ref.watch(partnerOutfitProvider(coupleId!)).value;
      if (outfit != null) {
        final t = parseHexColor(outfit['top_color'] as String);
        final b = parseHexColor(outfit['bottom_color'] as String);
        if (t != Colors.transparent) top = t;
        if (b != Colors.transparent) bottom = b;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glow.withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: LayeredPersonAvatar(
                  state: state,
                  topColor: top,
                  bottomColor: bottom,
                  isBunny: isBunny,
                  leftSeat: leftSeat,
                  size: size,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 2),
          Text(
            caption ?? 'Here',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Color _statusColor(AnimationState state) {
    return switch (state) {
      AnimationState.receiving ||
      AnimationState.giving ||
      AnimationState.leanIn =>
        AppColors.affection,
      AnimationState.sorry => AppColors.textSecondary,
      AnimationState.sleeping => const Color(0xFF6B5B8C),
      AnimationState.moodHappy || AnimationState.moodExcited =>
        const Color(0xFFFBBF24),
      AnimationState.moodSad || AnimationState.moodTired =>
        AppColors.textSecondary,
      AnimationState.moodDevastated => const Color(0xFF64748B),
      AnimationState.moodAngry => AppColors.danger,
      _ => AppColors.primary,
    };
  }
}

class _DropFlight extends StatefulWidget {
  const _DropFlight({
    super.key,
    required this.drop,
    required this.avatarSize,
  });

  final CoupleDrop drop;
  final double avatarSize;

  @override
  State<_DropFlight> createState() => _DropFlightState();
}

class _DropFlightState extends State<_DropFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        final start = widget.drop.senderIsLeft ? 0.22 : 0.78;
        final end = widget.drop.senderIsLeft ? 0.78 : 0.22;
        final x = start + (end - start) * t;
        final y = 0.38 - 0.16 * math.sin(math.pi * t);
        final opacity = t < 0.12
            ? t / 0.12
            : (t > 0.85 ? (1 - t) / 0.15 : 1.0);
        return Align(
          alignment: Alignment(x * 2 - 1, y * 2 - 1),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Text(
              _emojiFor(widget.drop.type),
              style: TextStyle(fontSize: widget.avatarSize * 0.22, height: 1),
            ),
          ),
        );
      },
    );
  }

  String _emojiFor(String type) {
    return switch (type) {
      'Kiss' => '💋',
      'Hug' => '💕',
      'Sorry' => '🥺',
      'Thinking' => '💭',
      _ => type.length <= 2 ? type : '💖',
    };
  }
}
