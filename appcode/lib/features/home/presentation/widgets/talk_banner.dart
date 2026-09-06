import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../connection/data/supabase_connection_repository.dart';
import '../providers/partner_status_provider.dart';

class TalkBanner extends ConsumerStatefulWidget {
  const TalkBanner({super.key});

  @override
  ConsumerState<TalkBanner> createState() => _TalkBannerState();
}

class _TalkBannerState extends ConsumerState<TalkBanner> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(partnerStatusProvider);
    final status = async.unwrapPrevious().asData?.value;
    final talk = status?.talk;
    if (talk == null) return const SizedBox.shrink();
    if (ref.watch(dismissedTalkIdsProvider).contains(talk.id)) {
      return const SizedBox.shrink();
    }

    // Recipient: unanswered ping from partner. Hide as soon as you reply.
    if (!talk.fromMe && talk.status == 'pending') {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _incomingLabel(talk.type),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AckChip(
                  label: 'Okay',
                  onTap: () => _ack(talk, 'yes'),
                ),
                _AckChip(
                  label: 'In a bit',
                  onTap: () => _ack(talk, 'soon'),
                ),
                _AckChip(
                  label: 'Tonight',
                  onTap: () => _ack(talk, 'tonight'),
                ),
                _AckChip(
                  label: 'Not now',
                  onTap: () => _ack(talk, 'not_now'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Sender: waiting until they answer. Do not show reply chips here.
    if (talk.fromMe && talk.status == 'pending') {
      return _Card(
        child: Text(
          'Waiting for them to reply',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      );
    }

    // Sender: they answered. Stays until the ping expires.
    if (talk.fromMe && talk.status != 'pending') {
      return _Card(
        child: Text(
          _outgoingLabel(talk.status),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _ack(TalkSignal talk, String status) async {
    HapticFeedback.lightImpact();
    ref.read(dismissedTalkIdsProvider.notifier).add(talk.id);
    try {
      await ref
          .read(connectionRepositoryProvider)
          .acknowledgeSignal(talk.id, status);
    } catch (e) {
      ref.read(dismissedTalkIdsProvider.notifier).remove(talk.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send that reply')),
        );
      }
    }
  }

  String _incomingLabel(String type) {
    return switch (type) {
      'call' => 'They want a call',
      'video_call' => 'They want video',
      _ => 'They want to text',
    };
  }

  String _outgoingLabel(String status) {
    return switch (status) {
      'yes' => 'They said okay',
      'soon' || 'give_me_10' => 'They’ll be there in a bit',
      'tonight' => 'They said tonight',
      'not_now' || 'cant_today' => 'They can’t right now',
      _ => 'They replied',
    };
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: child,
    );
  }
}

class _AckChip extends StatelessWidget {
  const _AckChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }
}