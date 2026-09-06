import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../../home/presentation/providers/home_providers.dart';
import '../../home/presentation/providers/partner_status_provider.dart';
import 'avatar_view_model.dart';

class CoupleDrop {
  const CoupleDrop({
    required this.type,
    required this.senderIsLeft,
    required this.playId,
  });

  final String type;
  final bool senderIsLeft;
  final int playId;

  @override
  bool operator ==(Object other) =>
      other is CoupleDrop &&
      type == other.type &&
      senderIsLeft == other.senderIsLeft &&
      playId == other.playId;

  @override
  int get hashCode => Object.hash(type, senderIsLeft, playId);
}

class CoupleSceneState {
  const CoupleSceneState({
    this.left = AnimationState.idle,
    this.right = AnimationState.idle,
    this.leftMood,
    this.rightMood,
    this.drop,
  });

  final AnimationState left;
  final AnimationState right;
  final String? leftMood;
  final String? rightMood;
  final CoupleDrop? drop;

  @override
  bool operator ==(Object other) =>
      other is CoupleSceneState &&
      left == other.left &&
      right == other.right &&
      leftMood == other.leftMood &&
      rightMood == other.rightMood &&
      drop == other.drop;

  @override
  int get hashCode => Object.hash(left, right, leftMood, rightMood, drop);
}

class CoupleSceneViewModel extends Notifier<CoupleSceneState> {
  Timer? _dropTimer;
  String? _optimisticMyMood;
  bool? _optimisticAsleep;

  @override
  CoupleSceneState build() {
    ref.onDispose(() => _dropTimer?.cancel());

    ref.listen(partnerStatusProvider, (previous, next) {
      final mine = next.unwrapPrevious().asData?.value.myMood;
      if (mine != null && mine == _optimisticMyMood) {
        _optimisticMyMood = null;
      }
      final asleep = next.unwrapPrevious().asData?.value.iAmAsleep;
      if (asleep != null && asleep == _optimisticAsleep) {
        _optimisticAsleep = null;
      }
      _syncFromStatus();
    });

    ref.listen(myRoleProvider, (previous, next) => _syncFromStatus());

    final coupleId = ref.watch(activeCoupleIdProvider.select((v) => v.value));
    if (coupleId != null) {
      ref.listen(loveDropsProvider(coupleId), (previous, next) {
        if (previous == null) return;
        final drop = next.unwrapPrevious().asData?.value;
        if (drop == null) return;
        playDrop(drop.type, fromMe: false);
      });
    }

    return _sceneFromStatus();
  }

  bool get _iAmLeft {
    final role = ref.read(myRoleProvider).value;
    return role != CoupleRole.bunny;
  }

  void setMyMood(String mood) {
    _optimisticMyMood = mood;
    _syncFromStatus();
  }

  void setMyAsleep(bool asleep) {
    _optimisticAsleep = asleep;
    _syncFromStatus();
  }

  void playDrop(String type, {required bool fromMe}) {
    _dropTimer?.cancel();
    final senderIsLeft = fromMe ? _iAmLeft : !_iAmLeft;
    var left = _baseLeft();
    var right = _baseRight();

    if (type == 'Hug') {
      left = AnimationState.leanIn;
      right = AnimationState.leanIn;
    } else if (type == 'Sorry') {
      if (senderIsLeft) {
        left = AnimationState.sorry;
      } else {
        right = AnimationState.sorry;
      }
    } else {
      if (senderIsLeft) {
        left = AnimationState.giving;
        right = AnimationState.receiving;
      } else {
        right = AnimationState.giving;
        left = AnimationState.receiving;
      }
    }

    final bases = _sceneFromStatus();
    state = CoupleSceneState(
      left: left,
      right: right,
      leftMood: bases.leftMood,
      rightMood: bases.rightMood,
      drop: CoupleDrop(
        type: type,
        senderIsLeft: senderIsLeft,
        playId: DateTime.now().microsecondsSinceEpoch,
      ),
    );
    _dropTimer = Timer(const Duration(milliseconds: 2500), () {
      _dropTimer = null;
      _syncFromStatus();
    });
  }

  void _syncFromStatus() {
    if (_dropTimer != null) return;
    final next = _sceneFromStatus();
    if (next != state) state = next;
  }

  CoupleSceneState _sceneFromStatus() {
    return CoupleSceneState(
      left: _baseLeft(),
      right: _baseRight(),
      leftMood: _captionFor(left: true),
      rightMood: _captionFor(left: false),
    );
  }

  AnimationState _baseLeft() => _stateFor(left: true);

  AnimationState _baseRight() => _stateFor(left: false);

  AnimationState _stateFor({required bool left}) {
    final status = ref.read(partnerStatusProvider).unwrapPrevious().asData?.value;
    final iAmLeft = _iAmLeft;
    final isMe = left == iAmLeft;
    final asleep = isMe
        ? (_optimisticAsleep ?? status?.iAmAsleep ?? false)
        : (status?.partnerAsleep ?? false);
    if (asleep) return AnimationState.sleeping;
    final mood = isMe
        ? (_optimisticMyMood ?? status?.myMood)
        : status?.mood;
    return _moodState(mood);
  }

  String? _captionFor({required bool left}) {
    final status = ref.read(partnerStatusProvider).unwrapPrevious().asData?.value;
    final iAmLeft = _iAmLeft;
    final isMe = left == iAmLeft;
    final asleep = isMe
        ? (_optimisticAsleep ?? status?.iAmAsleep ?? false)
        : (status?.partnerAsleep ?? false);
    if (asleep) return 'Sleeping';
    return isMe ? (_optimisticMyMood ?? status?.myMood) : status?.mood;
  }

  AnimationState _moodState(String? mood) {
    return switch (mood) {
      'Happy' => AnimationState.moodHappy,
      'Sad' => AnimationState.moodSad,
      'Devastated' => AnimationState.moodDevastated,
      'Overwhelmed' => AnimationState.moodOverwhelmed,
      'Excited' => AnimationState.moodExcited,
      'Tired' => AnimationState.moodTired,
      _ => AnimationState.idle,
    };
  }
}

final coupleSceneProvider =
    NotifierProvider<CoupleSceneViewModel, CoupleSceneState>(
  CoupleSceneViewModel.new,
);
