import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
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
  final _player = AudioPlayer();
  Timer? _ticker;
  int _elapsedMs = 0;
  int _pressGen = 0;
  bool _held = false;
  bool _recording = false;
  bool _denied = false;
  String? _path;

  @override
  void dispose() {
    _ticker?.cancel();
    _held = false;
    _pressGen++;
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    _held = true;
    final gen = ++_pressGen;
    _start(gen);
  }

  void _onHoldEnd({required bool keep}) {
    _held = false;
    _pressGen++;
    if (_recording) {
      _stop(keep: keep);
    }
  }

  Future<void> _start(int gen) async {
    final hasPermission = await _recorder.hasPermission();
    if (!mounted || gen != _pressGen) return;
    if (!hasPermission) {
      setState(() => _denied = true);
      return;
    }
    // Permission dialog stole the gesture — wait for a fresh hold.
    if (!_held) {
      setState(() => _denied = false);
      return;
    }
    final dir = await getTemporaryDirectory();
    if (!mounted || gen != _pressGen || !_held) return;
    _path = '${dir.path}/voice_drop.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _path!,
    );
    if (!mounted || gen != _pressGen || !_held) {
      if (await _recorder.isRecording()) await _recorder.stop();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _recording = true;
      _elapsedMs = 0;
      _denied = false;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (t) async {
      if (!mounted || gen != _pressGen) {
        t.cancel();
        return;
      }
      final next = _elapsedMs + 100;
      if (next >= 15000) {
        t.cancel();
        await _stop(keep: true);
        return;
      }
      setState(() => _elapsedMs = next);
    });
  }

  Future<void> _stop({required bool keep}) async {
    _ticker?.cancel();
    String? path;
    if (await _recorder.isRecording()) {
      path = await _recorder.stop();
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      if (keep) _path = path ?? _path;
      if (!keep) _path = null;
    });
  }

  Future<void> _send() async {
    final path = _path;
    if (path == null) return;
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
    final progress = (_elapsedMs / 15000).clamp(0.0, 1.0);

    if (_denied) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Microphone is off',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Enable it in Settings so you can leave a voice.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse(
                Platform.isIOS ? 'app-settings:' : 'app-settings:',
              )),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    if (_path != null && !_recording) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Preview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${seconds}s · gone in 24 hours',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            IconButton(
              iconSize: 48,
              onPressed: () async {
                await _player.setFilePath(_path!);
                await _player.play();
              },
              icon: Icon(AppIcons.play, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _send, child: const Text('Send')),
            TextButton(
              onPressed: () => setState(() {
                _path = null;
                _elapsedMs = 0;
              }),
              child: const Text('Re-record'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Voice drop', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Hold up to 15 seconds. Release to preview. Gone in 24 hours.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _recording ? progress : 0,
                  color: AppColors.affection,
                  backgroundColor: AppColors.elevated,
                  strokeWidth: 4,
                ),
                Listener(
                  onPointerUp: (_) => _onHoldEnd(keep: true),
                  onPointerCancel: (_) => _onHoldEnd(keep: false),
                  child: GestureDetector(
                    onLongPressStart: (_) => _onHoldStart(),
                    onLongPressEnd: (_) => _onHoldEnd(keep: true),
                    onLongPressCancel: () => _onHoldEnd(keep: false),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          _recording ? AppColors.affection : AppColors.primary,
                      child: Icon(AppIcons.mic, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _recording ? 'Release to preview' : 'Hold to record',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (_recording)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${seconds}s',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
        ],
      ),
    );
  }
}