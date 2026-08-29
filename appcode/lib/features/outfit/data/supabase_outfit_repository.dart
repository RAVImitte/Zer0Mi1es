import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  return SupabaseOutfitRepository(Supabase.instance.client);
});

abstract class OutfitRepository {
  Future<void> saveOutfit(String coupleId, String topColor, String bottomColor);
  Future<bool> hasOutfitForToday(String coupleId);
  Stream<Map<String, dynamic>?> watchPartnerOutfit(String coupleId);
}

class SupabaseOutfitRepository implements OutfitRepository {
  final SupabaseClient _client;

  SupabaseOutfitRepository(this._client);

  @override
  Future<void> saveOutfit(String coupleId, String topColor, String bottomColor) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    
    final today = DateTime.now().toIso8601String().split('T').first;
    
    await _client.from('daily_outfits').upsert({
      'couple_id': coupleId,
      'user_id': uid,
      'date': today,
      'top_color': topColor,
      'bottom_color': bottomColor,
    }, onConflict: 'couple_id, user_id, date');
  }

  @override
  Future<bool> hasOutfitForToday(String coupleId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    
    final today = DateTime.now().toIso8601String().split('T').first;
    
    final data = await _client.from('daily_outfits')
      .select('id')
      .eq('couple_id', coupleId)
      .eq('user_id', uid)
      .eq('date', today)
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
    
    final today = DateTime.now().toIso8601String().split('T').first;

    // Fetch initial value via HTTP request
    final initialData = await _client.from('daily_outfits')
      .select()
      .eq('couple_id', coupleId)
      .neq('user_id', uid)
      .eq('date', today)
      .maybeSingle();
    yield initialData;

    // Then listen for realtime updates
    yield* _client.from('daily_outfits')
      .stream(primaryKey: ['id'])
      .eq('couple_id', coupleId)
      .neq('user_id', uid)
      .eq('date', today)
      .map((data) => data.isNotEmpty ? data.first : null);
  }
}
