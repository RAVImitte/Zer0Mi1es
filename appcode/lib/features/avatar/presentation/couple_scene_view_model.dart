import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../connection/data/supabase_connection_repository.dart';
import '../../connection/domain/love_drop_message.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../../home/presentation/providers/home_providers.dart';
import '../../home/presentation/providers/partner_status_provider.dart';
import '../domain/avatar_event.dart';

class SeatNote {
  const SeatNote(this.text, {this.emoji, this.hidden = false});

  final String text;
  final String? emoji;
  final bool hidden;

  SeatNote hide() => SeatNote(text, emoji: emoji, hidden: true);

  SeatNote reveal() => SeatNote(text, emoji: emoji);

  SeatNote copyHiddenFrom(SeatNote? other) {
    if (other == null || other.text != text) return this;
    return SeatNote(text, emoji: emoji, hidden: other.hidden);
  }

  @override
  bool operator ==(Object other) =>
      other is SeatNote &&
      text == other.text &&
      emoji == other.emoji &&
      hidden == other.hidden;

  @override
  int get hashCode => Object.hash(text, emoji, hidden);
}

class CoupleDrop {
  const CoupleDrop({
    required this.type,
    required this.senderIsLeft,
    required this.playId,
    this.message,
    this.emoji,
  });

  final String type;
  final bool senderIsLeft;
  final int playId;
  final String? message;
  final String? emoji;

  @override
  bool operator ==(Object other) =>
      other is CoupleDrop &&
      type == other.type &&
      senderIsLeft == other.senderIsLeft &&
      playId == other.playId &&
      message == other.message &&
      emoji == other.emoji;

  @override
  int get hashCode => Object.hash(type, senderIsLeft, playId, message, emoji);
}

class CoupleSceneState {
  const CoupleSceneState({
    this.left = AnimationState.idle,
    this.right = AnimationState.idle,
    this.leftMood,
    this.rightMood,
    this.drop,
    this.leftNote,
    this.rightNote,
  });

  final AnimationState left;
  final AnimationState right;
  final String? leftMood;
  final String? rightMood;
  final CoupleDrop? drop;
  final SeatNote? leftNote;
  final SeatNote? rightNote;

  @override
  bool operator ==(Object other) =>
      other is CoupleSceneState &&
      left == other.left &&
      right == other.right &&
      leftMood == other.leftMood &&
      rightMood == other.rightMood &&
      drop == other.drop &&
      leftNote == other.leftNote &&
      rightNote == other.rightNote;

  @override
  int get hashCode =>
      Object.hash(left, right, leftMood, rightMood, drop, leftNote, rightNote);
}

class CoupleSceneViewModel extends Notifier<CoupleSceneState> {
  Timer? _dropTimer;
  String? _optimisticMyMood;
  bool? _optimisticAsleep;
  SeatNote? _myNote;
  SeatNote? _theirNote;
  String? _hydratedFor;
  bool _hydrateRunning = false;
  bool _touchedMine = false;
  bool _touchedTheirs = false;

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

    ref.listen(myRoleProvider, (previous, next) {
      _syncFromStatus();
      final id = ref.read(activeCoupleIdProvider).value;
      if (id != null) _hydrateNotes(id);
    });

