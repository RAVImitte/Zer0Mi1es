import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/supabase_photo_repository.dart';
import '../../domain/daily_photo.dart';

final todayPhotosProvider =
    StreamProvider.autoDispose.family<List<DailyPhoto>, String>((ref, coupleId) {
  return ref.watch(photoRepositoryProvider).watchTodayPhotos(coupleId);
});

final partnerPhotoStatusProvider =
    StreamProvider.autoDispose.family<bool, String>((ref, coupleId) {
  final controller = StreamController<bool>();
  final repo = ref.watch(photoRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);

  void fetchStatus() async {
    final hasUploaded = await repo.hasPartnerUploadedPhoto(coupleId);
    if (!controller.isClosed) controller.add(hasUploaded);
  }

  fetchStatus();

  final channel = client.channel('public:daily_photos_status:$coupleId');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'daily_photos',
        callback: (_) => fetchStatus(),
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
