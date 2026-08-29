import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../avatar/presentation/avatar_view_model.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return SupabaseConnectionRepository(Supabase.instance.client);
});

abstract class ConnectionRepository {
  Future<void> sendLoveDrop(String coupleId, String type, {String? message});
  Future<void> updateMood(String coupleId, String mood);
  Future<void> sendSignal(String coupleId, String signalType);
  Stream<AvatarEvent> watchPartnerEvents(String coupleId);
}

class SupabaseConnectionRepository implements ConnectionRepository {
  final SupabaseClient _client;

  SupabaseConnectionRepository(this._client);

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
    
    _triggerNotification('love_drops', coupleId, type);
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
    
    _triggerNotification('connection_signals', coupleId, signalType);
  }

  Future<void> _triggerNotification(String table, String coupleId, String type) async {
    final uid = _client.auth.currentUser?.id;
    try {
      await _client.functions.invoke('push-notification', body: {
        'table': table,
        'record': {
          'couple_id': coupleId,
          'sender_id': uid,
          'user_id': uid,
          'type': type,
        }
      });
    } catch (e) {
      print('Failed to trigger notification: $e');
    }
  }

  @override
  Stream<AvatarEvent> watchPartnerEvents(String coupleId) {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();

    final controller = StreamController<AvatarEvent>();

    // Listen to love_drops
    final channel = _client.channel('public:events:$coupleId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'love_drops',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'couple_id', value: coupleId),
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord['sender_id'] != uid) {
          controller.add(AvatarEvent.loveReceived);
        }
      },
    ).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'moods',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'couple_id', value: coupleId),
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord['user_id'] != uid) {
          final mood = newRecord['mood'] as String?;
          if (mood == 'Happy') controller.add(AvatarEvent.moodHappy);
          else if (mood == 'Sad') controller.add(AvatarEvent.moodSad);
          else if (mood == 'Devastated') controller.add(AvatarEvent.moodDevastated);
          else if (mood == 'Overwhelmed') controller.add(AvatarEvent.moodOverwhelmed);
          else if (mood == 'Excited') controller.add(AvatarEvent.moodExcited);
          else if (mood == 'Tired') controller.add(AvatarEvent.moodTired);
        }
      },
    ).onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'connection_signals',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'couple_id', value: coupleId),
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord['user_id'] != uid) {
          final type = newRecord['signal_type'] as String;
          if (type == 'feed') {
            controller.add(AvatarEvent.feedPet);
          } else if (type == 'pet') {
            controller.add(AvatarEvent.petAnimal);
          } else if (type == 'goodMorning') {
            controller.add(AvatarEvent.goodMorning);
          } else if (type == 'goodNight') {
            controller.add(AvatarEvent.goodNight);
          } else if (type == 'talk') {
            controller.add(AvatarEvent.talk);
          } else {
            controller.add(AvatarEvent.hugReceived);
          }
        }
      },
    ).subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
