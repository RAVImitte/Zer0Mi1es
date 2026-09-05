import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/partner_scene.dart';
import '../../../couple/data/supabase_couple_repository.dart';

final partnerSceneProvider = FutureProvider.autoDispose<PartnerScene>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (uid == null || coupleId == null) {
    return sceneForHour(DateTime.now().hour);
  }

  try {
    final couple = await client.from('couples').select().eq('id', coupleId).single();
    final partnerId =
        couple['bear_id'] == uid ? couple['bunny_id'] : couple['bear_id'];
    if (partnerId == null) return sceneForHour(DateTime.now().hour);

    final profile = await client
        .from('profiles')
        .select('timezone')
        .eq('id', partnerId)
        .maybeSingle();
    final iana = profile?['timezone'] as String? ?? 'UTC';
    final location = tz.getLocation(iana);
    return sceneForHour(tz.TZDateTime.now(location).hour);
  } catch (_) {
    return sceneForHour(DateTime.now().hour);
  }
});