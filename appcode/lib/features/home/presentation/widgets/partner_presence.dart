import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/color_parser.dart';
import '../../../../core/utils/partner_scene.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/living_window.dart';
import '../../../avatar/domain/avatar_event.dart';
import '../../../avatar/presentation/couple_scene_view_model.dart';
import '../../../avatar/presentation/widgets/layered_person_avatar.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../../outfit/presentation/providers/outfit_providers.dart';
import '../providers/partner_scene_provider.dart';
import '../providers/partner_status_provider.dart';
import 'connection_actions.dart';
import 'love_note_cloud.dart';
import 'room_wall_note.dart';
import '../../../voice_drop/presentation/voice_play_chip.dart';

const kHomeWallNoteSlot = 108.0;

class PartnerPresence extends ConsumerWidget {
  const PartnerPresence({super.key, this.seatsKey});

  /// Spotlight target for the first-run coach — just the two seats, not the wall note.
  final Key? seatsKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(coupleSceneProvider);
    final roleAsync = ref.watch(myRoleProvider);
    final myRole = roleAsync.unwrapPrevious().value;
    final coupleId = ref.watch(activeCoupleIdProvider).value;
    final partnerName = ref.watch(partnerNameProvider).value ?? 'Partner';
    final myScene = ref.watch(mySceneProvider);
    final theirScene =
        ref.watch(partnerSceneProvider).value ?? myScene;

    final waitingOnRole = coupleId != null &&
        myRole == null &&
        roleAsync.isLoading &&
        !roleAsync.hasError;
    if (waitingOnRole) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final iAmLeft = myRole != CoupleRole.bunny;
    final myAsleep =
        (iAmLeft ? scene.left : scene.right) == AnimationState.sleeping;
    final theirAsleep =
        (iAmLeft ? scene.right : scene.left) == AnimationState.sleeping;

    return LayoutBuilder(
      builder: (context, constraints) {
        final seatW = constraints.maxWidth / 2;
        final windowW = seatW.clamp(96.0, 220.0);
        final avatarSize = (windowW * 0.66).clamp(76.0, 140.0);
        const captionH = 32.0;
        final leftover =
            math.max(0.0, constraints.maxHeight - kHomeWallNoteSlot);
        final seatBlockH = math.min(leftover, windowW * 1.0 + captionH);

        Widget seatRow() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Seat(
                  leftSeat: true,
                  isMe: iAmLeft,
                  label: iAmLeft ? 'You' : _firstName(partnerName),
                  state: scene.left,
                  isBunny: false,
                  coupleId: coupleId,
                  size: avatarSize,
                  unpairedEmpty: coupleId == null && !iAmLeft,
                  windowScene: iAmLeft ? myScene : theirScene,
                  sleeping: iAmLeft ? myAsleep : theirAsleep,
                  mood: scene.leftMood,
                  partnerName: partnerName,
                  bubble: scene.leftNote,
                ),
              ),
              Expanded(
                child: _Seat(
                  leftSeat: false,
                  isMe: !iAmLeft,
                  label: iAmLeft ? _firstName(partnerName) : 'You',
                  state: scene.right,
                  isBunny: true,
                  coupleId: coupleId,
                  size: avatarSize,
                  unpairedEmpty: coupleId == null && iAmLeft,
                  windowScene: iAmLeft ? theirScene : myScene,
                  sleeping: iAmLeft ? theirAsleep : myAsleep,
                  mood: scene.rightMood,
                  partnerName: partnerName,
                  bubble: scene.rightNote,
                ),
              ),
            ],
          );
        }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: kHomeWallNoteSlot,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
                      child: _SafeFit(child: RoomWallNote()),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            key: seatsKey,
                            height: seatBlockH,
                            child: seatRow(),
                          ),
                        ),
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: VoicePlayChip(),
                        ),
                      ],
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

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Partner';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// FittedBox with a zero-size parent builds an infinite scale matrix.
class _SafeFit extends StatelessWidget {
  const _SafeFit({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.maxWidth.isFinite ||
            !box.maxHeight.isFinite ||
            box.maxWidth < 8 ||
            box.maxHeight < 8) {
          return const SizedBox.shrink();
        }
        return FittedBox(fit: BoxFit.scaleDown, child: child);
      },
    );
  }
}

