import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../couple/data/supabase_couple_repository.dart';

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

final partnerStatusProvider = StreamProvider.autoDispose<PartnerStatus>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  final coupleId = ref.watch(activeCoupleIdProvider).value;

  if (uid == null || coupleId == null) {
    return Stream.value(const PartnerStatus());
  }

  final controller = StreamController<PartnerStatus>();

  Future<void> fetchStatus() async {
    final moodData = await client
        .from('moods')
        .select('mood')
        .eq('couple_id', coupleId)
        .neq('user_id', uid)
        .maybeSingle();

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final incoming = await client
        .from('connection_signals')
        .select()
        .eq('couple_id', coupleId)
        .eq('status', 'pending')
        .neq('user_id', uid)
        .or('signal_type.eq.text,signal_type.eq.call,signal_type.eq.video_call')
        .or('expires_at.is.null,expires_at.gt.$nowIso')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final outgoing = incoming != null
        ? null
        : await client
            .from('connection_signals')
            .select()
            .eq('couple_id', coupleId)
            .eq('user_id', uid)
            .or('signal_type.eq.text,signal_type.eq.call,signal_type.eq.video_call')
            .or('expires_at.is.null,expires_at.gt.$nowIso')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    TalkSignal? talk;
    if (incoming != null) {
      talk = TalkSignal(
        id: incoming['id'] as String,
        type: incoming['signal_type'] as String,
        status: incoming['status'] as String? ?? 'pending',
        fromMe: false,
      );
    } else if (outgoing != null &&
        outgoing['status'] != null &&
        outgoing['status'] != 'pending') {
      talk = TalkSignal(
        id: outgoing['id'] as String,
        type: outgoing['signal_type'] as String,
        status: outgoing['status'] as String,
        fromMe: true,
      );
    }

    if (!controller.isClosed) {
      controller.add(PartnerStatus(
        mood: moodData?['mood'] as String?,
        talk: talk,
      ));
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