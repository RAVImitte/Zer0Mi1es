import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

class CanvasMural {
  const CanvasMural({required this.strokes, required this.updatedAt});

  final List<Map<String, dynamic>> strokes;
  final DateTime updatedAt;
}

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) {
  return CanvasRepository(ref.watch(supabaseClientProvider));
});

class CanvasRepository {
  CanvasRepository(this._client);

  final SupabaseClient _client;

  Future<CanvasMural?> load(String coupleId) async {
    final row = await _client
        .from('canvases')
        .select('strokes, updated_at')
        .eq('couple_id', coupleId)
        .maybeSingle();
    if (row == null) return null;
    final raw = row['strokes'];
    final strokes = raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return CanvasMural(
      strokes: strokes,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<void> save(String coupleId, List<Map<String, dynamic>> strokes) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('canvases').upsert({
      'couple_id': coupleId,
      'storage_path': '$coupleId/mural.png',
      'strokes': strokes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': uid,
    });
  }

  RealtimeChannel subscribe(
    String coupleId, {
    required void Function(CanvasMural mural) onRemote,
  }) {
    final uid = _client.auth.currentUser?.id;
    final channel = _client.channel('public:canvases:$coupleId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'canvases',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record['updated_by'] == uid) return;
            final raw = record['strokes'];
            final strokes = raw is List
                ? raw
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
                : <Map<String, dynamic>>[];
            final updatedAt = DateTime.tryParse('${record['updated_at']}');
            onRemote(CanvasMural(
              strokes: strokes,
              updatedAt: updatedAt ?? DateTime.now().toUtc(),
            ));
          },
        )
        .subscribe();
    return channel;
  }
}