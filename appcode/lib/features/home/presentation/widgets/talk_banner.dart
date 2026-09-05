import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../connection/data/supabase_connection_repository.dart';
import '../providers/partner_status_provider.dart';

class TalkBanner extends ConsumerWidget {
  const TalkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(partnerStatusProvider);
    final status = async.unwrapPrevious().asData?.value;
    final talk = status?.talk;
    if (talk == null) return const SizedBox.shrink();

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
                  label: '10 min',
                  onTap: () => _ack(context, ref, talk, 'give_me_10'),
                ),
                _AckChip(
                  label: 'Tonight',
                  onTap: () => _ack(context, ref, talk, 'tonight'),
                ),
                _AckChip(
                  label: 'Thinking of you',
                  onTap: () => _ack(context, ref, talk, 'cant_today'),
                ),
              ],
            ),
          ],
        ),
      );
    }

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

  Future<void> _ack(
    BuildContext context,
    WidgetRef ref,
    TalkSignal talk,
    String status,
  ) async {
    HapticFeedback.lightImpact();
    try {
      await ref
          .read(connectionRepositoryProvider)
          .acknowledgeSignal(talk.id, status);
      ref.invalidate(partnerStatusProvider);
    } catch (e) {
      if (context.mounted) {
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
      'give_me_10' => 'They said give them 10 minutes',
      'tonight' => 'They said tonight',
      'cant_today' => 'They’re thinking of you',
      _ => 'They saw it',
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