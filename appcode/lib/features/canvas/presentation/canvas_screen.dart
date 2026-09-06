import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/canvas_repository.dart';

class _Stroke {
  _Stroke(this.color, this.points);
  final Color color;
  final List<Offset> points;

  Map<String, dynamic> toJson() => {
        'color': color.toARGB32(),
        'points': [
          for (final p in points) [p.dx, p.dy],
        ],
      };

  factory _Stroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List? ?? const [];
    return _Stroke(
      Color(json['color'] as int),
      [
        for (final p in rawPoints)
          Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ],
    );
  }
}

class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final List<_Stroke> _strokes = [];
  _Stroke? _current;
  RealtimeChannel? _liveChannel;
  RealtimeChannel? _tableChannel;
  bool _erasing = false;
  bool _loaded = false;
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
    if (coupleId != null && _loaded) {
      unawaited(_persist(coupleId));
    }
    final client = ref.read(supabaseClientProvider);
    if (_liveChannel != null) client.removeChannel(_liveChannel!);
    if (_tableChannel != null) client.removeChannel(_tableChannel!);
    super.dispose();
  }

  Future<void> _boot() async {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (coupleId == null || uid == null) return;

    try {
      final mural = await ref.read(canvasRepositoryProvider).load(coupleId);
      if (mural != null && mounted) {
        setState(() {
          _strokes
            ..clear()
            ..addAll(mural.strokes.map(_Stroke.fromJson));
        });
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load canvas')),
        );
      }
    }
    if (mounted) setState(() => _loaded = true);

    _tableChannel = ref.read(canvasRepositoryProvider).subscribe(
      coupleId,
      onRemote: (mural) {
        if (!mounted) return;
        setState(() {
          _strokes
            ..clear()
            ..addAll(mural.strokes.map(_Stroke.fromJson));
        });
      },
    );

    _liveChannel = client.channel('canvas:$coupleId');
    _liveChannel!
        .onBroadcast(
          event: 'stroke',
          callback: (payload) {
            if (payload['user_id'] == uid || !mounted) return;
            final pts = (payload['points'] as List)
                .map((p) => Offset(
                      (p[0] as num).toDouble(),
                      (p[1] as num).toDouble(),
                    ))
                .toList();
            setState(() => _strokes.add(_Stroke(Color(payload['color'] as int), pts)));
          },
        )
        .onBroadcast(
          event: 'clear',
          callback: (payload) {
            if (payload['user_id'] == uid || !mounted) return;
            setState(_strokes.clear);
          },
        )
        .subscribe();
  }

  Color get _ink {
    final role = ref.read(myRoleProvider).value;
    return role == CoupleRole.bunny ? AppColors.affection : AppColors.primary;
  }

  List<Map<String, dynamic>> get _payload =>
      [for (final s in _strokes) s.toJson()];

  Future<void> _persist(String coupleId) async {
    if (!_loaded) return;
    await ref.read(canvasRepositoryProvider).save(coupleId, _payload);
  }

  void _scheduleSave() {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId == null) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () {
      _persist(coupleId);
    });
  }

  void _broadcast(_Stroke stroke) {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null || _liveChannel == null) return;
    _liveChannel!.sendBroadcastMessage(event: 'stroke', payload: {
      'user_id': uid,
      'color': stroke.color.toARGB32(),
      'points': [
        for (final p in stroke.points) [p.dx, p.dy],
      ],
    });
  }

  Offset _normalized(Offset local, Size size) {
    if (size.width == 0 || size.height == 0) return Offset.zero;
    return Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = ref.watch(activeCoupleIdProvider.select((v) => v.value));
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (coupleId != null) unawaited(_persist(coupleId));
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                setState(_strokes.clear);
                final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
                _liveChannel?.sendBroadcastMessage(
                    event: 'clear', payload: {'user_id': uid});
                if (coupleId != null) await _persist(coupleId);
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: coupleId == null
            ? const Center(child: Text('Pair first'))
            : SafeArea(
                top: false,
                child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Listener(
                    onPointerDown: (e) {
                      _current = _Stroke(
                        _erasing ? AppColors.background : _ink,
                        [_normalized(e.localPosition, size)],
                      );
                      setState(() => _strokes.add(_current!));
                    },
                    onPointerMove: (e) {
                      setState(() =>
                          _current?.points.add(_normalized(e.localPosition, size)));
                    },
                    onPointerUp: (_) {
                      if (_current != null) _broadcast(_current!);
                      _current = null;
                      _scheduleSave();
                    },
                    child: CustomPaint(
                      size: size,
                      painter: _MuralPainter(strokes: List.of(_strokes)),
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }
}

class _MuralPainter extends CustomPainter {
  _MuralPainter({required this.strokes});

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(
          stroke.points.first.dx * size.width,
          stroke.points.first.dy * size.height,
        );
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MuralPainter oldDelegate) => true;
}