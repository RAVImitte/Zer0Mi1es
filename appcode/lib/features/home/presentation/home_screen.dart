import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/partner_scene.dart';
import '../../../core/widgets/affection_toast.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../connection/domain/love_drop_message.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../../notifications/data/push_notification_service.dart';
import 'providers/home_providers.dart';
import 'providers/partner_scene_provider.dart';
import 'widgets/connection_actions.dart';
import 'widgets/daily_status.dart';
import 'widgets/partner_presence.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/talk_banner.dart';
import '../../voice_drop/presentation/voice_play_chip.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(pushNotificationServiceProvider).initialize();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        await ref.read(authRepositoryProvider).syncTimezone(name);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCoupleId =
        ref.watch(activeCoupleIdProvider.select((v) => v.value));
    final partnerName = ref.watch(partnerNameProvider).value ?? 'Partner';
    final isPaired = activeCoupleId != null;
    final scene = ref.watch(partnerSceneProvider).value ?? PartnerScene.day;

    if (activeCoupleId != null) {
      ref.listen<AsyncValue<LoveDropMessage>>(
        loveDropsProvider(activeCoupleId),
        (previous, next) {
          if (next.hasValue && next.value != null && mounted) {
            final drop = next.value!;
            showAffectionToast(
              context,
              emoji: _emojiForDrop(drop.type),
              label: drop.message?.isNotEmpty == true
                  ? drop.message!
                  : '$partnerName sent a ${drop.type}',
            );
          }
        },
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sceneWash(scene),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPaired ? partnerName : 'Zero Miles',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (isPaired)
                            Text(
                              sceneLabel(scene),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: () => showSettingsSheet(context, ref),
                      icon: const Icon(Icons.settings_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              const TalkBanner(),
              const VoicePlayChip(),
              const Expanded(flex: 5, child: PartnerPresence()),
              const SizedBox(height: 8),
              const DailyStatus(),
              const SizedBox(height: 20),
              const ConnectionActions(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _emojiForDrop(String type) {
    switch (type) {
      case 'Kiss':
        return '💋';
      case 'Hug':
        return '🤗';
      case 'Sorry':
        return '🥺';
      default:
        return type.length <= 2 ? type : '💖';
    }
  }
}