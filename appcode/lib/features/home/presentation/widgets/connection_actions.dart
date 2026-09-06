import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/affection_toast.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../voice_drop/presentation/voice_record_sheet.dart';
import '../../../avatar/presentation/avatar_view_model.dart';
import '../../../avatar/presentation/couple_scene_view_model.dart';
import '../../../connection/data/supabase_connection_repository.dart';
import '../../../connection/domain/connection_repository.dart';
import '../../../couple/data/supabase_couple_repository.dart';

class ConnectionActions extends ConsumerWidget {
  const ConnectionActions({super.key});

  Future<bool> _run(
    WidgetRef ref,
    Future<void> Function(ConnectionRepository repo, String coupleId) action,
  ) async {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId == null) return false;
    try {
      await action(ref.read(connectionRepositoryProvider), coupleId);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _requirePair(BuildContext context, bool isPaired, VoidCallback action) {
    if (!isPaired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pair with your partner first')),
      );
      return;
    }
    action();
  }

  Future<void> _sendDrop(
    BuildContext context,
    WidgetRef ref, {
    required String type,
    required String emoji,
    String? message,
  }) async {
    HapticFeedback.mediumImpact();
    final ok = await _run(
      ref,
      (repo, id) => repo.sendLoveDrop(id, type, message: message),
    );
    if (!context.mounted) return;
    if (ok) {
      ref.read(coupleSceneProvider.notifier).playDrop(type, fromMe: true);
      showAffectionToast(context, emoji: emoji, label: 'Sent');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send')),
      );
    }
  }

  void _showMoodSheet(BuildContext context, WidgetRef ref) {
    const moods = [
      ('Happy', '😊'),
      ('Sad', '😢'),
      ('Devastated', '😭'),
      ('Overwhelmed', '🤯'),
      ('Excited', '🤩'),
      ('Tired', '😴'),
    ];
    showAppSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How are you feeling?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final mood in moods)
                    _MoodChip(
                      label: mood.$1,
                      emoji: mood.$2,
                      onTap: () {
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                        _run(ref, (repo, id) => repo.updateMood(id, mood.$1));
                        ref
                            .read(coupleSceneProvider.notifier)
                            .setMyMood(mood.$1);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTalkSheet(BuildContext context, WidgetRef ref) {
    showAppSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('I want to…', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline,
                    color: AppColors.primary),
                title: const Text('Text'),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _run(ref, (repo, id) => repo.sendSignal(id, 'text'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_outlined, color: AppColors.primary),
                title: const Text('Call'),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _run(ref, (repo, id) => repo.sendSignal(id, 'call'));
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.videocam_outlined, color: AppColors.primary),
                title: const Text('Video'),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _run(ref, (repo, id) => repo.sendSignal(id, 'video_call'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoteSheet(
    BuildContext context,
    WidgetRef ref, {
    required String type,
    required String emoji,
  }) {
    final textController = TextEditingController();
    String customEmoji = emoji;
    String selected = type;

    showAppSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add a note',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    hintText: 'Optional message',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      final picked = await showAppSheet<String>(
                        context: context,
                        builder: (context) => SizedBox(
                          height: 260,
                          child: EmojiPicker(
                            onEmojiSelected: (category, value) {
                              Navigator.pop(context, value.emoji);
                            },
                          ),
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          customEmoji = picked;
                          selected = picked;
                        });
                      }
                    },
                    child: Text('Emoji $customEmoji'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final msg = textController.text.trim();
                    _sendDrop(
                      context,
                      ref,
                      type: selected,
                      emoji: customEmoji,
                      message: msg.isEmpty ? null : msg,
                    );
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          );
        });
      },
    ).whenComplete(textController.dispose);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(coupleSceneProvider);
    final iAmLeft =
        ref.watch(myRoleProvider).unwrapPrevious().value != CoupleRole.bunny;
    final isAsleep =
        (iAmLeft ? scene.left : scene.right) == AnimationState.sleeping;
    final isPaired = ref.watch(activeCoupleIdProvider).value != null;

    Widget row(List<Widget> children) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children.map((child) => Expanded(child: child)).toList(),
      );
    }

    return Column(
      children: [
        row([
          _ConnectIcon(
            emoji: '😘',
            tooltip: 'Kiss',
            label: 'Kiss',
            onTap: () => _requirePair(
              context,
              isPaired,
              () => _sendDrop(context, ref, type: 'Kiss', emoji: '😘'),
            ),
            onLongPress: () => _requirePair(
              context,
              isPaired,
              () => _showNoteSheet(context, ref, type: 'Kiss', emoji: '😘'),
            ),
          ),
          _ConnectIcon(
            emoji: '🤗',
            tooltip: 'Hug',
            label: 'Hug',
            onTap: () => _requirePair(
              context,
              isPaired,
              () => _sendDrop(context, ref, type: 'Hug', emoji: '🤗'),
            ),
            onLongPress: () => _requirePair(
              context,
              isPaired,
              () => _showNoteSheet(context, ref, type: 'Hug', emoji: '🤗'),
            ),
          ),
          _ConnectIcon(
            emoji: '🥺',
            tooltip: 'Sorry',
            label: 'Sorry',
            onTap: () => _requirePair(
              context,
              isPaired,
              () => _sendDrop(context, ref, type: 'Sorry', emoji: '🥺'),
            ),
          ),
          _ConnectIcon(
            icon: Icons.mood_outlined,
            tooltip: 'Mood',
            label: 'Mood',
            onTap: () => _requirePair(
              context,
              isPaired,
              () => _showMoodSheet(context, ref),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        row([
          _ConnectIcon(
            icon: Icons.call_outlined,
            tooltip: 'Talk',
            label: 'Talk',
            onTap: () => _requirePair(
              context,
              isPaired,
              () => _showTalkSheet(context, ref),
            ),
          ),
          _ConnectIcon(
            icon: isAsleep ? Icons.wb_sunny_outlined : Icons.bedtime_outlined,
            tooltip: isAsleep ? 'Wake' : 'Sleep',
            label: isAsleep ? 'Wake' : 'Sleep',
            onTap: () => _requirePair(context, isPaired, () {
              HapticFeedback.lightImpact();
              final signal = isAsleep ? 'goodMorning' : 'goodNight';
              ref.read(coupleSceneProvider.notifier).setMyAsleep(!isAsleep);
              _run(ref, (repo, id) => repo.sendSignal(id, signal));
            }),
          ),
          _ConnectIcon(
            icon: Icons.mic_none,
            tooltip: 'Voice',
            label: 'Voice',
            onTap: () => _requirePair(
              context,
              isPaired,
              () => showVoiceRecordSheet(context, ref),
            ),
          ),
          _ConnectIcon(
            icon: Icons.brush_outlined,
            tooltip: 'Canvas',
            label: 'Canvas',
            onTap: () => _requirePair(
              context,
              isPaired,
              () => context.push(AppRoutes.canvas),
            ),
          ),
        ]),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectIcon extends StatelessWidget {
  const _ConnectIcon({
    this.icon,
    this.emoji,
    required this.tooltip,
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  final IconData? icon;
  final String? emoji;
  final String tooltip;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.none,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  child: Center(
                    child: emoji != null
                        ? Text(
                            emoji!,
                            style: const TextStyle(fontSize: 28, height: 1.0),
                          )
                        : Icon(icon, color: AppColors.textPrimary, size: 26),
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}