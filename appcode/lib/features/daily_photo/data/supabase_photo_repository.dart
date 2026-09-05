import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/notifications/push_dispatcher.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/iso_date.dart';
import '../domain/daily_photo.dart';
import '../domain/photo_repository.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return SupabasePhotoRepository(ref.watch(supabaseClientProvider));
});

class SupabasePhotoRepository implements PhotoRepository {
  SupabasePhotoRepository(this._client) : _push = PushDispatcher(_client);

  final SupabaseClient _client;
  final PushDispatcher _push;

  @override
  Future<void> uploadDailyPhoto(
    String coupleId,
    File imageFile, {
    String? comment,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final bytes = await imageFile.readAsBytes();
    final today = isoDate();
    final storagePath = '$coupleId/$uid/$today.jpg';

    await _client.storage.from('photos').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    await _client.from('daily_photos').upsert({
      'couple_id': coupleId,
      'user_id': uid,
      'date': today,
      'storage_path': storagePath,
      'comment': comment,
    }, onConflict: 'couple_id, user_id, date');

    await _push.notify(table: 'daily_photos', record: {
      'couple_id': coupleId,
      'user_id': uid,
    });
  }

  @override
  Stream<List<DailyPhoto>> watchTodayPhotos(String coupleId) async* {
    final today = isoDate();

    final initialData = await _client
        .from('daily_photos')
        .select()
        .eq('couple_id', coupleId)
        .eq('date', today);
    yield (initialData as List)
        .map((json) => DailyPhoto.fromJson(json as Map<String, dynamic>))
        .toList();

    yield* _client
        .from('daily_photos')
        .stream(primaryKey: ['id'])
        .eq('couple_id', coupleId)
        .eq('date', today)
        .map((data) => data.map(DailyPhoto.fromJson).toList());
  }

  @override
  Future<String> getSignedUrl(String path) {
    return _client.storage.from('photos').createSignedUrl(path, 60 * 60);
  }

  @override
  Future<bool> hasPartnerUploadedPhoto(String coupleId) async {
    final response = await _client.rpc('has_partner_uploaded_photo', params: {
      'c_id': coupleId,
      'p_date': isoDate(),
    });
    return response as bool? ?? false;
  }

  @override
  Future<void> reactToPhoto(String photoId, {String? emoji, String? text}) async {
    final updates = <String, dynamic>{};
    if (emoji != null) updates['reaction_emoji'] = emoji;
    if (text != null) updates['reaction_text'] = text;
    if (updates.isEmpty) return;

    await _client.from('daily_photos').update(updates).eq('id', photoId);
  }
}
