import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radii.dart';
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
import 'widgets/home_coach_overlay.dart';
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
  final _presenceKey = GlobalKey();
  final _ritualsKey = GlobalKey();
  final _dockKey = GlobalKey();

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
      if (!(prefs.getBool('home_coach_v4') ?? false) && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 480));
        if (mounted) setState(() => _coach = true);
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
    if (state == AppLifecycleState.resumed) {
      ref.read(coupleSceneProvider.notifier).refreshNotes();
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      cancelHomeWidgetSync();
      syncHomeWidget(ref);
    }
  }

  Future<void> _dismissCoach() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_coach_v4', true);
    if (mounted) setState(() => _coach = false);
  }

  void _showCoach() {
    setState(() {
      _coachStep = 0;
      _coach = true;
    });
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
              emoji: _emojiForDrop(drop.type, emoji: drop.emoji),
              label: drop.type == 'Note'
                  ? '$partnerName sent a note'
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Zero Miles',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 22,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Settings',
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final replay = await showSettingsSheet(context, ref);
                            if (replay && mounted) _showCoach();
                          },
                          icon: Icon(AppIcons.settings,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const AppOfflineBanner(),
                    const TalkBanner(),
                    if (activeCoupleId != null)
                      const SizedBox(
                        height: kHomeVoiceLogSlot,
                        child: VoicePlayChip(),
                      ),
                    Expanded(
                      flex: 5,
                      child: PartnerPresence(seatsKey: _presenceKey),
                    ),
                    const SizedBox(height: 8),
                    DailyStatus(key: _ritualsKey),
                    const SizedBox(height: 12),
                    ConnectionActions(key: _dockKey),
                  ],
                ),
              ),
            ),
            if (_coach)
              HomeCoachOverlay(
                step: _coachStep,
                steps: [
                  CoachStep(
                    key: _presenceKey,
                    radius: AppRadii.window,
                    padding: 6,
                    title: 'Your room',
                    body:
                        'Two of you, side by side. Each window is their time of day.',
                  ),
                  CoachStep(
                    key: _ritualsKey,
                    radius: AppRadii.control,
                    padding: 10,
                    title: 'Today',
                    body:
                        'Outfit, a photo, one question. Small rituals that keep you in the same day.',
                  ),
                  CoachStep(
                    key: _dockKey,
                    radius: 18,
                    padding: 8,
                    title: 'Reach them',
                    body:
                        'Love, mood, talk, and more. Start with Love — a kiss, a hug, a sorry, or a note.',
                  ),
                ],
                onNext: () {
                  if (_coachStep < 2) {
                    setState(() => _coachStep++);
                  } else {
                    _dismissCoach();
                  }
                },
                onSkip: _dismissCoach,
              ),
          ],
        ),
      ),
    );
  }

  String _emojiForDrop(String type, {String? emoji}) {
    if (emoji != null && emoji.isNotEmpty) return emoji;
    switch (type) {
      case 'Kiss':
        return '💋';
      case 'Hug':
        return '🤗';
      case 'Sorry':
        return '🥺';
      case 'Note':
        return '💌';
      default:
        return type.length <= 2 ? type : '💖';
    }
  }
}