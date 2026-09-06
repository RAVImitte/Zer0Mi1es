import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../couple/data/supabase_couple_repository.dart';

const _talkTypes = {'text', 'call', 'video_call'};

class TalkSignal {
  const TalkSignal({
    required this.id,
    required this.type,
    required this.status,
    required this.fromMe,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String status;
  final bool fromMe;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  static const pendingMaxAge = Duration(hours: 8);

  DateTime? get hideAt {
    if (status == 'pending') {
      if (createdAt == null) return null;
      return createdAt!.add(pendingMaxAge);
    }
    return expiresAt;
  }

  @override
  bool operator ==(Object other) =>
      other is TalkSignal &&
      id == other.id &&
      type == other.type &&
      status == other.status &&
      fromMe == other.fromMe &&
      expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(id, type, status, fromMe, expiresAt);
}

class PartnerStatus {
  const PartnerStatus({
    this.mood,
    this.myMood,
    this.talk,
    this.iAmAsleep = false,
    this.partnerAsleep = false,
  });

  /// Partner's latest mood label (Happy, Tired, …).
  final String? mood;
  final String? myMood;
  final TalkSignal? talk;
  final bool iAmAsleep;
  final bool partnerAsleep;
}

class DismissedTalkIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void add(String id) => state = {...state, id};

  void remove(String id) => state = {...state}..remove(id);
}

final dismissedTalkIdsProvider =
    NotifierProvider<DismissedTalkIds, Set<String>>(DismissedTalkIds.new);

final partnerStatusProvider = StreamProvider<PartnerStatus>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  final coupleId = ref.watch(activeCoupleIdProvider.select((v) => v.value));

  if (uid == null || coupleId == null) {
    return Stream.value(const PartnerStatus());
  }

  final controller = StreamController<PartnerStatus>();
  Timer? expiryTimer;

  bool isActive(Map<String, dynamic> row) {
    final status = row['status'] as String? ?? 'pending';
    final now = DateTime.now().toUtc();
    if (status == 'pending') {
      final created = DateTime.tryParse(row['created_at'] as String? ?? '');
      if (created == null) return true;
      return now.difference(created.toUtc()) < TalkSignal.pendingMaxAge;
    }
    final exp = row['expires_at'];
    if (exp == null) return false;
    return DateTime.parse(exp as String).toUtc().isAfter(now);
  }

  bool isTalk(Map<String, dynamic> row) =>
      _talkTypes.contains(row['signal_type']);

  Future<void> fetchStatus() async {
    try {
      final moodRows = await client
          .from('moods')
          .select('user_id, mood')
          .eq('couple_id', coupleId);

      final couple = await client
          .from('couples')
          .select('bear_id, bunny_id')
          .eq('id', coupleId)
          .maybeSingle();
      final me = uid.toString();
      final bear = couple?['bear_id']?.toString();
      final bunny = couple?['bunny_id']?.toString();
      final partnerId = bear == me ? bunny : bear;

      String? myMood;
      String? partnerMood;
      for (final row in (moodRows as List).cast<Map<String, dynamic>>()) {
        final owner = row['user_id']?.toString();
        final label = row['mood'] as String?;
        if (owner == me) myMood = label;
        if (partnerId != null && owner == partnerId) partnerMood = label;
      }

      final rows = await client
          .from('connection_signals')
          .select()
          .eq('couple_id', coupleId)
          .order('created_at', ascending: false)
          .limit(30);

      final signals = (rows as List).cast<Map<String, dynamic>>();
      final talkRows = signals.where(isTalk).where(isActive).toList();
      final dismissed = ref.read(dismissedTalkIdsProvider);

      DateTime? expiresOf(Map<String, dynamic> row) {
        final raw = row['expires_at'];
        if (raw == null) return null;
        return DateTime.tryParse(raw as String)?.toUtc();
      }

      TalkSignal fromRow(Map<String, dynamic> row, {required bool fromMe}) {
        final created = DateTime.tryParse(row['created_at'] as String? ?? '');
        return TalkSignal(
          id: row['id'] as String,
          type: row['signal_type'] as String,
          status: row['status'] as String? ?? 'pending',
          fromMe: fromMe,
          expiresAt: expiresOf(row),
          createdAt: created?.toUtc(),
        );
      }

      TalkSignal? talk;
      for (final row in talkRows) {
        final sender = row['user_id']?.toString();
        final status = row['status'] as String? ?? 'pending';
        if (partnerId != null && sender == partnerId) {
          if (status != 'pending') continue;
          if (dismissed.contains(row['id'])) {
            talk = null;
            break;
          }
          talk = fromRow(row, fromMe: false);
          break;
        }
        if (sender == me) {
          final ackedBy = row['acknowledged_by']?.toString();
          if (status == 'pending' || ackedBy == partnerId) {
            talk = fromRow(row, fromMe: true);
            break;
          }
        }
      }

      expiryTimer?.cancel();
      final hideAt = talk?.hideAt;
      if (hideAt != null) {
        final wait = hideAt.difference(DateTime.now().toUtc());
        if (wait > Duration.zero) {
          expiryTimer = Timer(wait + const Duration(seconds: 1), fetchStatus);
        }
      }

      var iAmAsleep = false;
      var partnerAsleep = false;
      var seenMeSleep = false;
      var seenPartnerSleep = false;
      void readSleep(List<Map<String, dynamic>> rows) {
        for (final row in rows) {
          final type = row['signal_type'] as String?;
          if (type != 'goodNight' && type != 'goodMorning') continue;
          final sender = row['user_id']?.toString();
          if (!seenMeSleep && sender == me) {
            iAmAsleep = type == 'goodNight';
            seenMeSleep = true;
          }
          if (!seenPartnerSleep && partnerId != null && sender == partnerId) {
            partnerAsleep = type == 'goodNight';
            seenPartnerSleep = true;
          }
          if (seenMeSleep && seenPartnerSleep) return;
        }
      }

      readSleep(signals);
      if (!seenMeSleep || !seenPartnerSleep) {
        final sleepRows = await client
            .from('connection_signals')
            .select('user_id, signal_type')
            .eq('couple_id', coupleId)
            .inFilter('signal_type', ['goodNight', 'goodMorning'])
            .order('created_at', ascending: false)
            .limit(10);
        readSleep((sleepRows as List).cast<Map<String, dynamic>>());
      }

      if (!controller.isClosed) {
        controller.add(PartnerStatus(
          mood: partnerMood,
          myMood: myMood,
          talk: talk,
          iAmAsleep: iAmAsleep,
          partnerAsleep: partnerAsleep,
        ));
      }
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  fetchStatus();
  final poll = Timer.periodic(const Duration(seconds: 5), (_) => fetchStatus());

  final channel = client.channel('public:partner_status:$coupleId');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'moods',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'couple_id',
          value: coupleId,
        ),
        callback: (_) => fetchStatus(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'connection_signals',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'couple_id',
          value: coupleId,
        ),
        callback: (_) => fetchStatus(),
      )
      .subscribe();

  final talkChannel = client.channel('talk:$coupleId');
  talkChannel
      .onBroadcast(
        event: 'ack',
        callback: (_) => fetchStatus(),
      )
      .subscribe();

  ref.onDispose(() {
    expiryTimer?.cancel();
    poll.cancel();
    client.removeChannel(channel);
    client.removeChannel(talkChannel);
    controller.close();
  });

  return controller.stream;
});