    final coupleId = ref.watch(activeCoupleIdProvider.select((v) => v.value));
    if (coupleId != null) {
      ref.listen(loveDropsProvider(coupleId), (previous, next) {
        if (previous == null) return;
        final drop = next.unwrapPrevious().asData?.value;
        if (drop == null) return;
        playDrop(
          drop.type,
          fromMe: false,
          message: drop.message,
          emoji: drop.emoji,
        );
      });
      Future.microtask(() => _hydrateNotes(coupleId));
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

  void playDrop(
    String type, {
    required bool fromMe,
    String? message,
    String? emoji,
  }) {
    _dropTimer?.cancel();
    final senderIsLeft = fromMe ? _iAmLeft : !_iAmLeft;
    final note = message?.trim();
    final hasNote = note != null && note.isNotEmpty;
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

    if (hasNote) {
      final seat = SeatNote(note, emoji: emoji);
      if (fromMe) {
        _myNote = seat;
        _touchedMine = true;
      } else {
        _theirNote = seat;
        _touchedTheirs = true;
      }
      unawaited(_writeCache());
    }

    final bases = _sceneFromStatus();
    state = CoupleSceneState(
      left: left,
      right: right,
      leftMood: bases.leftMood,
      rightMood: bases.rightMood,
      leftNote: bases.leftNote,
      rightNote: bases.rightNote,
      drop: CoupleDrop(
        type: type,
        senderIsLeft: senderIsLeft,
        playId: DateTime.now().microsecondsSinceEpoch,
        message: hasNote ? note : null,
        emoji: emoji,
      ),
    );
    _dropTimer = Timer(const Duration(milliseconds: 2500), () {
      _dropTimer = null;
      _syncFromStatus();
    });
  }

  Future<void> refreshNotes() async {
    final id = ref.read(activeCoupleIdProvider).value;
    if (id == null) return;
    _hydratedFor = null;
    await _hydrateNotes(id);
  }

  Future<void> _hydrateNotes(String coupleId) async {
    if (_hydrateRunning) return;
    if (_hydratedFor == coupleId) return;
    _hydrateRunning = true;
    try {
      await _readCache(coupleId);
      if (_myNote != null || _theirNote != null) _syncFromStatus();

      List<LatestLoveNote> notes = const [];
      Object? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          notes = await ref
              .read(connectionRepositoryProvider)
              .fetchLatestNotes(coupleId);
          lastError = null;
          if (notes.isNotEmpty) break;
        } catch (e) {
          lastError = e;
          debugPrint('hydrate notes attempt $attempt failed: $e');
        }
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 350 * (attempt + 1)),
          );
        }
      }
      if (lastError != null && notes.isEmpty) {
        _hydratedFor = null;
        return;
      }

      final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
      for (final note in notes) {
        final incoming = SeatNote(note.message, emoji: note.emoji);
        if (note.senderId == uid) {
          if (!_touchedMine) {
            _myNote = incoming.copyHiddenFrom(_myNote);
          }
        } else {
          if (!_touchedTheirs) {
            _theirNote = incoming.copyHiddenFrom(_theirNote);
          }
        }
      }
      if (notes.isNotEmpty) {
        _hydratedFor = coupleId;
        await _writeCache();
      } else if (_myNote != null || _theirNote != null || lastError == null) {
        _hydratedFor = coupleId;
      } else {
        _hydratedFor = null;
      }
      _syncFromStatus();
    } catch (e, st) {
      debugPrint('hydrate notes failed: $e\n$st');
      _hydratedFor = null;
    } finally {
      _hydrateRunning = false;
    }
  }

  Future<void> _readCache(String coupleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(CacheKeys.loveNotes(coupleId));
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _myNote ??= _seatFromCache(map['my']);
      _theirNote ??= _seatFromCache(map['their']);
    } catch (e) {
      debugPrint('love note cache read failed: $e');
    }
  }

  Future<void> _writeCache() async {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        CacheKeys.loveNotes(coupleId),
        jsonEncode({
          'my': _seatToCache(_myNote),
          'their': _seatToCache(_theirNote),
        }),
      );
    } catch (e) {
      debugPrint('love note cache write failed: $e');
    }
  }

  static Map<String, dynamic>? _seatToCache(SeatNote? note) {
    if (note == null) return null;
    return {'text': note.text, 'emoji': note.emoji};
  }

  static SeatNote? _seatFromCache(Object? raw) {
    if (raw is! Map) return null;
    final text = (raw['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) return null;
    return SeatNote(text, emoji: raw['emoji'] as String?);
  }

  void dismissNote({required bool mine}) {
    if (mine) {
      _myNote = _myNote?.hide();
    } else {
      _theirNote = _theirNote?.hide();
    }
    _publishNotes();
  }

  void restoreNote({required bool mine}) {
    if (mine) {
      _myNote = _myNote?.reveal();
    } else {
      _theirNote = _theirNote?.reveal();
    }
    _publishNotes();
  }

  void _publishNotes() {
    final notes = _sceneFromStatus();
    state = CoupleSceneState(
      left: state.left,
      right: state.right,
      leftMood: state.leftMood,
      rightMood: state.rightMood,
      drop: state.drop,
      leftNote: notes.leftNote,
      rightNote: notes.rightNote,
    );
  }

  void _syncFromStatus() {
    if (_dropTimer != null) return;
    final next = _sceneFromStatus();
    if (next != state) state = next;
  }

  CoupleSceneState _sceneFromStatus() {
    final iAmLeft = _iAmLeft;
    return CoupleSceneState(
      left: _baseLeft(),
      right: _baseRight(),
      leftMood: _captionFor(left: true),
      rightMood: _captionFor(left: false),
      leftNote: iAmLeft ? _myNote : _theirNote,
      rightNote: iAmLeft ? _theirNote : _myNote,
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
      'Angry' || 'Overwhelmed' => AnimationState.moodAngry,
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
