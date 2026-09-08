import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_voice_repository.dart';
import '../domain/voice_drop.dart';

const _kVoiceStack = 3;

class VoicePlayChip extends ConsumerStatefulWidget {
  const VoicePlayChip({super.key});

  @override
  ConsumerState<VoicePlayChip> createState() => _VoicePlayChipState();
}

class _VoicePlayChipState extends ConsumerState<VoicePlayChip> {
  final _hidden = <String>{};

  @override
  void initState() {
    super.initState();
    _loadHidden();
  }

  Future<void> _loadHidden() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(CacheKeys.dismissedVoiceIds) ?? const [];
    if (!mounted) return;
    setState(() => _hidden.addAll(ids));
  }

  Future<void> _dismiss(String id) async {
    HapticFeedback.lightImpact();
    setState(() => _hidden.add(id));
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(CacheKeys.dismissedVoiceIds) ?? [];
    if (!ids.contains(id)) ids.add(id);
    if (ids.length > 40) ids.removeRange(0, ids.length - 40);
    await prefs.setStringList(CacheKeys.dismissedVoiceIds, ids);
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = ref.watch(activeCoupleIdProvider).value;
    if (coupleId == null) return const SizedBox.shrink();
    final drops = ref.watch(_partnerVoicesProvider(coupleId)).value ?? const [];
    final visible =
        drops.where((d) => !_hidden.contains(d.id)).take(_kVoiceStack).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Dismissible(
              key: ValueKey(visible[i].id),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => _dismiss(visible[i].id),
              child: _PlayPill(drop: visible[i]),
            ),
          ],
        ],
      ),
    );
  }
}

final _partnerVoicesProvider =
    StreamProvider.autoDispose.family<List<VoiceDrop>, String>((ref, coupleId) {
  return ref.watch(voiceRepositoryProvider).watchPartnerDrops(coupleId);
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
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _playing = false);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final url =
        await ref.read(voiceRepositoryProvider).signedUrl(widget.drop.storagePath);
    await _player.setUrl(url);
    if (!mounted) return;
    setState(() => _playing = true);
    await _player.play();
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
            children: [
              Icon(_playing ? AppIcons.stop : AppIcons.play,
                  color: AppColors.affection, size: 20),
              const SizedBox(width: 8),
              Expanded(
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
