import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'couple_repository.dart';

part 'supabase_couple_repository.g.dart';

class SupabaseCoupleRepository extends CoupleRepository {
  final SupabaseClient _client;

  SupabaseCoupleRepository(this._client);

  @override
  Stream<String?> get activeCoupleId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(null);

    // We stream the couples table for any row where this user is bear or bunny
    return _client.from('couples').stream(primaryKey: ['id']).map((rows) {
      try {
        final activeRow = rows.firstWhere((row) =>
            (row['bear_id'] == uid || row['bunny_id'] == uid) &&
            row['bear_id'] != null &&
            row['bunny_id'] != null);
        return activeRow['id'] as String;
      } catch (_) {
        return null; // Not found
      }
    });
  }

  @override
  Future<String> createCouple() async {
    final rawToken = generateRawToken();
    await _client
        .rpc('create_couple_with_token', params: {'raw_token': rawToken});
    return rawToken;
  }

  @override
  Future<void> joinCouple(String rawToken) async {
    await _client
        .rpc('join_couple_with_token', params: {'raw_token': rawToken});
  }
}

@riverpod
CoupleRepository coupleRepository(Ref ref) {
  return SupabaseCoupleRepository(Supabase.instance.client);
}

@riverpod
Stream<String?> activeCoupleId(Ref ref) {
  return ref.watch(coupleRepositoryProvider).activeCoupleId;
}

@riverpod
Future<String?> partnerName(Ref ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  final coupleId = await ref.watch(activeCoupleIdProvider.future);
  
  if (uid == null || coupleId == null) return null;

  // Get the couple row
  final coupleRes = await client.from('couples').select().eq('id', coupleId).single();
  
  // Determine partner ID
  final partnerId = coupleRes['bear_id'] == uid ? coupleRes['bunny_id'] : coupleRes['bear_id'];
  
  if (partnerId == null) return 'Partner'; // If they haven't joined yet

  // Fetch partner profile
  final profileRes = await client.from('profiles').select('display_name').eq('id', partnerId).single();
  return profileRes['display_name'] as String?;
}

@riverpod
Future<String?> partnerRole(Ref ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  final coupleId = await ref.watch(activeCoupleIdProvider.future);
  
  if (uid == null || coupleId == null) return null;

  // Get the couple row
  final coupleRes = await client.from('couples').select().eq('id', coupleId).single();
  
  // If the current user is the bear, the partner is the bunny, and vice versa
  if (coupleRes['bear_id'] == uid) {
    return 'bunny';
  } else if (coupleRes['bunny_id'] == uid) {
    return 'bear';
  }
  
  return null;
}
