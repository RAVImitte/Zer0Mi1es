import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../utils/partner_scene.dart';

final windowMotionPausedProvider = NotifierProvider<WindowMotionPaused, bool>(
  WindowMotionPaused.new,
);

class WindowMotionPaused extends Notifier<bool> {
  @override
  bool build() => false;

  void setPaused(bool value) => state = value;
}

/// Soft weather aura behind a puppet — no hard frame.
class LivingWindow extends ConsumerStatefulWidget {
  const LivingWindow({
    super.key,
    required this.scene,
    required this.child,
    this.sleeping = false,
    this.unpaired = false,
    this.leftSeat = true,
    this.onTap,
    this.onLongPress,
    this.rimColor,
  });

  final PartnerScene scene;
  final Widget child;
  final bool sleeping;
  final bool unpaired;
  final bool leftSeat;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? rimColor;

  @override
  ConsumerState<LivingWindow> createState() => _LivingWindowState();
}

class _LivingWindowState extends ConsumerState<LivingWindow>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() => _time = elapsed.inMilliseconds / 1000.0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant LivingWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final paused = ref.read(windowMotionPausedProvider);
    final enabled = TickerMode.valuesOf(context).enabled &&
        !reduce &&
        !paused &&
        !widget.unpaired;
    final ticker = _ticker;
    if (ticker == null) return;
    if (enabled) {
      if (!ticker.isTicking) ticker.start();
    } else if (ticker.isTicking) {
      ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(windowMotionPausedProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncTicker();
      });
    });

    final reduce = MediaQuery.disableAnimationsOf(context);
    final look = sceneLook(widget.scene, unpaired: widget.unpaired);
    final rim = widget.rimColor ?? AppColors.primary;

    return Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            if (w <= 0 || h <= 0) return const SizedBox.shrink();
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  isComplex: true,
                  willChange: !reduce && !widget.unpaired,
                  painter: _StagePainter(
                    look: look,
                    scene: widget.scene,
                    time: _time,
                    sleeping: widget.sleeping,
                    unpaired: widget.unpaired,
                    leftSeat: widget.leftSeat,
                    rim: rim,
                    animate: !reduce && !widget.unpaired,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: h * 0.04,
                  child: widget.child,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.look,
    required this.scene,
    required this.time,
    required this.sleeping,
    required this.unpaired,
    required this.leftSeat,
    required this.rim,
    required this.animate,
  });

  final SceneLook look;
  final PartnerScene scene;
  final double time;
  final bool sleeping;
  final bool unpaired;
  final bool leftSeat;
  final Color rim;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    // Bleed on the outer and top/bottom edges. Keep the inner edge
    // short so it does not draw a seam across the other face.
    final outer = size.width * 0.34;
    final inner = size.width * 0.08;
    final padLeft = leftSeat ? outer : inner;
    final padRight = leftSeat ? inner : outer;
    final padTop = size.height * 0.28;
    final padBottom = size.height * 0.18;
    final bounds = Rect.fromLTRB(
      -padLeft,
      -padTop,
      size.width + padRight,
      size.height + padBottom,
    );
    canvas.saveLayer(bounds, Paint());

    _sky(canvas, bounds);
    _moodGlow(canvas, bounds);
    if (!unpaired) {
      _orb(canvas, size);
      if (animate) _weather(canvas, size);
    }
    _ground(canvas, size);
    if (sleeping) _sleepDim(canvas, bounds);

    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 36)
        ..shader = RadialGradient(
          center: const Alignment(0, 0.08),
          radius: 0.98,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.88),
            Colors.white.withValues(alpha: 0.48),
            Colors.white.withValues(alpha: 0.16),
            Colors.transparent,
          ],
          stops: const [0.0, 0.26, 0.52, 0.76, 1.0],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  void _sky(Canvas canvas, Rect bounds) {
    final dim = sleeping ? 0.55 : (unpaired ? 0.45 : 1.0);
    Color fade(Color c, [double a = 1]) =>
        c.withValues(alpha: (a * dim).clamp(0.0, 1.0));

    final sky = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.08),
        radius: 1.2,
        colors: [
          fade(look.skyHi, 0.92),
          fade(look.skyMid, 0.62),
          fade(look.skyMid, 0.28),
          fade(look.skyMid, 0),
        ],
        stops: const [0.0, 0.34, 0.62, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, sky);
  }

  void _moodGlow(Canvas canvas, Rect bounds) {
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.35),
        radius: 0.62,
        colors: [
          rim.withValues(alpha: sleeping ? 0.12 : 0.28),
          rim.withValues(alpha: 0),
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, glow);
  }

  void _orb(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final night =
        scene == PartnerScene.night || scene == PartnerScene.evening;
    final r = w * (night ? 0.09 : 0.08);
    final c = Offset(w * 0.72, h * 0.22);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          look.accent.withValues(alpha: sleeping ? 0.35 : 0.7),
          look.accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 3.2));
    canvas.drawCircle(c, r * 3.2, glow);
    canvas.drawCircle(
      c,
      r,
      Paint()..color = look.accent.withValues(alpha: sleeping ? 0.55 : 0.92),
    );
    if (night) {
      canvas.drawCircle(
        c.translate(-r * 0.28, -r * 0.1),
        r * 0.72,
        Paint()..color = look.skyMid.withValues(alpha: 0.35),
      );
    }
  }

  void _weather(Canvas canvas, Size size) {
    switch (scene) {
      case PartnerScene.night:
      case PartnerScene.evening:
        _stars(canvas, size);
      case PartnerScene.dawn:
      case PartnerScene.morning:
        _clouds(canvas, size);
      case PartnerScene.afternoon:
        _motes(canvas, size);
    }
  }

  void _stars(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 16; i++) {
      final seed = i * 17.3;
      final x = (math.sin(seed) * 0.5 + 0.5) * size.width;
      final y = (math.cos(seed * 1.3) * 0.5 + 0.5) * size.height * 0.5;
      final twinkle = 0.25 + 0.55 * (0.5 + 0.5 * math.sin(time * 1.4 + seed));
      paint.color = Colors.white.withValues(alpha: twinkle * (sleeping ? 0.7 : 1));
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.35, paint);
    }
  }

  void _clouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.14);
    for (var i = 0; i < 3; i++) {
      final x = ((time * 7 + i * 90) % (size.width + 70)) - 35;
      final y = size.height * (0.18 + i * 0.07);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 54, height: 16),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + 14, y - 4),
          width: 28,
          height: 14,
        ),
        paint,
      );
    }
  }

  void _motes(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 10; i++) {
      final seed = i * 11.0;
      final x = (math.sin(time * 0.3 + seed) * 0.5 + 0.5) * size.width;
      final y = (size.height * 0.72 -
              ((time * 10 + seed * 20) % (size.height * 0.5)))
          .clamp(0, size.height);
      paint.color = look.accent.withValues(alpha: 0.28);
      canvas.drawCircle(Offset(x, y.toDouble()), 1.3, paint);
    }
  }

  void _ground(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.9),
      width: size.width * 1.15,
      height: size.height * 0.22,
    );
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          look.ground.withValues(alpha: sleeping ? 0.5 : 0.82),
          look.ground.withValues(alpha: 0.28),
          look.ground.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    canvas.drawOval(rect, paint);
    canvas.drawOval(
      rect.deflate(size.width * 0.08),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );
  }

  void _sleepDim(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.2),
        radius: 0.9,
        colors: const [
          Color(0x66101828),
          Color(0x00101828),
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, paint);
  }

  @override
  bool shouldRepaint(covariant _StagePainter old) =>
      old.time != time ||
      old.scene != scene ||
      old.sleeping != sleeping ||
      old.unpaired != unpaired ||
      old.leftSeat != leftSeat ||
      old.rim != rim ||
      old.look != look;
}

class WindowSillCaption extends StatelessWidget {
  const WindowSillCaption({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
