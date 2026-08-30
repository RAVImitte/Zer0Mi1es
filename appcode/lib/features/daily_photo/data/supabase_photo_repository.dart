import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return SupabasePhotoRepository(Supabase.instance.client);
});

class DailyPhoto {
  final String id;
  final String userId;
  final String storagePath;
  final String? comment;
  final String? reactionEmoji;
  final String? reactionText;
  final DateTime createdAt;
  
  DailyPhoto({
    required this.id, 
    required this.userId, 
    required this.storagePath, 
    this.comment,
    this.reactionEmoji,
    this.reactionText,
    required this.createdAt,
  });

  factory DailyPhoto.fromJson(Map<String, dynamic> json) {
    return DailyPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      storagePath: json['storage_path'] as String,
      comment: json['comment'] as String?,
      reactionEmoji: json['reaction_emoji'] as String?,
      reactionText: json['reaction_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

abstract class PhotoRepository {
  Future<void> uploadDailyPhoto(String coupleId, File imageFile, {String? comment});
  Stream<List<DailyPhoto>> watchTodayPhotos(String coupleId);
  Future<String> getSignedUrl(String path);
  Future<bool> hasPartnerUploadedPhoto(String coupleId);
  Future<void> reactToPhoto(String photoId, {String? emoji, String? text});
}

class SupabasePhotoRepository implements PhotoRepository {
  final SupabaseClient _client;

  SupabasePhotoRepository(this._client);

  Future<void> _triggerNotification(String table, String coupleId, Map<String, dynamic> record) async {
    try {
      await _client.functions.invoke('push-notification', body: {
        'table': table,
        'record': record,
      });
    } catch (e) {
      print('Failed to trigger notification: $e');
    }
  }

  @override
  Future<void> uploadDailyPhoto(String coupleId, File imageFile, {String? comment}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    // The image is already compressed by image_picker natively
    final compressedBytes = await imageFile.readAsBytes();

    final today = DateTime.now().toIso8601String().split('T').first;
    final fileName = '$today.jpg';
    final storagePath = '$coupleId/$uid/$fileName';

    // 2. Upload to Storage
    await _client.storage.from('photos').uploadBinary(
      storagePath,
      compressedBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );

    // 3. Save Metadata
    await _client.from('daily_photos').upsert({
      'couple_id': coupleId,
      'user_id': uid,
      'date': today,
      'storage_path': storagePath,
      'comment': comment,
    }, onConflict: 'couple_id, user_id, date');
    
    _triggerNotification('daily_photos', coupleId, {
      'couple_id': coupleId,
      'user_id': uid,
    });
  }

  @override
  Stream<List<DailyPhoto>> watchTodayPhotos(String coupleId) async* {
    final today = DateTime.now().toIso8601String().split('T').first;
    
    // Fetch initial value via HTTP request to prevent infinite loading if WebSocket fails
    final initialData = await _client.from('daily_photos')
      .select()
      .eq('couple_id', coupleId)
      .eq('date', today);
    yield (initialData as List).map((json) => DailyPhoto.fromJson(json)).toList();

    // Then listen for realtime updates
    yield* _client.from('daily_photos')
      .stream(primaryKey: ['id'])
      .eq('couple_id', coupleId)
      .eq('date', today)
      .map((data) => data.map((json) => DailyPhoto.fromJson(json)).toList());
  }


  
  @override
  Future<String> getSignedUrl(String path) async {
    return await _client.storage.from('photos').createSignedUrl(path, 60 * 60);
  }

  @override
  Future<bool> hasPartnerUploadedPhoto(String coupleId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final response = await _client.rpc('has_partner_uploaded_photo', params: {
      'c_id': coupleId,
      'p_date': today,
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
