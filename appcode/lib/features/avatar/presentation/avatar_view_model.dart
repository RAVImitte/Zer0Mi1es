import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../../home/data/supabase_connection_repository.dart';

part 'avatar_view_model.g.dart';

enum AnimationState {
  idle,
  walking,
  playing,
  petting,
  feeding,
  sitting,
  resting,
  sleeping,
  reaction,
  talking
}

enum AvatarEvent {
  loveReceived,
  hugReceived,
  talk,
  goodMorning,
  goodNight,
  feedPet,
  petAnimal,
  playWithPet,
}

@riverpod
class AvatarViewModel extends _$AvatarViewModel {
  Timer? _resetTimer;

  @override
  AnimationState build() {
    // Listen to real-time events from partner if we have a couple ID
    final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
    if (activeCoupleId != null) {
      final repo = ref.watch(connectionRepositoryProvider);
      final subscription = repo.watchPartnerEvents(activeCoupleId).listen((event) {
        onEvent(event);
      });
      ref.onDispose(() => subscription.cancel());
    }

    // Start idle
    return AnimationState.idle;
  }


  void onEvent(AvatarEvent event) {
    // Cancel any existing timer to prevent premature resets
    _resetTimer?.cancel();

    // Determine the next state based on the event
    AnimationState nextState = state;
    Duration duration = const Duration(seconds: 3); // Default animation duration

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
    }

    state = nextState;

    // Set a timer to return to IDLE (or another ambient state) after the action completes
    if (nextState != AnimationState.sleeping && nextState != AnimationState.idle) {
      _resetTimer = Timer(duration, () {
        if (state == nextState) {
          state = AnimationState.idle;
        }
      });
    }
  }
}