class _Seat extends ConsumerWidget {
  const _Seat({
    required this.leftSeat,
    required this.isMe,
    required this.label,
    required this.state,
    required this.isBunny,
    required this.coupleId,
    required this.size,
    required this.unpairedEmpty,
    required this.windowScene,
    required this.sleeping,
    required this.mood,
    required this.partnerName,
    this.bubble,
  });

  final bool leftSeat;
  final bool isMe;
  final String label;
  final AnimationState state;
  final bool isBunny;
  final String? coupleId;
  final double size;
  final bool unpairedEmpty;
  final PartnerScene windowScene;
  final bool sleeping;
  final String? mood;
  final String partnerName;
  final SeatNote? bubble;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glow = _statusColor(state);

    if (unpairedEmpty) {
      return _framedSeat(
        context: context,
        label: 'Them',
        window: LivingWindow(
          scene: windowScene,
          unpaired: true,
          leftSeat: leftSeat,
          onTap: () => context.push(AppRoutes.couple),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.pair, color: AppColors.primary, size: 28),
                const SizedBox(height: 6),
                Text(
                  'Pair',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
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

    return _framedSeat(
      context: context,
      label: label,
      bubble: bubble,
      avatarSize: size,
      onPopNote: bubble == null
          ? null
          : () => ref.read(coupleSceneProvider.notifier).dismissNote(mine: isMe),
      onRestoreNote: bubble == null
          ? null
          : () => ref.read(coupleSceneProvider.notifier).restoreNote(mine: isMe),
      window: LivingWindow(
        scene: windowScene,
        sleeping: sleeping,
        leftSeat: leftSeat,
        rimColor: glow,
        onTap: () {
          if (isMe) {
            showMoodSheet(context, ref);
          } else {
            _showPresence(context, ref);
          }
        },
        onLongPress: isMe ? () => showLoveSheet(context, ref) : null,
        child: LayeredPersonAvatar(
          state: state,
          topColor: top,
          bottomColor: bottom,
          isBunny: isBunny,
          leftSeat: leftSeat,
          size: size,
        ),
      ),
    );
  }

  Widget _framedSeat({
    required BuildContext context,
    required String label,
    required Widget window,
    SeatNote? bubble,
    double avatarSize = 0,
    VoidCallback? onPopNote,
    VoidCallback? onRestoreNote,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = math.max(constraints.maxHeight - 32, 80.0);
        final width = maxW;
        final height = maxH;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    window,
                    if (bubble != null && !bubble.hidden)
                      Positioned(
                        left: width * 0.46,
                        right: 2,
                        bottom: 6 + avatarSize * 0.92,
                        child: LoveNoteCloud(
                          key: ValueKey('${bubble.text}|${bubble.emoji}'),
                          note: bubble,
                          maxWidth: math.max(76.0, width * 0.54 - 2),
                          onPopped: onPopNote ?? () {},
                        ),
                      ),
                    if (bubble != null && bubble.hidden)
                      Positioned(
                        left: width * 0.52,
                        bottom: 6 + avatarSize * 0.90,
                        child: LoveNoteEmber(
                          onRestore: onRestoreNote ?? () {},
                        ),
                      ),
                  ],
                ),
              ),
              WindowSillCaption(label: label),
            ],
          ),
        );
      },
    );
  }

  void _showPresence(BuildContext context, WidgetRef ref) {
    final status = ref.read(partnerStatusProvider).value;
    showAppSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                partnerName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                sleeping
                    ? 'Resting'
                    : (status?.mood ?? mood ?? 'Here'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(AnimationState state) {
    return switch (state) {
      AnimationState.receiving ||
      AnimationState.giving ||
      AnimationState.leanIn =>
        AppColors.affection,
      AnimationState.sorry => AppColors.textSecondary,
      AnimationState.sleeping => const Color(0xFF4338CA),
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
        final y = 0.62 - 0.12 * math.sin(math.pi * t);
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
    final custom = widget.drop.emoji;
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (type) {
      'Kiss' => '💋',
      'Hug' => '💕',
      'Sorry' => '🥺',
      'Note' => '💌',
      _ => type.runes.length <= 2 ? type : '💖',
    };
  }
}

