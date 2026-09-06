import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/affection_toast.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../voice_drop/presentation/voice_record_sheet.dart';
import '../../../avatar/domain/avatar_event.dart';
import '../../../avatar/presentation/couple_scene_view_model.dart';
import '../../../connection/data/supabase_connection_repository.dart';
import '../../../connection/domain/connection_repository.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../providers/partner_status_provider.dart';

class ConnectionActions extends ConsumerWidget {
  const ConnectionActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaired = ref.watch(activeCoupleIdProvider).value != null;
    return Row(
      children: [
        _DockItem(
          icon: AppIcons.love,
          label: 'Love',
          onTap: () => _requirePair(context, isPaired, () => showLoveSheet(context, ref)),
        ),
        _DockItem(
          icon: AppIcons.mood,
          label: 'Mood',
          onTap: () => _requirePair(context, isPaired, () => showMoodSheet(context, ref)),
        ),
        _DockItem(
          icon: AppIcons.talk,
          label: 'Talk',
          onTap: () => _requirePair(context, isPaired, () => showTalkSheet(context, ref)),
        ),
        _DockItem(
          icon: AppIcons.more,
          label: 'More',
          onTap: () => _requirePair(context, isPaired, () => _showMoreSheet(context, ref)),
        ),
      ],
    );
  }
}

void _requirePair(BuildContext context, bool isPaired, VoidCallback action) {
  if (!isPaired) {
    context.push(AppRoutes.couple);
    return;
  }
  action();
}

Future<bool> _run(
  WidgetRef ref,
  Future<void> Function(ConnectionRepository repo, String coupleId) action,
) async {
  final coupleId = ref.read(activeCoupleIdProvider).value;
  if (coupleId == null) return false;
  try {
    await action(ref.read(connectionRepositoryProvider), coupleId);
    return true;
  } catch (_) {
    return false;
  }
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

void showLoveSheet(BuildContext context, WidgetRef ref) {
  showAppSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send a little love',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _LoveTile(
              emoji: '😘',
              title: 'Kiss',
              onSend: () {
                Navigator.pop(context);
                _sendDrop(context, ref, type: 'Kiss', emoji: '😘');
              },
              onNote: () {
                Navigator.pop(context);
                _showNoteSheet(context, ref, type: 'Kiss', emoji: '😘');
              },
            ),
            _LoveTile(
              emoji: '🤗',
              title: 'Hug',
              onSend: () {
                Navigator.pop(context);
                _sendDrop(context, ref, type: 'Hug', emoji: '🤗');
              },
              onNote: () {
                Navigator.pop(context);
                _showNoteSheet(context, ref, type: 'Hug', emoji: '🤗');
              },
            ),
            _LoveTile(
              emoji: '🥺',
              title: 'Sorry',
              onSend: () {
                Navigator.pop(context);
                _sendDrop(context, ref, type: 'Sorry', emoji: '🥺');
              },
              onNote: () {
                Navigator.pop(context);
                _showNoteSheet(context, ref, type: 'Sorry', emoji: '🥺');
              },
            ),
          ],
        ),
      );
    },
  );
}

