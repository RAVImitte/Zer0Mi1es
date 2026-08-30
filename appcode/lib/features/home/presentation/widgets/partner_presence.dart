import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../avatar/presentation/avatar_view_model.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/partner_status_provider.dart';
import '../../../outfit/data/supabase_outfit_repository.dart';
import '../../../avatar/presentation/widgets/dynamic_person_avatar.dart';

final partnerOutfitProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, coupleId) {
  return ref.watch(outfitRepositoryProvider).watchPartnerOutfit(coupleId);
});

final myOutfitProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, coupleId) {
  return ref.watch(outfitRepositoryProvider).watchMyOutfit(coupleId);
});

Color _parseColor(String str) {
  if (str.startsWith('#')) {
    // Support both #RRGGBB and #AARRGGBB
    final hex = str.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }
  // Fallback to older saved names if any
  final Map<String, Color> oldMap = {
    'Red': Colors.red, 'Blue': Colors.blue, 'Green': Colors.green,
    'Yellow': Colors.yellow, 'Orange': Colors.orange, 'Purple': Colors.purple,
    'Black': Colors.black, 'White': Colors.white, 'Pink': Colors.pink, 'Teal': Colors.teal,
  };
  return oldMap[str] ?? Colors.transparent;
}

class PartnerPresence extends ConsumerWidget {
  const PartnerPresence({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationState = ref.watch(avatarViewModelProvider);
    final partnerNameAsync = ref.watch(partnerNameProvider);

    // Determine visual properties based on state
    Color avatarColor = AppColors.primary;
    IconData avatarIcon = Icons.person;
    double scale = 1.0;
    String statusText = 'Idle';

    switch (animationState) {
      case AnimationState.idle:
        avatarColor = AppColors.primary;
        avatarIcon = Icons.person_outline;
        statusText = 'Chilling...';
        break;
      case AnimationState.reaction:
        avatarColor = Colors.pinkAccent;
        avatarIcon = Icons.favorite;
        scale = 1.2;
        statusText = 'Feeling the love!';
        break;
      case AnimationState.talking:
        avatarColor = Colors.blueAccent;
        avatarIcon = Icons.record_voice_over;
        scale = 1.1;
        statusText = 'Talking...';
        break;
      case AnimationState.playing:
        avatarColor = Colors.orangeAccent;
        avatarIcon = Icons.sports_esports;
        statusText = 'Playing with pet...';
        break;
      case AnimationState.petting:
        avatarColor = Colors.lightBlueAccent;
        avatarIcon = Icons.pets;
        statusText = 'Petting...';
        break;
      case AnimationState.feeding:
        avatarColor = Colors.greenAccent;
        avatarIcon = Icons.restaurant;
        statusText = 'Feeding pet...';
        break;
      case AnimationState.sleeping:
        avatarColor = Colors.indigo;
        avatarIcon = Icons.bedtime;
        statusText = 'Zzz...';
        break;
      case AnimationState.walking:
        avatarColor = Colors.teal;
        avatarIcon = Icons.directions_walk;
        statusText = 'Walking...';
        break;
      case AnimationState.sitting:
      case AnimationState.resting:
        avatarColor = Colors.blueGrey;
        avatarIcon = Icons.chair;
        statusText = 'Resting...';
        break;
      case AnimationState.moodHappy:
        avatarColor = Colors.amber;
        statusText = 'Super Happy!';
        break;
      case AnimationState.moodSad:
        avatarColor = Colors.grey;
        statusText = 'Feeling Sad...';
        break;
      case AnimationState.moodDevastated:
        avatarColor = Colors.blueGrey;
        statusText = 'Devastated...';
        break;
      case AnimationState.moodOverwhelmed:
        avatarColor = Colors.deepOrange;
        statusText = 'Overwhelmed!';
        break;
      case AnimationState.moodExcited:
        avatarColor = Colors.green;
        statusText = 'Feeling Excited! 🤩';
        break;
      case AnimationState.moodTired:
        avatarColor = Colors.indigo.shade300;
        statusText = 'Feeling Tired...';
        break;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final dynamicSize = screenWidth * 0.48; // Maximize bubble size on the left

    return Container(
      width: screenWidth,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Column: Avatar Bubble
          Expanded(
            flex: 5,
            child: Consumer(
              builder: (context, ref, _) {
                final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
                final outfitAsync = activeCoupleId != null
                    ? ref.watch(partnerOutfitProvider(activeCoupleId))
                    : const AsyncValue<Map<String, dynamic>?>.data(null);
                
                final partnerRoleAsync = ref.watch(partnerRoleProvider);
                final bool isBunny = partnerRoleAsync.value == 'bunny';

                Color topColor = avatarColor.withOpacity(0.2);
                Color bottomColor = avatarColor.withOpacity(0.2);

                final outfitValue = outfitAsync.value;

                if (outfitValue != null) {
                  final topStr = outfitValue['top_color'] as String;
                  final bottomStr = outfitValue['bottom_color'] as String;

                  final parsedTop = _parseColor(topStr);
                  final parsedBottom = _parseColor(bottomStr);
                  topColor = parsedTop == Colors.transparent ? topColor : parsedTop;
                  bottomColor = parsedBottom == Colors.transparent ? bottomColor : parsedBottom;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      transform: Matrix4.identity()..scale(scale),
                      transformAlignment: Alignment.center,
                      width: dynamicSize,
                      height: dynamicSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: avatarColor.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: avatarColor.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5),
                        ],
                      ),
                      child: Center(
                        child: activeCoupleId == null
                            ? GestureDetector(
                                onTap: () => context.push('/couple'),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: dynamicSize * 0.3,
                                      color: AppColors.primary.withOpacity(0.8),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pair Partner',
                                      style: TextStyle(
                                        color: AppColors.primary.withOpacity(0.8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GestureDetector(
                                onTap: () => ref.read(avatarViewModelProvider.notifier).resetToIdle(),
                                child: DynamicPersonAvatar(
                                  state: animationState,
                                  topColor: topColor,
                                  bottomColor: bottomColor,
                                  isBunny: isBunny,
                                  size: dynamicSize * 0.75,
                                ),
                              ),
                      ),
                    ),
                    if (activeCoupleId != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Consumer(
                          builder: (context, ref, child) {
                            final myRoleAsync = ref.watch(myRoleProvider);
                            final outfitAsync = ref.watch(myOutfitProvider(activeCoupleId));

                            final isMyBunny = myRoleAsync.value == 'bunny';
                            Color myTopColor = AppColors.primary.withOpacity(0.2);
                            Color myBottomColor = AppColors.primary.withOpacity(0.2);

                            final myOutfitValue = outfitAsync.value;
                            if (myOutfitValue != null) {
                              myTopColor = _parseColor(myOutfitValue['top_color'] as String);
                              myBottomColor = _parseColor(myOutfitValue['bottom_color'] as String);
                              if (myTopColor == Colors.transparent) myTopColor = AppColors.primary.withOpacity(0.2);
                              if (myBottomColor == Colors.transparent) myBottomColor = AppColors.primary.withOpacity(0.2);
                            }

                            return Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, spreadRadius: 1),
                                ],
                              ),
                              child: ClipOval(
                                child: OverflowBox(
                                  maxHeight: 65,
                                  maxWidth: 65,
                                  child: Transform.translate(
                                    offset: const Offset(0, 4), // Shift down slightly so the head isn't cut off by the top edge of the circle
                                    child: Transform.scale(
                                      scale: 0.95,
                                      alignment: Alignment.center,
                                      child: DynamicPersonAvatar(
                                        state: AnimationState.resting,
                                        topColor: myTopColor,
                                        bottomColor: myBottomColor,
                                        isBunny: isMyBunny,
                                        size: 65,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          // Right Column: Name, Status Text, Partner Card
          Expanded(
            flex: 5,
            child: Consumer(
              builder: (context, ref, child) {
                final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
                if (activeCoupleId == null) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ready to Pair',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the bubble to connect!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    partnerNameAsync.when(
                      data: (name) => Text(
                        name ?? 'Partner',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const SizedBox(height: 28),
                      error: (_, __) => const Text('Partner',
                          style: TextStyle(color: AppColors.primary, fontSize: 24)),
                    ),

                const SizedBox(height: 8),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    statusText,
                    key: ValueKey(statusText),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Partner Status Card
                Consumer(
                  builder: (context, ref, _) {
                    final partnerStatusAsync = ref.watch(partnerStatusProvider);
                    final partnerName = partnerNameAsync.value ?? 'Partner';

                    return partnerStatusAsync.when(
                      data: (status) {
                        if (status.mood == null && status.talkSignal == null) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (status.mood != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.mood,
                                        color: Colors.orangeAccent, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$partnerName is ${status.mood}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (status.mood != null &&
                                  status.talkSignal != null)
                                const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Divider()),
                              if (status.talkSignal != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.notifications_active,
                                        color: Colors.blueAccent, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        () {
                                          switch (status.talkSignal) {
                                            case 'text':
                                              return 'Requested to text';
                                            case 'call':
                                              return 'Requested a call';
                                            case 'video_call':
                                              return 'Requested video call';
                                            case 'goodNight':
                                              return 'Going to sleep 🌙';
                                            case 'nudge':
                                              return 'Nudged you to answer today\'s question! ⏰';
                                            default:
                                              return 'Sent a signal';
                                          }
                                        }(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    ],
  ),
);
  }
}
