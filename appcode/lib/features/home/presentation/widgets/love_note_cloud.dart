import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../avatar/presentation/couple_scene_view_model.dart';

const kLoveNoteMaxChars = 36;
const kLoveNoteMaxLines = 3;

class LoveNoteCloud extends StatefulWidget {
  const LoveNoteCloud({
    super.key,
    required this.note,
    required this.onPopped,
  });

  final SeatNote note;
  final VoidCallback onPopped;

  @override
  State<LoveNoteCloud> createState() => _LoveNoteCloudState();
}

class _LoveNoteCloudState extends State<LoveNoteCloud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _burst() async {
    if (_popping) return;
    _popping = true;
    HapticFeedback.lightImpact();
    await _pop.forward();
    if (mounted) widget.onPopped();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final maxW =
            (box.maxWidth.isFinite && box.maxWidth >= 48) ? box.maxWidth : 160.0;
        final maxH = box.maxHeight.isFinite
            ? math.max(box.maxHeight, 80.0)
            : 140.0;

        const padX = 18.0;
        const padY = 14.0;
        const trailH = 24.0;
        const diag = 16.0;
        final textMaxW = (maxW - padX * 2 - diag).clamp(40.0, 160.0);
        final style = Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF3A2A22),
              height: 1.25,
              fontWeight: FontWeight.w600,
            );

        final span = TextSpan(
          children: [
            if (widget.note.emoji != null && widget.note.emoji!.isNotEmpty)
              TextSpan(text: '${widget.note.emoji} '),
            TextSpan(text: widget.note.text),
          ],
          style: style,
        );
        final tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          maxLines: kLoveNoteMaxLines,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: textMaxW);

        final heightCap = maxH.isFinite ? math.max(36.0, maxH - trailH) : 96.0;
        final cloudW =
            (tp.width + padX * 2).clamp(76.0, math.max(76.0, maxW - diag)).toDouble();
        final cloudH =
            (tp.height + padY * 2).clamp(36.0, heightCap).toDouble();

        return Semantics(
          button: true,
          label: 'Pop note',
          child: GestureDetector(
            onTap: _burst,
            child: AnimatedBuilder(
              animation: _pop,
              builder: (context, child) {
                final v = _pop.value;
                final scale =
                    (1.0 + 0.1 * v - 1.2 * v * v).clamp(0.0, 1.12).toDouble();
                final opacity = (1 - v).clamp(0.0, 1.0).toDouble();
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                width: cloudW + diag,
                height: cloudH + trailH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      width: cloudW,
                      height: cloudH,
                      child: CustomPaint(
                        painter: _VolumeCloudPainter(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Text.rich(
                            span,
                            maxLines: kLoveNoteMaxLines,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: diag * 0.42,
                      bottom: 8,
                      child: const _Puff(diameter: 9),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: const _Puff(diameter: 5.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Puff extends StatelessWidget {
  const _Puff({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(diameter),
      painter: _PuffPainter(),
    );
  }
}

class _PuffPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c.translate(0.4, 0.8),
      r,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.4),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: const [
            Color(0xFFFFFCF8),
            Color(0xFFE8D5C2),
            Color(0xFFCDB49A),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx - r * 0.22, c.dy - r * 0.28),
        width: r * 0.7,
        height: r * 0.42,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VolumeCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lobes = <(Offset, double)>[
      (Offset(w * 0.22, h * 0.58), h * 0.34),
      (Offset(w * 0.50, h * 0.38), h * 0.42),
      (Offset(w * 0.78, h * 0.56), h * 0.33),
      (Offset(w * 0.38, h * 0.62), h * 0.30),
      (Offset(w * 0.64, h * 0.64), h * 0.28),
    ];

    for (final lobe in lobes) {
      final (c, r) = lobe;
      canvas.drawCircle(
        c.translate(0.8, 2.2),
        r,
        Paint()
          ..color = const Color(0x3D000000)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.1, h * 0.4, w * 0.9, h * 0.9),
        Radius.circular(h * 0.28),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFFFFBF6),
            Color(0xFFF0E0D0),
            Color(0xFFD4BBA4),
          ],
        ).createShader(Offset.zero & size),
    );

    for (final lobe in lobes) {
      _lobe(canvas, lobe.$1, lobe.$2);
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.82),
        width: w * 0.62,
        height: h * 0.22,
      ),
      Paint()
        ..color = const Color(0x2A8A6A50)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.38, h * 0.28),
        width: w * 0.42,
        height: h * 0.18,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );
  }

  void _lobe(Canvas canvas, Offset c, double r) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.42),
          radius: 1.05,
          colors: const [
            Color(0xFFFFFDF9),
            Color(0xFFF4E6D6),
            Color(0xFFC9AE96),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx - r * 0.28, c.dy - r * 0.34),
        width: r * 0.58,
        height: r * 0.32,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tiny leftover thought after the cloud is popped — tap to bring it back.
class LoveNoteEmber extends StatefulWidget {
  const LoveNoteEmber({super.key, required this.onRestore});

  final VoidCallback onRestore;

  @override
  State<LoveNoteEmber> createState() => _LoveNoteEmberState();
}

class _LoveNoteEmberState extends State<LoveNoteEmber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Show note',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onRestore();
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = 0.86 + 0.14 * _pulse.value;
            return Transform.scale(scale: t, child: child);
          },
          child: SizedBox(
            width: 22,
            height: 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  right: 0,
                  top: 0,
                  child: _Puff(diameter: 15),
                ),
                const Positioned(
                  left: 0,
                  bottom: 0,
                  child: _Puff(diameter: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