void showMoodSheet(BuildContext context, WidgetRef ref) {
  const moods = [
    _MoodChoice('Happy', '😊', Color(0xFFFBBF24)),
    _MoodChoice('Excited', '🤩', Color(0xFFF59E0B)),
    _MoodChoice('Tired', '😴', Color(0xFF94A3B8)),
    _MoodChoice('Sad', '😢', Color(0xFF60A5FA)),
    _MoodChoice('Angry', '😠', Color(0xFFF08080)),
    _MoodChoice('Devastated', '😭', Color(0xFF64748B)),
  ];
  final current = ref.read(partnerStatusProvider).value?.myMood;
  showAppSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you feeling?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'They’ll see this on you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < moods.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MoodTile(
                      mood: moods[i],
                      selected: current == moods[i].label,
                      onTap: () {
                        Navigator.pop(context);
                        if (current == moods[i].label) return;
                        HapticFeedback.lightImpact();
                        _run(
                          ref,
                          (repo, id) => repo.updateMood(id, moods[i].label),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MoodTile(
                      mood: moods[i + 1],
                      selected: current == moods[i + 1].label,
                      onTap: () {
                        Navigator.pop(context);
                        if (current == moods[i + 1].label) return;
                        HapticFeedback.lightImpact();
                        _run(
                          ref,
                          (repo, id) =>
                              repo.updateMood(id, moods[i + 1].label),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

void showTalkSheet(BuildContext context, WidgetRef ref) {
  final name = ref.read(partnerNameProvider).value ?? 'them';
  showAppSheet(
    context: context,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('I want to…', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(AppIcons.chat, color: AppColors.primary),
              title: const Text('Text'),
              subtitle: const Text('Ask them to text'),
              onTap: () {
                Navigator.pop(sheetContext);
                HapticFeedback.lightImpact();
                _run(ref, (repo, id) => repo.sendSignal(id, 'text'));
                showAffectionToast(context, emoji: '💬', label: 'We’ll let $name know');
              },
            ),
            ListTile(
              leading: Icon(AppIcons.call, color: AppColors.primary),
              title: const Text('Call'),
              subtitle: const Text('Ask them to call'),
              onTap: () {
                Navigator.pop(sheetContext);
                HapticFeedback.lightImpact();
                _run(ref, (repo, id) => repo.sendSignal(id, 'call'));
                showAffectionToast(context, emoji: '📞', label: 'We’ll let $name know');
              },
            ),
            ListTile(
              leading: Icon(AppIcons.video, color: AppColors.primary),
              title: const Text('Video'),
              subtitle: const Text('Ask them to video chat'),
              onTap: () {
                Navigator.pop(sheetContext);
                HapticFeedback.lightImpact();
                _run(ref, (repo, id) => repo.sendSignal(id, 'video_call'));
                showAffectionToast(context, emoji: '🎥', label: 'We’ll let $name know');
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showMoreSheet(BuildContext context, WidgetRef ref) {
  final scene = ref.read(coupleSceneProvider);
  final iAmLeft =
      ref.read(myRoleProvider).unwrapPrevious().value != CoupleRole.bunny;
  final isAsleep =
      (iAmLeft ? scene.left : scene.right) == AnimationState.sleeping;

  showAppSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('More', style: Theme.of(context).textTheme.titleLarge),
            ListTile(
              leading: Icon(
                isAsleep ? AppIcons.wake : AppIcons.sleep,
                color: AppColors.primary,
              ),
              title: Text(isAsleep ? 'Wake' : 'Sleep'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                final signal = isAsleep ? 'goodMorning' : 'goodNight';
                ref.read(coupleSceneProvider.notifier).setMyAsleep(!isAsleep);
                _run(ref, (repo, id) => repo.sendSignal(id, signal));
              },
            ),
            ListTile(
              leading: Icon(AppIcons.mic, color: AppColors.primary),
              title: const Text('Voice'),
              onTap: () {
                Navigator.pop(context);
                showVoiceRecordSheet(context, ref);
              },
            ),
            ListTile(
              leading: Icon(AppIcons.canvas, color: AppColors.primary),
              title: const Text('Canvas'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.canvas);
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
              Text('Add a note', style: Theme.of(context).textTheme.titleLarge),
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

class _LoveTile extends StatelessWidget {
  const _LoveTile({
    required this.emoji,
    required this.title,
    required this.onSend,
    required this.onNote,
  });

  final String emoji;
  final String title;
  final VoidCallback onSend;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(title),
      onTap: onSend,
      trailing: TextButton(
        onPressed: onNote,
        child: const Text('Add a note'),
      ),
    );
  }
}

class _MoodChoice {
  const _MoodChoice(this.label, this.emoji, this.tint);

  final String label;
  final String emoji;
  final Color tint;
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.onTap,
    this.selected = false,
  });

  final _MoodChoice mood;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.alphaBlend(
        mood.tint.withValues(alpha: selected ? 0.28 : 0.16),
        AppColors.elevated,
      ),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: mood.tint.withValues(alpha: selected ? 0.8 : 0.32),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 28, height: 1)),
              const SizedBox(height: 8),
              Text(
                mood.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  width: 36,
                  child: Icon(icon, color: AppColors.textPrimary, size: 26),
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