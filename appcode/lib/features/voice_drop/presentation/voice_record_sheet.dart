import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/affection_toast.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_voice_repository.dart';

Future<void> showVoiceRecordSheet(BuildContext context, WidgetRef ref) {
  return showAppSheet(
    context: context,
    builder: (context) => const _VoiceRecordBody(),
  );
}

class _VoiceRecordBody extends ConsumerStatefulWidget {
  const _VoiceRecordBody();

  @override
  ConsumerState<_VoiceRecordBody> createState() => _VoiceRecordBodyState();
}

class _VoiceRecordBodyState extends ConsumerState<_VoiceRecordBody> {
  final _recorder = AudioRecorder();
  Timer? _ticker;
  int _elapsedMs = 0;
  bool _recording = false;
  String? _path;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/voice_drop.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _path!,
    );
    HapticFeedback.mediumImpact();
    setState(() {
      _recording = true;
      _elapsedMs = 0;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (t) async {
      final next = _elapsedMs + 100;
      if (next >= 15000) {
        t.cancel();
        await _stop(send: true);
        return;
      }
      setState(() => _elapsedMs = next);
    });
  }

  Future<void> _stop({required bool send}) async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (!send || path == null) return;
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId == null) return;
    final duration = _elapsedMs.clamp(1, 15000);
    await ref.read(voiceRepositoryProvider).send(
          coupleId: coupleId,
          file: File(path),
          durationMs: duration,
        );
    if (mounted) {
      Navigator.pop(context);
      showAffectionToast(context, emoji: '🎙️', label: 'Voice sent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_elapsedMs / 1000).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Voice drop', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Hold up to 15 seconds. Gone in 24 hours.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text(_recording ? '${seconds}s' : '0.0s',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          GestureDetector(
            onLongPressStart: (_) => _start(),
            onLongPressEnd: (_) => _stop(send: true),
            child: CircleAvatar(
              radius: 36,
              backgroundColor:
                  _recording ? AppColors.affection : AppColors.primary,
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _recording ? 'Release to send' : 'Hold to record',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}