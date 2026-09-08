import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/partner_scene.dart';
import '../../../couple/data/supabase_couple_repository.dart';

final clockHourProvider = StreamProvider<int>((ref) async* {
  yield DateTime.now().hour;
  yield* Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now().hour,
  );
});

final mySceneProvider = Provider<PartnerScene>((ref) {
  final hour = ref.watch(clockHourProvider).value ?? DateTime.now().hour;
  return sceneForHour(hour);
});

final partnerSceneProvider =
    FutureProvider.autoDispose<PartnerScene>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  final fallbackHour =
      ref.watch(clockHourProvider).value ?? DateTime.now().hour;
  if (uid == null || coupleId == null) {
    return sceneForHour(fallbackHour);
  }

  try {
    final couple =
        await client.from('couples').select().eq('id', coupleId).single();
    final partnerId =
        couple['bear_id'] == uid ? couple['bunny_id'] : couple['bear_id'];
    if (partnerId == null) return sceneForHour(fallbackHour);

    final profile = await client
        .from('profiles')
        .select('timezone')
        .eq('id', partnerId)
        .maybeSingle();
    final iana = profile?['timezone'] as String? ?? 'UTC';
    final location = tz.getLocation(iana);
    return sceneForHour(tz.TZDateTime.now(location).hour);
  } catch (_) {
    return sceneForHour(fallbackHour);
  }
});