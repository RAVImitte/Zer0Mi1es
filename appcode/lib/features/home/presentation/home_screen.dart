import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/partner_scene.dart';
import '../../../core/widgets/affection_toast.dart';
import '../../../core/widgets/app_offline_banner.dart';
import '../../../core/widgets/living_window.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../connection/domain/love_drop_message.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../../notifications/data/push_notification_service.dart';
import '../../avatar/presentation/couple_scene_view_model.dart';
import '../data/home_widget_sync.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _coach = false;
  int _coachStep = 0;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(pushNotificationServiceProvider).initialize();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        await ref.read(authRepositoryProvider).syncTimezone(name);
      } catch (_) {}
      await syncHomeWidget(ref);
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('home_coach_v2') ?? false) && mounted) {
        setState(() => _coach = true);
      }
    });
  }

  @override
  void dispose() {
    cancelHomeWidgetSync();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(windowMotionPausedProvider.notifier).setPaused(
          state == AppLifecycleState.paused ||
              state == AppLifecycleState.inactive,
        );
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      cancelHomeWidgetSync();
      syncHomeWidget(ref);
    }
  }

  Future<void> _dismissCoach() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_coach_v2', true);
    if (mounted) setState(() => _coach = false);
  }

  @override
  Widget build(BuildContext context) {
    bindHomeWidgetListeners(ref);
    final activeCoupleId =
        ref.watch(activeCoupleIdProvider.select((v) => v.value));
    final partnerName = ref.watch(partnerNameProvider).value ?? 'Partner';
    final myScene = ref.watch(mySceneProvider);

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

    final hasOutfit = ref.watch(outfitCompletedProvider).value ?? false;
    final hasPhoto = ref.watch(photoCompletedProvider).value ?? false;
    final hasQuestion = ref.watch(questionCompletedProvider).value ?? false;
    if (!_celebrated && hasOutfit && hasPhoto && hasQuestion) {
      _celebrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(coupleSceneProvider.notifier).playDrop('Hug', fromMe: true);
        showAffectionToast(context, emoji: '✨', label: 'That’s all of today');
      });
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sceneWash(myScene),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => showSettingsSheet(context, ref),
                          icon: Icon(AppIcons.settings,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const AppOfflineBanner(),
                    const TalkBanner(),
                    const VoicePlayChip(),
                    const Expanded(
                      flex: 5,
                      child: ClipRect(child: PartnerPresence()),
                    ),
                    const SizedBox(height: 8),
                    const DailyStatus(),
                    const SizedBox(height: 12),
                    const ConnectionActions(),
                  ],
                ),
              ),
              if (_coach) _buildCoach(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoach(BuildContext context) {
    const steps = [
      'Two windows. Their time of day lives in theirs — you feel the distance, you don’t read it.',
      'Today’s three rituals sit under the sill. Outfit, photo, question.',
      'Love is the first dock item. Kiss, hug, or sorry — with a note if you want.',
    ];
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  steps[_coachStep],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_coachStep < steps.length - 1) {
                      setState(() => _coachStep++);
                    } else {
                      _dismissCoach();
                    }
                  },
                  child: Text(_coachStep < steps.length - 1 ? 'Next' : 'Got it'),
                ),
                TextButton(
                  onPressed: _dismissCoach,
                  child: const Text('Skip'),
                ),
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