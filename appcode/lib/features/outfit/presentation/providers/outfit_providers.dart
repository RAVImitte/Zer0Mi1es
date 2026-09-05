import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/supabase_outfit_repository.dart';

final partnerOutfitProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, coupleId) {
  return ref.watch(outfitRepositoryProvider).watchPartnerOutfit(coupleId);
});

final myOutfitProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, coupleId) {
  return ref.watch(outfitRepositoryProvider).watchMyOutfit(coupleId);
});
