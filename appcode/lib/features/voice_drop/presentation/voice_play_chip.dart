import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_voice_repository.dart';
import '../domain/voice_drop.dart';

class VoicePlayChip extends ConsumerWidget {
  const VoicePlayChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleId = ref.watch(activeCoupleIdProvider).value;
    if (coupleId == null) return const SizedBox.shrink();
    final drop = ref.watch(_partnerVoiceProvider(coupleId)).value;
    if (drop == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PlayPill(drop: drop),
    );
  }
}

final _partnerVoiceProvider =
    StreamProvider.autoDispose.family<VoiceDrop?, String>((ref, coupleId) {
  return ref.watch(voiceRepositoryProvider).watchPartnerDrop(coupleId);
});

class _PlayPill extends ConsumerStatefulWidget {
  const _PlayPill({required this.drop});

  final VoiceDrop drop;

  @override
  ConsumerState<_PlayPill> createState() => _PlayPillState();
}

class _PlayPillState extends ConsumerState<_PlayPill> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    final url =
        await ref.read(voiceRepositoryProvider).signedUrl(widget.drop.storagePath);
    await _player.setUrl(url);
    setState(() => _playing = true);
    await _player.play();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _playing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_playing ? AppIcons.stop : AppIcons.play,
                  color: AppColors.affection, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _label(context, ref),
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context, WidgetRef ref) {
    final name = ref.watch(partnerNameProvider).value ?? 'They';
    final first = name.trim().split(RegExp(r'\s+')).first;
    final secs = (widget.drop.durationMs / 1000).ceil();
    final left = widget.drop.expiresAt.difference(DateTime.now());
    final hours = left.inHours.clamp(0, 24);
    return '$first left a voice · 0:${secs.toString().padLeft(2, '0')} · ${hours}h left';
  }
}