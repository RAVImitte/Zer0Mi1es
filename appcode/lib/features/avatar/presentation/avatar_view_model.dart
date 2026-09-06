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

    StreamSubscription<AvatarEvent>? eventsSub;
    ref.onDispose(() => eventsSub?.cancel());

    void bindCouple(String? coupleId) {
      eventsSub?.cancel();
      eventsSub = null;
      if (coupleId == null) return;
      eventsSub = ref
          .read(connectionRepositoryProvider)
          .watchPartnerEvents(coupleId)
          .listen(onEvent);
    }

    ref.listen<AsyncValue<String?>>(
      activeCoupleIdProvider,
      (previous, next) {
        final id = next.value;
        if (id != previous?.value) bindCouple(id);
      },
      fireImmediately: true,
    );

    ref.listen(partnerStatusProvider, (previous, next) {
      final status = next.unwrapPrevious().asData?.value;
      if (status == null) return;
      final prev = previous?.unwrapPrevious().asData?.value;

      if (status.mood != null && prev?.mood != status.mood) {
        final event = _eventForMood(status.mood!);
        if (event != null) onEvent(event);
      }

      if (status.talk != null &&
          !status.talk!.fromMe &&
          prev?.talk?.id != status.talk!.id) {
        onEvent(AvatarEvent.talk);
      }
    });

    return AnimationState.idle;
  }

  Future<void> _initFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final table = prefs.getString(CacheKeys.partnerAnimationTable);
    final type = prefs.getString(CacheKeys.partnerAnimationType);

    if (table != null && type != null) {
      if (table == 'moods') {
        final event = _eventForMood(type);
        if (event != null) onEvent(event);
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
      case AvatarEvent.moodAngry:
        nextState = AnimationState.moodAngry;
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

AvatarEvent? _eventForMood(String mood) {
  return switch (mood) {
    'Happy' => AvatarEvent.moodHappy,
    'Sad' => AvatarEvent.moodSad,
    'Devastated' => AvatarEvent.moodDevastated,
    'Angry' || 'Overwhelmed' => AvatarEvent.moodAngry,
    'Excited' => AvatarEvent.moodExcited,
    'Tired' => AvatarEvent.moodTired,
    _ => null,
  };
}
