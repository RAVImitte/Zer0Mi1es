import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/notifications/push_dispatcher.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../avatar/domain/avatar_event.dart';
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
    await _client.from('connection_signals').insert({
      'couple_id': coupleId,
      'user_id': uid,
      'signal_type': signalType,
    });

    await _push.notify(table: 'connection_signals', record: {
      'couple_id': coupleId,
      'sender_id': uid,
      'user_id': uid,
      'type': signalType,
    });
  }

  @override
  Stream<AvatarEvent> watchPartnerEvents(String coupleId) {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();

    final controller = StreamController<AvatarEvent>();
    final channel = _client.channel('public:events:$coupleId');

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
              controller.add(AvatarEvent.loveReceived);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'moods',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (payload) {
            if (payload.newRecord['user_id'] == uid) return;
            final mood = payload.newRecord['mood'] as String?;
            switch (mood) {
              case 'Happy':
                controller.add(AvatarEvent.moodHappy);
              case 'Sad':
                controller.add(AvatarEvent.moodSad);
              case 'Devastated':
                controller.add(AvatarEvent.moodDevastated);
              case 'Overwhelmed':
                controller.add(AvatarEvent.moodOverwhelmed);
              case 'Excited':
                controller.add(AvatarEvent.moodExcited);
              case 'Tired':
                controller.add(AvatarEvent.moodTired);
            }
          },
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
          callback: (payload) {
            if (payload.newRecord['user_id'] == uid) return;
            final type = payload.newRecord['signal_type'] as String;
            switch (type) {
              case 'feed':
                controller.add(AvatarEvent.feedPet);
              case 'pet':
                controller.add(AvatarEvent.petAnimal);
              case 'goodMorning':
                controller.add(AvatarEvent.goodMorning);
              case 'goodNight':
                controller.add(AvatarEvent.goodNight);
              case 'talk':
                controller.add(AvatarEvent.talk);
              default:
                controller.add(AvatarEvent.hugReceived);
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
