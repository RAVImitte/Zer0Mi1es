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
import 'love_note_cloud.dart';
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
  } catch (e, st) {
    debugPrint('connection action failed: $e\n$st');
    return false;
  }
}

Future<void> _sendDrop(
  BuildContext hostContext,
  WidgetRef ref, {
  required String type,
  required String emoji,
  String? message,
}) async {
  HapticFeedback.mediumImpact();
  final messenger =
      hostContext.mounted ? ScaffoldMessenger.maybeOf(hostContext) : null;
  final ok = await _run(
    ref,
    (repo, id) => repo.sendLoveDrop(
      id,
      type,
      message: message,
      emoji: emoji,
    ),
  );
  if (ok) {
    ref.read(coupleSceneProvider.notifier).playDrop(
          type,
          fromMe: true,
          message: message,
          emoji: emoji,
        );
    if (type != 'Note' && hostContext.mounted) {
      showAffectionToast(hostContext, emoji: emoji, label: 'Sent');
    }
  } else {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Could not send')),
    );
  }
}

void showLoveSheet(BuildContext context, WidgetRef ref) {
  showAppSheet(
    context: context,
    title: 'Send a little love',
    subtitle: 'They’ll feel it on their side.',
    builder: (sheetContext) {
      Widget card(String emoji, String title, VoidCallback onTap) {
        return Expanded(
          child: _EmojiCard(emoji: emoji, title: title, onTap: onTap),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Row(
              children: [
                card('😘', 'Kiss', () {
                  Navigator.pop(sheetContext);
                  _sendDrop(context, ref, type: 'Kiss', emoji: '😘');
                }),
                const SizedBox(width: 10),
                card('🤗', 'Hug', () {
                  Navigator.pop(sheetContext);
                  _sendDrop(context, ref, type: 'Hug', emoji: '🤗');
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                card('🥺', 'Sorry', () {
                  Navigator.pop(sheetContext);
                  _sendDrop(context, ref, type: 'Sorry', emoji: '🥺');
                }),
                const SizedBox(width: 10),
                card('💌', 'Note', () {
                  Navigator.pop(sheetContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) _showNoteSheet(context, ref);
                  });
                }),
              ],
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
    title: 'How are you feeling?',
    subtitle: 'They’ll see this on you.',
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < moods.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MoodTile(
                      mood: moods[i],
                      selected: current == moods[i].label,
                      onTap: () {
                        Navigator.pop(sheetContext);
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
                        Navigator.pop(sheetContext);
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
    title: 'I want to…',
    subtitle: 'We’ll ping $name to meet you there.',
    builder: (sheetContext) {
      void send(String type, String emoji) {
        Navigator.pop(sheetContext);
        HapticFeedback.lightImpact();
        _run(ref, (repo, id) => repo.sendSignal(id, type));
        showAffectionToast(context, emoji: emoji, label: 'We’ll let $name know');
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            _LineCard(
              icon: AppIcons.chat,
              title: 'Text',
              caption: 'Ask them to message you',
              onTap: () => send('text', '💬'),
            ),
            const SizedBox(height: 10),
            _LineCard(
              icon: AppIcons.call,
              title: 'Call',
              caption: 'Ask them to ring you',
              onTap: () => send('call', '📞'),
            ),
            const SizedBox(height: 10),
            _LineCard(
              icon: AppIcons.video,
              title: 'Video',
              caption: 'Ask them to video chat',
              onTap: () => send('video_call', '🎥'),
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
    title: 'More',
    subtitle: 'Quiet extras for the two of you.',
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            _LineCard(
              icon: isAsleep ? AppIcons.wake : AppIcons.sleep,
              title: isAsleep ? 'Wake' : 'Sleep',
              caption: isAsleep
                  ? 'Let them know you’re up'
                  : 'Dim your window for the night',
              onTap: () {
                Navigator.pop(sheetContext);
                HapticFeedback.lightImpact();
                final signal = isAsleep ? 'goodMorning' : 'goodNight';
                ref.read(coupleSceneProvider.notifier).setMyAsleep(!isAsleep);
                _run(ref, (repo, id) => repo.sendSignal(id, signal));
              },
            ),
            const SizedBox(height: 10),
            _LineCard(
              icon: AppIcons.mic,
              title: 'Voice',
              caption: 'Leave a short voice drop',
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) showVoiceRecordSheet(context, ref);
                });
              },
            ),
            const SizedBox(height: 10),
            _LineCard(
              icon: AppIcons.canvas,
              title: 'Canvas',
              caption: 'Doodle something together',
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.canvas);
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showNoteSheet(BuildContext hostContext, WidgetRef ref) {
  final textController = TextEditingController();
  var emoji = '💌';
  const choices = [
    '💌',
    '❤️',
    '🥰',
    '😘',
    '🌙',
    '⭐',
    '🌸',
    '🤗',
    '🥺',
    '✨',
    '💭',
    '🐻',
  ];

  showAppSheet(
    context: hostContext,
    isScrollControlled: true,
    title: 'Note',
    subtitle: 'They’ll see this on you.',
    builder: (sheetContext) {
      return StatefulBuilder(builder: (_, setState) {
        final canSend = textController.text.trim().isNotEmpty;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40, height: 1)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final choice in choices)
                    GestureDetector(
                      onTap: () => setState(() => emoji = choice),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: choice == emoji
                              ? AppColors.primary.withValues(alpha: 0.22)
                              : AppColors.elevated,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: choice == emoji
                                ? AppColors.primary
                                : AppColors.hairline,
                          ),
                        ),
                        child: Text(choice, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLength: kLoveNoteMaxChars,
                minLines: 2,
                maxLines: kLoveNoteMaxLines,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'A short thought for the cloud',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: canSend
                    ? () {
                        final msg = textController.text.trim();
                        final picked = emoji;
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(sheetContext);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _sendDrop(
                            hostContext,
                            ref,
                            type: 'Note',
                            emoji: picked,
                            message: msg,
                          );
                        });
                      }
                    : null,
                child: const Text('Send'),
              ),
            ],
          ),
        );
      });
    },
  ).whenComplete(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      textController.dispose();
    });
  });
}

class _EmojiCard extends StatelessWidget {
  const _EmojiCard({
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.elevated,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34, height: 1)),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.elevated,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        mood.tint.withValues(alpha: selected ? 0.32 : 0.14),
        AppColors.elevated,
      ),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: mood.tint.withValues(alpha: selected ? 0.9 : 0.28),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: mood.tint.withValues(alpha: 0.28),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 28, height: 1)),
              const SizedBox(height: 6),
              Text(
                mood.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
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