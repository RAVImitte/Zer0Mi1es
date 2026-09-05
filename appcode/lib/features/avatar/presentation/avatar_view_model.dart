import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../connection/data/supabase_connection_repository.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../../home/presentation/providers/partner_status_provider.dart';
import '../domain/avatar_event.dart';

export '../domain/avatar_event.dart';

part 'avatar_view_model.g.dart';

@riverpod
class AvatarViewModel extends _$AvatarViewModel {
  Timer? _resetTimer;

  @override
  AnimationState build() {
    _initFromCache();

    // Listen to real-time events from partner if we have a couple ID
    final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
    if (activeCoupleId != null) {
      final repo = ref.watch(connectionRepositoryProvider);
      final subscription =
          repo.watchPartnerEvents(activeCoupleId).listen((event) {
        onEvent(event);
      });
      ref.onDispose(() => subscription.cancel());

      ref.listen(partnerStatusProvider, (previous, next) {
        if (next.hasValue && next.value != null) {
          final status = next.value!;
          
          // Sync Mood
          if (status.mood != null && (previous?.value?.mood != status.mood)) {
            final moodStr = 'mood${status.mood}';
            try {
              final event = AvatarEvent.values.firstWhere((e) => e.name == moodStr);
              onEvent(event);
            } catch (_) {}
          }
          
          // Sync Sleep/Wake
          if (status.talkSignal != null && (previous?.value?.talkSignal != status.talkSignal)) {
            if (status.talkSignal == 'goodNight') onEvent(AvatarEvent.goodNight);
            else if (status.talkSignal == 'goodMorning') onEvent(AvatarEvent.goodMorning);
          }
        }
      }, fireImmediately: true);
    }

    // Start idle
    return AnimationState.idle;
  }

  Future<void> _initFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final table = prefs.getString(CacheKeys.partnerAnimationTable);
    final type = prefs.getString(CacheKeys.partnerAnimationType);

    if (table != null && type != null) {
      if (table == 'moods') {
        // Convert 'Happy' to 'moodHappy'
        final moodStr = 'mood$type';
        try {
          final event = AvatarEvent.values.firstWhere((e) => e.name == moodStr);
          onEvent(event);
        } catch (_) {}
      } else if (table == 'connection_signals') {
        if (type == 'goodNight') onEvent(AvatarEvent.goodNight);
        if (type == 'goodMorning') onEvent(AvatarEvent.goodMorning);
      } else if (table == 'love_drops') {
        if (type == 'Kiss')
          onEvent(AvatarEvent.loveReceived);
        else if (type == 'Hug')
          onEvent(AvatarEvent.hugReceived);
        else
          onEvent(
              AvatarEvent.loveReceived); // Default reaction for custom drops
      }
    }
  }

  void resetToIdle() {
    if (state != AnimationState.sleeping) {
      state = AnimationState.idle;
      _resetTimer?.cancel();
      // Clear cache so it doesn't resume this animation on next load
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove(CacheKeys.partnerAnimationTable);
        prefs.remove(CacheKeys.partnerAnimationType);
      });
    }
  }

  void onEvent(AvatarEvent event) {
    // Cancel any existing timer to prevent premature resets
    _resetTimer?.cancel();

    // Determine the next state based on the event
    AnimationState nextState = state;
    Duration duration =
        const Duration(seconds: 3); // Default animation duration

    switch (event) {
      case AvatarEvent.loveReceived:
      case AvatarEvent.hugReceived:
        nextState = AnimationState.reaction;
        break;
      case AvatarEvent.talk:
      case AvatarEvent.playWithPet:
        // Deliberately no avatar animation; handled by UI status card or ignored.
        break;
      case AvatarEvent.petAnimal:
        nextState = AnimationState.petting;
        break;
      case AvatarEvent.feedPet:
        nextState = AnimationState.feeding;
        duration = const Duration(seconds: 4);
        break;
      case AvatarEvent.goodMorning:
        nextState = AnimationState.idle; // Wake up
        break;
      case AvatarEvent.goodNight:
        nextState = AnimationState.sleeping;
        duration = const Duration(hours: 8); // Sleep until morning event
        break;
      case AvatarEvent.moodHappy:
        nextState = AnimationState.moodHappy;
        break;
      case AvatarEvent.moodSad:
        nextState = AnimationState.moodSad;
        break;
      case AvatarEvent.moodDevastated:
        nextState = AnimationState.moodDevastated;
        break;
      case AvatarEvent.moodOverwhelmed:
        nextState = AnimationState.moodOverwhelmed;
        break;
      case AvatarEvent.moodExcited:
        nextState = AnimationState.moodExcited;
        break;
      case AvatarEvent.moodTired:
        nextState = AnimationState.moodTired;
        break;
    }

    state = nextState;

    // Set a timer to return to IDLE (or another ambient state) after the action completes
    bool isMoodState = nextState.name.startsWith('mood');
    if (nextState != AnimationState.sleeping &&
        nextState != AnimationState.idle &&
        !isMoodState) {
      _resetTimer = Timer(duration, () {
        if (state == nextState) {
          state = AnimationState.idle;
        }
      });
    }
  }
}
