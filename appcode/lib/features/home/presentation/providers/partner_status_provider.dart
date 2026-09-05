import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../couple/data/supabase_couple_repository.dart';

class PartnerStatus {
  const PartnerStatus({this.mood, this.talkSignal});

  final String? mood;
  final String? talkSignal;
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
    final signalData = await client
        .from('connection_signals')
        .select()
        .eq('couple_id', coupleId)
        .neq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    String? talkSignal;
    if (signalData != null) {
      final createdAt =
          DateTime.parse(signalData['created_at'] as String).toLocal();
      final now = DateTime.now();
      if (createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day) {
        talkSignal = signalData['signal_type'] as String;
      }
    }

    if (!controller.isClosed) {
      controller.add(PartnerStatus(
        mood: moodData?['mood'] as String?,
        talkSignal: talkSignal,
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
        event: PostgresChangeEvent.insert,
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
