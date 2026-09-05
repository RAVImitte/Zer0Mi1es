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
  });

  final String id;
  final String type;
  final String status;
  final bool fromMe;
}

class PartnerStatus {
  const PartnerStatus({this.mood, this.talk});

  final String? mood;
  final TalkSignal? talk;
}

final partnerStatusProvider = StreamProvider<PartnerStatus>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  final coupleId = ref.watch(activeCoupleIdProvider.select((v) => v.value));

  if (uid == null || coupleId == null) {
    return Stream.value(const PartnerStatus());
  }

  final controller = StreamController<PartnerStatus>();

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

      Map<String, dynamic>? incoming;
      Map<String, dynamic>? outgoingAck;
      for (final row in talkRows) {
        final sender = row['user_id']?.toString();
        final status = row['status'] as String? ?? 'pending';
        if (incoming == null &&
            partnerId != null &&
            sender == partnerId &&
            status == 'pending') {
          incoming = row;
        }
        if (outgoingAck == null && sender == me && status != 'pending') {
          outgoingAck = row;
        }
      }

      TalkSignal? talk;
      if (incoming != null) {
        talk = TalkSignal(
          id: incoming['id'] as String,
          type: incoming['signal_type'] as String,
          status: incoming['status'] as String? ?? 'pending',
          fromMe: false,
        );
      } else if (outgoingAck != null) {
        talk = TalkSignal(
          id: outgoingAck['id'] as String,
          type: outgoingAck['signal_type'] as String,
          status: outgoingAck['status'] as String,
          fromMe: true,
        );
      }

      if (!controller.isClosed) {
        controller.add(PartnerStatus(
          mood: moodData?['mood'] as String?,
          talk: talk,
        ));
      }
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  fetchStatus();

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

  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});