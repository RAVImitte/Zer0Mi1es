import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../avatar/presentation/avatar_view_model.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/partner_status_provider.dart';
import '../../../outfit/data/supabase_outfit_repository.dart';

final partnerOutfitProvider = StreamProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, coupleId) {
  return ref.watch(outfitRepositoryProvider).watchPartnerOutfit(coupleId);
});

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
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
            error: (_, __) => const Text('Partner', style: TextStyle(color: AppColors.primary, fontSize: 24)),
          ),
          const SizedBox(height: 16),
          
          Consumer(
            builder: (context, ref, _) {
              final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
              final outfitAsync = activeCoupleId != null 
                ? ref.watch(partnerOutfitProvider(activeCoupleId)) 
                : const AsyncValue<Map<String, dynamic>?>.data(null);

              Color topColor = avatarColor.withOpacity(0.2);
              Color bottomColor = avatarColor.withOpacity(0.2);

              final outfitValue = outfitAsync.value;

              if (outfitValue != null) {
                final topStr = outfitValue['top_color'] as String;
                final bottomStr = outfitValue['bottom_color'] as String;
                
                final Map<String, Color> colorMap = {
                  'Red': Colors.red, 'Blue': Colors.blue, 'Green': Colors.green, 
                  'Yellow': Colors.yellow, 'Orange': Colors.orange, 'Purple': Colors.purple, 
                  'Black': Colors.black, 'White': Colors.white, 'Pink': Colors.pink, 'Teal': Colors.teal,
                };
                
                topColor = colorMap[topStr] ?? topColor;
                bottomColor = colorMap[bottomStr] ?? bottomColor;
              }

              final screenWidth = MediaQuery.sizeOf(context).width;
              final dynamicSize = screenWidth * 0.35; // Scales beautifully with device width
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()..scale(scale),
                transformAlignment: Alignment.center,
                width: dynamicSize,
                height: dynamicSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [topColor, bottomColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarColor, width: 4),
                ),
                child: Icon(
                  avatarIcon,
                  size: dynamicSize * 0.5,
                  color: avatarColor == Colors.white ? Colors.black : Colors.white, // Contrast against gradient
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            statusText,
            key: ValueKey(statusText),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (status.mood != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mood, color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '$partnerName is feeling ${status.mood} right now',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (status.mood != null && status.talkSignal != null) 
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      if (status.talkSignal != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                () {
                                  switch (status.talkSignal) {
                                    case 'text': return '$partnerName requested to text';
                                    case 'call': return '$partnerName requested a voice call';
                                    case 'video_call': return '$partnerName requested a video call';
                                    case 'goodNight': return '$partnerName is going to sleep 🌙';
                                    default: return '$partnerName sent a signal';
                                  }
                                }(),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
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
  }
}
