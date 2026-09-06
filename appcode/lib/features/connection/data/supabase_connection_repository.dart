import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/notifications/push_dispatcher.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/talk_expiry.dart';
import '../domain/connection_repository.dart';
import '../domain/love_drop_message.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return SupabaseConnectionRepository(ref.watch(supabaseClientProvider));
});

class SupabaseConnectionRepository implements ConnectionRepository {
  SupabaseConnectionRepository(this._client)
      : _push = PushDispatcher(_client);

  final SupabaseClient _client;
  final PushDispatcher _push;

  @override
  Future<void> sendLoveDrop(String coupleId, String type, {String? message}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('love_drops').insert({
      'couple_id': coupleId,
      'sender_id': uid,
      'type': type,
      if (message != null) 'message': message,
    });

    await _push.notify(table: 'love_drops', record: {
      'couple_id': coupleId,
      'sender_id': uid,
      'user_id': uid,
      'type': type,
      if (message != null) 'message': message,
    });
  }

  @override
  Future<void> updateMood(String coupleId, String mood) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('moods').upsert({
      'couple_id': coupleId,
      'user_id': uid,
      'mood': mood,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'couple_id, user_id');
  }

  @override
  Future<void> sendSignal(String coupleId, String signalType) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final isTalk =
        signalType == 'text' || signalType == 'call' || signalType == 'video_call';
    await _client.from('connection_signals').insert({
      'couple_id': coupleId,
      'user_id': uid,
      'signal_type': signalType,
      if (isTalk)
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 12))
            .toIso8601String(),
    });

    await _push.notify(table: 'connection_signals', record: {
      'couple_id': coupleId,
      'sender_id': uid,
      'user_id': uid,
      'type': signalType,
    });
  }

  @override
  Future<void> acknowledgeSignal(String signalId, String status) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    var iana = 'UTC';
    final profile = await _client
        .from('profiles')
        .select('timezone')
        .eq('id', uid)
        .maybeSingle();
    final tzName = profile?['timezone'] as String?;
    if (tzName != null && tzName.isNotEmpty) iana = tzName;

    final row = await _client
        .from('connection_signals')
        .update({
          'status': status,
          'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
          'acknowledged_by': uid,
          'expires_at': talkReplyExpiry(status, iana: iana).toIso8601String(),
        })
        .eq('id', signalId)
        .select()
        .maybeSingle();
    if (row == null) {
      throw StateError('Acknowledge did not apply');
    }
    final coupleId = row['couple_id'] as String;
    final talkChannel = _client.channel('talk:$coupleId');
    talkChannel.subscribe();
    await talkChannel.sendBroadcastMessage(event: 'ack', payload: {
      'id': signalId,
      'status': status,
      'by': uid,
    });
    await _push.notify(table: 'connection_signals', record: {
      'couple_id': coupleId,
      'user_id': uid,
      'status': status,
      'signal_type': row['signal_type'],
    });
  }

  @override
  Stream<LoveDropMessage> watchLoveDrops(String coupleId) {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();

    final controller = StreamController<LoveDropMessage>();
    final channel = _client.channel('public:love_drops:$coupleId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'love_drops',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (payload) {
            if (payload.newRecord['sender_id'] != uid) {
              controller.add(LoveDropMessage(
                payload.newRecord['type'] as String,
                payload.newRecord['message'] as String?,
              ));
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
