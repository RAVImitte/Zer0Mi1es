import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/couple_repository.dart';

part 'supabase_couple_repository.g.dart';

class SupabaseCoupleRepository extends CoupleRepository {
  SupabaseCoupleRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<String?> get activeCoupleId async* {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      yield null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(CacheKeys.activeCoupleId);
    if (cached != null) yield cached;

    await for (final rows in _client.from('couples').stream(primaryKey: ['id'])) {
      try {
        final activeRow = rows.firstWhere((row) =>
            (row['bear_id'] == uid || row['bunny_id'] == uid) &&
            row['bear_id'] != null &&
            row['bunny_id'] != null);
        final coupleId = activeRow['id'] as String;
        prefs.setString(CacheKeys.activeCoupleId, coupleId);
        yield coupleId;
      } catch (_) {
        prefs.remove(CacheKeys.activeCoupleId);
        yield null;
      }
    }
  }

  @override
  Future<String> createCouple() async {
    final rawToken = generateRawToken();
    await _client.rpc('create_couple_with_token', params: {'raw_token': rawToken});
    return rawToken;
  }

  @override
  Future<void> joinCouple(String rawToken) async {
    await _client.rpc('join_couple_with_token', params: {'raw_token': rawToken});
  }
}

@riverpod
CoupleRepository coupleRepository(Ref ref) {
  return SupabaseCoupleRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<String?> activeCoupleId(Ref ref) {
  return ref.watch(coupleRepositoryProvider).activeCoupleId;
}

@riverpod
Future<String?> partnerName(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedName = prefs.getString(CacheKeys.partnerName);

  if (cachedName != null) {
    _fetchAndCachePartnerName(ref, prefs);
    return cachedName;
  }

  return _fetchAndCachePartnerName(ref, prefs);
}

Future<String?> _fetchAndCachePartnerName(
  Ref ref,
  SharedPreferences prefs,
) async {
  final client = ref.read(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  final coupleId = await ref.watch(activeCoupleIdProvider.future);

  if (uid == null || coupleId == null) return null;

  try {
    final coupleRes =
        await client.from('couples').select().eq('id', coupleId).single();
    final partnerId =
        coupleRes['bear_id'] == uid ? coupleRes['bunny_id'] : coupleRes['bear_id'];

    if (partnerId == null) return 'Partner';

    final profileRes = await client
        .from('profiles')
        .select('display_name')
        .eq('id', partnerId)
        .single();
    final name = profileRes['display_name'] as String?;

    if (name != null) {
      await prefs.setString(CacheKeys.partnerName, name);
    }
    return name;
  } catch (_) {
    return prefs.getString(CacheKeys.partnerName) ?? 'Partner';
  }
}

const _roleTimeout = Duration(seconds: 8);

@riverpod
Future<String?> partnerRole(Ref ref) async {
  final role = await ref.watch(myRoleProvider.future);
  if (role == CoupleRole.bear) return CoupleRole.bunny;
  if (role == CoupleRole.bunny) return CoupleRole.bear;
  return null;
}

@riverpod
Future<String?> myRole(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(CacheKeys.myRole);
  if (cached != null) {
    unawaited(_refreshMyRole(ref, prefs));
    return cached;
  }
  return _refreshMyRole(ref, prefs);
}

Future<String?> _refreshMyRole(Ref ref, SharedPreferences prefs) async {
  final client = ref.read(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) return prefs.getString(CacheKeys.myRole);

  String? coupleId;
  try {
    coupleId = await ref
        .read(activeCoupleIdProvider.future)
        .timeout(_roleTimeout);
  } catch (_) {
    coupleId = ref.read(activeCoupleIdProvider).value;
  }
  if (coupleId == null) return prefs.getString(CacheKeys.myRole);

  try {
    final coupleRes = await client
        .from('couples')
        .select('bear_id, bunny_id')
        .eq('id', coupleId)
        .maybeSingle()
        .timeout(_roleTimeout);
    if (coupleRes == null) return prefs.getString(CacheKeys.myRole);
    final String? role;
    if (coupleRes['bear_id'] == uid) {
      role = CoupleRole.bear;
    } else if (coupleRes['bunny_id'] == uid) {
      role = CoupleRole.bunny;
    } else {
      role = null;
    }
    if (role != null) {
      await prefs.setString(CacheKeys.myRole, role);
    }
    return role ?? prefs.getString(CacheKeys.myRole);
  } catch (_) {
    return prefs.getString(CacheKeys.myRole);
  }
}
