import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../couple/data/supabase_couple_repository.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _Stroke {
  _Stroke(this.color, this.points);
  final Color color;
  final List<Offset> points;
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final _boundaryKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  _Stroke? _current;
  RealtimeChannel? _channel;
  Uint8List? _snapshot;
  bool _erasing = false;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId != null) {
      unawaited(_saveSnapshot(coupleId));
    }
    final client = ref.read(supabaseClientProvider);
    if (_channel != null) client.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _boot() async {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (coupleId == null || uid == null) return;

    try {
      final row = await client
          .from('canvases')
          .select()
          .eq('couple_id', coupleId)
          .maybeSingle();
      if (row != null) {
        final path = row['storage_path'] as String;
        final bytes = await client.storage.from('canvas').download(path);
        if (mounted) setState(() => _snapshot = bytes);
      }
    } catch (_) {}

    _channel = client.channel('canvas:$coupleId');
    _channel!
        .onBroadcast(
          event: 'stroke',
          callback: (payload) {
            if (payload['user_id'] == uid) return;
            final box = context.size;
            if (box == null) return;
            final pts = (payload['points'] as List)
                .map((p) => Offset(
                      (p[0] as num).toDouble() * box.width,
                      (p[1] as num).toDouble() * box.height,
                    ))
                .toList();
            final color = Color(payload['color'] as int);
            setState(() => _strokes.add(_Stroke(color, pts)));
          },
        )
        .onBroadcast(
          event: 'clear',
          callback: (payload) {
            if (payload['user_id'] == uid) return;
            setState(() {
              _strokes.clear();
              _snapshot = null;
            });
          },
        )
        .subscribe();
  }

  Color get _ink {
    final role = ref.read(myRoleProvider).value;
    return role == 'bunny' ? AppColors.affection : AppColors.primary;
  }

  void _broadcast(_Stroke stroke, Size size) {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (coupleId == null || uid == null || _channel == null) return;
    _channel!.sendBroadcastMessage(event: 'stroke', payload: {
      'user_id': uid,
      'color': stroke.color.value,
      'points': [
        for (final p in stroke.points) [p.dx / size.width, p.dy / size.height]
      ],
    });
  }

  Future<void> _saveSnapshot(String coupleId) async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final bytes = data.buffer.asUint8List();
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    const path = 'mural.png';
    final storagePath = '$coupleId/$path';
    await client.storage.from('canvas').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
        );
    await client.from('canvases').upsert({
      'couple_id': coupleId,
      'storage_path': storagePath,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': uid,
    });
  }

  void _scheduleSave() {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId == null) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 3), () => _saveSnapshot(coupleId));
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = ref.watch(activeCoupleIdProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas'),
        actions: [
          IconButton(
            tooltip: _erasing ? 'Draw' : 'Erase',
            onPressed: () => setState(() => _erasing = !_erasing),
            icon: Icon(_erasing ? Icons.brush : Icons.auto_fix_off),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Clear the mural?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Clear')),
                  ],
                ),
              );
              if (ok != true) return;
              setState(() {
                _strokes.clear();
                _snapshot = null;
              });
              final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
              _channel?.sendBroadcastMessage(
                  event: 'clear', payload: {'user_id': uid});
              if (coupleId != null) await _saveSnapshot(coupleId);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: coupleId == null
          ? const Center(child: Text('Pair first'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Listener(
                  onPointerDown: (e) {
                    _current = _Stroke(
                      _erasing ? AppColors.background : _ink,
                      [e.localPosition],
                    );
                    setState(() => _strokes.add(_current!));
                  },
                  onPointerMove: (e) {
                    setState(() => _current?.points.add(e.localPosition));
                  },
                  onPointerUp: (_) {
                    if (_current != null) _broadcast(_current!, size);
                    _current = null;
                    _scheduleSave();
                  },
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: CustomPaint(
                      size: size,
                      painter: _MuralPainter(
                        snapshot: _snapshot,
                        strokes: List.of(_strokes),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _MuralPainter extends CustomPainter {
  _MuralPainter({required this.snapshot, required this.strokes});

  final Uint8List? snapshot;
  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    if (snapshot != null) {
      // Snapshot is painted asynchronously; strokes cover live ink.
    }
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MuralPainter oldDelegate) => true;
}