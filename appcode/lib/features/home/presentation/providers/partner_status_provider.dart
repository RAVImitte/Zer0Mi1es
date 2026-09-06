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
  });

  final String id;
  final String type;
  final String status;
  final bool fromMe;
  final DateTime? expiresAt;
}

class PartnerStatus {
  const PartnerStatus({this.mood, this.talk, this.iAmAsleep = false});

  final String? mood;
  final TalkSignal? talk;
  final bool iAmAsleep;
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
    final exp = row['expires_at'];
    if (exp == null) return true;
    return DateTime.parse(exp as String).toUtc().isAfter(DateTime.now().toUtc());
  }

  bool isTalk(Map<String, dynamic> row) =>
      _talkTypes.contains(row['signal_type']);

  Future<void> fetchStatus() async {
    try {
      final moodData = await client
          .from('moods')
          .select('mood')
          .eq('couple_id', coupleId)
          .neq('user_id', uid)
          .maybeSingle();

      final couple = await client
          .from('couples')
          .select('bear_id, bunny_id')
          .eq('id', coupleId)
          .maybeSingle();
      final me = uid.toString();
      final bear = couple?['bear_id']?.toString();
      final bunny = couple?['bunny_id']?.toString();
      final partnerId = bear == me ? bunny : bear;

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
        return TalkSignal(
          id: row['id'] as String,
          type: row['signal_type'] as String,
          status: row['status'] as String? ?? 'pending',
          fromMe: fromMe,
          expiresAt: expiresOf(row),
        );
      }

      Map<String, dynamic>? incoming;
      Map<String, dynamic>? myLatest;
      for (final row in talkRows) {
        final sender = row['user_id']?.toString();
        final status = row['status'] as String? ?? 'pending';
        if (incoming == null &&
            partnerId != null &&
            sender == partnerId &&
            status == 'pending') {
          incoming = row;
        }
        if (myLatest == null && sender == me) {
          myLatest = row;
        }
      }

      TalkSignal? talk;
      if (incoming != null && !dismissed.contains(incoming['id'])) {
        talk = fromRow(incoming, fromMe: false);
      } else if (incoming != null && dismissed.contains(incoming['id'])) {
        talk = null;
      } else if (myLatest != null) {
        final status = myLatest['status'] as String? ?? 'pending';
        final ackedBy = myLatest['acknowledged_by']?.toString();
        if (status == 'pending' || ackedBy == partnerId) {
          talk = fromRow(myLatest, fromMe: true);
        }
      }

      expiryTimer?.cancel();
      final expiresAt = talk?.expiresAt;
      if (expiresAt != null) {
        final wait = expiresAt.difference(DateTime.now().toUtc());
        if (wait > Duration.zero) {
          expiryTimer = Timer(wait + const Duration(seconds: 1), fetchStatus);
        }
      }

      var iAmAsleep = false;
      for (final row in signals) {
        final sender = row['user_id']?.toString();
        final type = row['signal_type'] as String?;
        if (sender == me && (type == 'goodNight' || type == 'goodMorning')) {
          iAmAsleep = type == 'goodNight';
          break;
        }
      }

      if (!controller.isClosed) {
        controller.add(PartnerStatus(
          mood: moodData?['mood'] as String?,
          talk: talk,
          iAmAsleep: iAmAsleep,
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