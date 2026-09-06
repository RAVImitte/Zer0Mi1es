import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/notifications/push_dispatcher.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/voice_drop.dart';

final voiceRepositoryProvider = Provider<VoiceDropRepository>((ref) {
  return VoiceDropRepository(ref.watch(supabaseClientProvider));
});

class VoiceDropRepository {
  VoiceDropRepository(this._client) : _push = PushDispatcher(_client);

  final SupabaseClient _client;
  final PushDispatcher _push;

  Future<void> send({
    required String coupleId,
    required File file,
    required int durationMs,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final path = '$coupleId/$uid/$id.m4a';
    await _client.storage.from('voice').upload(path, file);
    await _client.from('voice_drops').insert({
      'couple_id': coupleId,
      'sender_id': uid,
      'storage_path': path,
      'duration_ms': durationMs,
    });
    await _push.notify(table: 'voice_drops', record: {
      'couple_id': coupleId,
      'user_id': uid,
      'sender_id': uid,
    });
  }

  Future<String> signedUrl(String path) {
    return _client.storage.from('voice').createSignedUrl(path, 3600);
  }

  Stream<VoiceDrop?> watchPartnerDrop(String coupleId) {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(null);

    final controller = StreamController<VoiceDrop?>();

    Future<void> fetch() async {
      final row = await _client
          .from('voice_drops')
          .select()
          .eq('couple_id', coupleId)
          .neq('sender_id', uid)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (!controller.isClosed) {
        controller.add(row == null ? null : VoiceDrop.fromMap(row));
      }
    }

    fetch();
    final channel = _client.channel('public:voice:$coupleId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'voice_drops',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => fetch(),
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };
    return controller.stream;
  }
}