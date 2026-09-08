import 'dart:async';

import 'package:flutter/foundation.dart';
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
  Future<void> sendLoveDrop(
    String coupleId,
    String type, {
    String? message,
    String? emoji,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final note = message?.trim();
    final row = <String, dynamic>{
      'couple_id': coupleId,
      'sender_id': uid,
      'type': type,
      if (note != null && note.isNotEmpty) 'message': note,
      if (type == 'Note' && emoji != null && emoji.isNotEmpty) 'emoji': emoji,
    };

    try {
      await _client.from('love_drops').insert(row);
    } catch (e) {
      debugPrint('love_drops insert failed: $e');
      final retry = Map<String, dynamic>.from(row)..remove('emoji');
      try {
        await _client.from('love_drops').insert(retry);
      } catch (e2) {
        debugPrint('love_drops insert retry failed: $e2');
        if (type == 'Note' && note != null && note.isNotEmpty) {
          await _client.from('love_drops').insert({
            'couple_id': coupleId,
            'sender_id': uid,
            'type': 'Note',
            'message': note,
          });
        } else {
          rethrow;
        }
      }
    }

    await _push.notify(table: 'love_drops', record: {
      'couple_id': coupleId,
      'sender_id': uid,
      'user_id': uid,
      'type': type,
      if (note != null && note.isNotEmpty) 'message': note,
      if (type == 'Note' && emoji != null && emoji.isNotEmpty) 'emoji': emoji,
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
                emoji: payload.newRecord['emoji'] as String?,
                senderId: payload.newRecord['sender_id'] as String?,
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

  @override
  Future<List<LatestLoveNote>> fetchLatestNotes(String coupleId) async {
    final rows = await _loveDropRows(coupleId);
    debugPrint('fetchLatestNotes couple=$coupleId rows=${rows.length}');
    return _latestNotesFromRows(rows);
  }

  Future<List<dynamic>> _loveDropRows(String coupleId) async {
    Future<List<dynamic>> select(String cols) {
      return _client
          .from('love_drops')
          .select(cols)
          .eq('couple_id', coupleId)
          .order('created_at', ascending: false)
          .limit(80);
    }

    try {
      return await select('sender_id, message, emoji, type, created_at');
    } catch (e) {
      debugPrint('fetchLatestNotes select failed: $e');
      try {
        return await select('sender_id, message, type, created_at');
      } catch (e2) {
        debugPrint('fetchLatestNotes fallback failed: $e2');
        return await select('sender_id, message, created_at');
      }
    }
  }
}

class _NoteRow {
  const _NoteRow(this.sender, this.message, this.emoji, this.type, this.at);
  final String sender;
  final String message;
  final String? emoji;
  final String type;
  final DateTime at;
}

List<LatestLoveNote> _latestNotesFromRows(List<dynamic> rows) {
  const affection = {'Kiss', 'Hug', 'Sorry'};
  final parsed = <_NoteRow>[];
  for (final raw in rows) {
    final row = Map<String, dynamic>.from(raw as Map);
    final sender = row['sender_id'] as String?;
    final message = (row['message'] as String?)?.trim();
    if (sender == null || message == null || message.isEmpty) continue;
    parsed.add(_NoteRow(
      sender,
      message,
      row['emoji'] as String?,
      row['type'] as String? ?? '',
      DateTime.tryParse('${row['created_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    ));
  }
  parsed.sort((a, b) => b.at.compareTo(a.at));

  bool noteLike(_NoteRow row) =>
      row.type == 'Note' ||
      (row.type.isNotEmpty && !affection.contains(row.type));

  final seen = <String>{};
  final notes = <LatestLoveNote>[];
  void take(bool Function(_NoteRow row) ok) {
    for (final row in parsed) {
      if (!ok(row) || !seen.add(row.sender)) continue;
      notes.add(LatestLoveNote(
        senderId: row.sender,
        message: row.message,
        emoji: row.emoji,
      ));
      if (notes.length >= 2) return;
    }
  }

  take(noteLike);
  if (notes.length < 2) take((_) => true);
  return notes;
}
