import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../connection/data/supabase_connection_repository.dart';
import '../../../connection/domain/love_drop_message.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../../daily_photo/data/supabase_photo_repository.dart';
import '../../../daily_question/data/supabase_question_repository.dart';
import '../../../outfit/data/supabase_outfit_repository.dart';

final loveDropsProvider =
    StreamProvider.autoDispose.family<LoveDropMessage, String>((ref, coupleId) {
  return ref.watch(connectionRepositoryProvider).watchLoveDrops(coupleId);
});

class IsAsleepNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final isAsleepProvider =
    NotifierProvider<IsAsleepNotifier, bool>(IsAsleepNotifier.new);

final outfitCompletedProvider = StreamProvider.autoDispose<bool>((ref) {
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (coupleId == null) return Stream.value(false);
  return ref
      .watch(outfitRepositoryProvider)
      .watchMyOutfit(coupleId)
      .map((outfit) => outfit != null);
});

final photoCompletedProvider = StreamProvider.autoDispose<bool>((ref) {
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  final uid = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (coupleId == null || uid == null) return Stream.value(false);
  return ref
      .watch(photoRepositoryProvider)
      .watchTodayPhotos(coupleId)
      .map((photos) => photos.any((photo) => photo.userId == uid));
});

final questionCompletedProvider = StreamProvider.autoDispose<bool>((ref) {
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (coupleId == null) return Stream.value(false);
  return ref
      .watch(questionRepositoryProvider)
      .watchDailyQuestion(coupleId)
      .map((state) => state.myAnswer != null);
});
