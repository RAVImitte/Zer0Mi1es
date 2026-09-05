import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/notifications/push_dispatcher.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/iso_date.dart';
import '../domain/outfit_repository.dart';

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  return SupabaseOutfitRepository(ref.watch(supabaseClientProvider));
});

class SupabaseOutfitRepository implements OutfitRepository {
  SupabaseOutfitRepository(this._client) : _push = PushDispatcher(_client);

  final SupabaseClient _client;
  final PushDispatcher _push;

  @override
  Future<void> saveOutfit(
    String coupleId,
    String topColor,
    String bottomColor,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final today = isoDate();
    await _client.from('daily_outfits').upsert({
      'couple_id': coupleId,
      'user_id': uid,
      'date': today,
      'top_color': topColor,
      'bottom_color': bottomColor,
    }, onConflict: 'couple_id, user_id, date');

    await _push.notify(table: 'daily_outfits', record: {
      'couple_id': coupleId,
      'user_id': uid,
    });
  }

  @override
  Future<bool> hasOutfitForToday(String coupleId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;

    final data = await _client
        .from('daily_outfits')
        .select('id')
        .eq('couple_id', coupleId)
        .eq('user_id', uid)
        .eq('date', isoDate())
        .maybeSingle();

    return data != null;
  }

  @override
  Stream<Map<String, dynamic>?> watchPartnerOutfit(String coupleId) async* {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      yield null;
      return;
    }

    final today = isoDate();
    yield await _client
        .from('daily_outfits')
        .select()
        .eq('couple_id', coupleId)
        .neq('user_id', uid)
        .eq('date', today)
        .maybeSingle();

    yield* _client
        .from('daily_outfits')
        .stream(primaryKey: ['id'])
        .eq('couple_id', coupleId)
        .neq('user_id', uid)
        .eq('date', today)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  @override
  Stream<Map<String, dynamic>?> watchMyOutfit(String coupleId) async* {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      yield null;
      return;
    }

    final today = isoDate();
    yield await _client
        .from('daily_outfits')
        .select()
        .eq('couple_id', coupleId)
        .eq('user_id', uid)
        .eq('date', today)
        .maybeSingle();

    yield* _client
        .from('daily_outfits')
        .stream(primaryKey: ['id'])
        .eq('couple_id', coupleId)
        .eq('user_id', uid)
        .eq('date', today)
        .map((data) => data.isNotEmpty ? data.first : null);
  }
}
