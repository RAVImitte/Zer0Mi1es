import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/canvas_repository.dart';

class _Stroke {
  _Stroke(this.color, this.points, {this.erase = false, this.width = 4});
  final Color color;
  final List<Offset> points;
  final bool erase;
  final double width;

  Map<String, dynamic> toJson() => {
        'color': color.toARGB32(),
        'erase': erase,
        'width': width,
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
      erase: json['erase'] as bool? ?? false,
      width: (json['width'] as num?)?.toDouble() ?? 4,
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
  double _width = 6;
  Color? _inkOverride;
  DateTime? _partnerDrawing;
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
    } catch (_) {}
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
            setState(() => _partnerDrawing = DateTime.now());
            final pts = (payload['points'] as List)
                .map((p) => Offset(
                      (p[0] as num).toDouble(),
                      (p[1] as num).toDouble(),
                    ))
                .toList();
            setState(() => _strokes.add(_Stroke(
                  Color(payload['color'] as int),
                  pts,
                  erase: payload['erase'] == true,
                  width: (payload['width'] as num?)?.toDouble() ?? 4,
                )));
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
    if (_inkOverride != null) return _inkOverride!;
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
      'erase': stroke.erase,
      'width': stroke.width,
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
          title: const Text('Our mural'),
          actions: [
            IconButton(
              tooltip: 'Undo',
              onPressed: _strokes.isEmpty
                  ? null
                  : () {
                      setState(() => _strokes.removeLast());
                      _scheduleSave();
                    },
              icon: Icon(AppIcons.undo),
            ),
            IconButton(
              tooltip: _erasing ? 'Draw' : 'Erase',
              onPressed: () => setState(() => _erasing = !_erasing),
              icon: Icon(_erasing ? AppIcons.brush : AppIcons.erase),
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
              icon: Icon(AppIcons.trash),
            ),
          ],
        ),
        body: coupleId == null
            ? const Center(child: Text('Pair first'))
            : SafeArea(
                top: false,
                child: Column(
                  children: [
                    if (_partnerDrawing != null &&
                        DateTime.now().difference(_partnerDrawing!) <
                            const Duration(seconds: 3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${ref.watch(partnerNameProvider).value ?? 'They'} is drawing',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    if (_strokes.isEmpty && _loaded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Draw something for them. It stays.',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    Expanded(
                      child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Listener(
                    onPointerDown: (e) {
                      _current = _Stroke(
                        _ink,
                        [_normalized(e.localPosition, size)],
                        erase: _erasing,
                        width: _erasing ? _width * 2.2 : _width,
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
                    _toolbar(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _toolbar() {
    const inks = [
      Color(0xFFE8A090),
      Color(0xFFE25C7A),
      Color(0xFFF2C6B8),
      Color(0xFFE0B56A),
      Color(0xFFF6F0E8),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          for (final color in inks)
            GestureDetector(
              onTap: () => setState(() {
                _inkOverride = color;
                _erasing = false;
              }),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (!_erasing && (_inkOverride ?? _ink) == color)
                        ? AppColors.textPrimary
                        : AppColors.hairline,
                    width: 2,
                  ),
                ),
              ),
            ),
          const Spacer(),
          for (final w in [3.0, 6.0, 10.0])
            GestureDetector(
              onTap: () => setState(() => _width = w),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(left: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _width == w
                        ? AppColors.primary
                        : AppColors.hairline,
                  ),
                ),
                child: Container(
                  width: w + 2,
                  height: w + 2,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MuralPainter extends CustomPainter {
  _MuralPainter({required this.strokes});

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.erase ? BlendMode.clear : BlendMode.srcOver
        ..color = stroke.erase ? Colors.transparent : stroke.color;
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MuralPainter oldDelegate) => true;
}