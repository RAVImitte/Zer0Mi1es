import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../connection/data/supabase_connection_repository.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../providers/partner_status_provider.dart';

class TalkBanner extends ConsumerWidget {
  const TalkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(partnerStatusProvider);
    final status = async.unwrapPrevious().asData?.value;
    final talk = status?.talk;
    if (talk == null) return const SizedBox.shrink();
    if (ref.watch(dismissedTalkIdsProvider).contains(talk.id)) {
      return const SizedBox.shrink();
    }

    final name = ref.watch(partnerNameProvider).value ?? 'They';

    if (!talk.fromMe && talk.status == 'pending') {
      return _Banner(
        icon: _icon(talk.type),
        title: _incomingTitle(name, talk.type),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () async {
                await _ack(context, ref, talk, 'yes');
                if (context.mounted) {
                  await _followThrough(context, talk.type);
                }
              },
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 36),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Okay'),
            ),
            IconButton(
              tooltip: 'More options',
              visualDensity: VisualDensity.compact,
              onPressed: () => _defer(context, ref, talk),
              icon: Icon(AppIcons.more, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (talk.fromMe && talk.status == 'pending') {
      return _Banner(
        icon: _icon(talk.type),
        title: 'Waiting for $name',
        trailing: IconButton(
          tooltip: 'Hide for now',
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              ref.read(dismissedTalkIdsProvider.notifier).add(talk.id),
          icon: Icon(AppIcons.close, color: AppColors.textSecondary, size: 20),
        ),
      );
    }

    if (talk.fromMe && talk.status != 'pending') {
      return _Banner(
        icon: AppIcons.check,
        title: _outgoingTitle(name, talk.status),
        trailing: IconButton(
          tooltip: 'Hide for now',
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              ref.read(dismissedTalkIdsProvider.notifier).add(talk.id),
          icon: Icon(AppIcons.close, color: AppColors.textSecondary, size: 20),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _defer(BuildContext context, WidgetRef ref, TalkSignal talk) {
    return showAppSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('When can you?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('In a bit'),
                subtitle: const Text('They’ll see you’ll be free soon'),
                onTap: () {
                  Navigator.pop(context);
                  _ack(context, ref, talk, 'soon');
                },
              ),
              ListTile(
                title: const Text('Tonight'),
                subtitle: const Text('Until 6am their time'),
                onTap: () {
                  Navigator.pop(context);
                  _ack(context, ref, talk, 'tonight');
                },
              ),
              ListTile(
                title: const Text('Not now'),
                onTap: () {
                  Navigator.pop(context);
                  _ack(context, ref, talk, 'not_now');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _ack(
    BuildContext context,
    WidgetRef ref,
    TalkSignal talk,
    String status,
  ) async {
    HapticFeedback.lightImpact();
    ref.read(dismissedTalkIdsProvider.notifier).add(talk.id);
    try {
      await ref
          .read(connectionRepositoryProvider)
          .acknowledgeSignal(talk.id, status);
    } catch (_) {
      ref.read(dismissedTalkIdsProvider.notifier).remove(talk.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send that reply')),
        );
      }
    }
  }

  Future<void> _followThrough(BuildContext context, String type) async {
    await showAppSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Open a real channel',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(AppIcons.chat, color: AppColors.primary),
                title: const Text('Messages'),
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse('sms:'));
                },
              ),
              if (type != 'text')
                ListTile(
                  leading: Icon(AppIcons.call, color: AppColors.primary),
                  title: const Text('Phone'),
                  onTap: () async {
                    Navigator.pop(context);
                    await launchUrl(Uri.parse('tel:'));
                  },
                ),
              if (type == 'video_call')
                ListTile(
                  leading: Icon(AppIcons.video, color: AppColors.primary),
                  title: Text(Platform.isIOS ? 'FaceTime' : 'Video app'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (Platform.isIOS) {
                      await launchUrl(Uri.parse('facetime:'));
                    }
                  },
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Not now'),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _icon(String type) {
    return switch (type) {
      'call' => AppIcons.call,
      'video_call' => AppIcons.video,
      _ => AppIcons.chat,
    };
  }

  String _incomingTitle(String name, String type) {
    return switch (type) {
      'call' => '$name wants to call',
      'video_call' => '$name wants to video chat',
      _ => '$name wants to text',
    };
  }

  String _outgoingTitle(String name, String status) {
    return switch (status) {
      'yes' => '$name said okay',
      'soon' || 'give_me_10' => '$name will be there in a bit',
      'tonight' => '$name said tonight',
      'not_now' || 'cant_today' => '$name can’t right now',
      _ => '$name replied',
    };
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
