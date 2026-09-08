import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/avatar_event.dart';
import '../puppet/puppet_pose.dart';

class LayeredPersonAvatar extends StatefulWidget {
  const LayeredPersonAvatar({
    super.key,
    required this.state,
    required this.topColor,
    required this.bottomColor,
    this.isBunny = false,
    this.leftSeat = true,
    this.size = 150,
  });

  final AnimationState state;
  final Color topColor;
  final Color bottomColor;
  final bool isBunny;
  final bool leftSeat;
  final double size;

  @override
  State<LayeredPersonAvatar> createState() => _LayeredPersonAvatarState();
}

class _LayeredPersonAvatarState extends State<LayeredPersonAvatar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  double _blink = 1;
  double _blinkClock = 2.4;
  double _squashPulse = 0;
  PuppetPose _pose = const PuppetPose();
  final _rng = math.Random();

  static const _skin = Color(0xFFF6C7A0);
  static const _hair = Color(0xFF1A1A1A);
  static const _outline = Color(0xFF161616);
  static const _shoe = Color(0xFF1C1C1C);

  @override
  void initState() {
    super.initState();
    _pose = PuppetPose.forState(widget.state, leftSeat: widget.leftSeat);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant LayeredPersonAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state &&
        widget.state == AnimationState.receiving) {
      _squashPulse = 1;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final clampedDt = dt.clamp(0.0, 1 / 30);

    _time += clampedDt;
    _squashPulse = math.max(0, _squashPulse - clampedDt * 2.6);

    final sleeping = widget.state == AnimationState.sleeping;
    if (!sleeping) {
      _blinkClock -= clampedDt;
      if (_blinkClock <= 0) {
        _blinkClock = 2.2 + _rng.nextDouble() * 3.0;
        _blink = 0;
      }
      _blink += (1 - _blink) * (1 - math.exp(-clampedDt * 18));
    } else {
      _blink = 0;
    }

    final target = PuppetPose.forState(widget.state, leftSeat: widget.leftSeat);
    final k = 1 - math.exp(-clampedDt * 7.5);
    _pose = PuppetPose.lerp(_pose, target, k);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final breathe = math.sin(_time * math.pi * 2 / 2.35);
    final sway = math.sin(_time * math.pi * 2 / 3.4);
    final happyHop = widget.state == AnimationState.moodHappy ||
            widget.state == AnimationState.moodExcited
        ? (0.5 + 0.5 * math.sin(_time * math.pi * 5)).clamp(0.0, 1.0)
        : 0.0;
    final angryStomp = widget.state == AnimationState.moodAngry
        ? (0.5 + 0.5 * math.sin(_time * math.pi * 9)).clamp(0.0, 1.0)
        : 0.0;

    final pulse = math.sin(_squashPulse * math.pi);
    final squashX = (_pose.squashX *
            (1 + 0.035 * pulse) *
            (1 - 0.008 * breathe) *
            (1 + 0.018 * angryStomp))
        .clamp(0.97, 1.05);
    final squashY = (_pose.squashY *
            (1 - 0.025 * pulse) *
            (1 + 0.01 * breathe) *
            (1 - 0.022 * angryStomp))
        .clamp(0.97, 1.04);

    final blinkLid = 1 - _blink;
    final pose = PuppetPose(
      headTilt: _pose.headTilt + sway * 0.035 + angryStomp * 0.04,
      headY: _pose.headY + breathe * 0.006 - happyHop * 0.018 + angryStomp * 0.01,
      bodySquash: _pose.bodySquash,
      armL: _pose.armL,
      armR: _pose.armR,
      eyeOpen: _pose.eyeOpen,
      eyeScaleY: _pose.eyeScaleY,
      lidDrop: math.max(_pose.lidDrop, blinkLid),
      browDown: _pose.browDown,
      browWorry: _pose.browWorry,
      mouthSmile: _pose.mouthSmile,
      mouthOpen: _pose.mouthOpen,
      blush: _pose.blush,
      heartEyes: _pose.heartEyes,
      sparkle: _pose.sparkle,
      sweat: _pose.sweat,
      tear: _pose.tear,
      squashX: squashX,
      squashY: squashY,
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(widget.size),
            painter: _PuppetPainter(
              pose: pose,
              topColor: widget.topColor,
              bottomColor: widget.bottomColor,
              isBunny: widget.isBunny,
              devastated: widget.state == AnimationState.moodDevastated,
              angry: widget.state == AnimationState.moodAngry,
              t: _time,
            ),
          ),
          if (widget.state == AnimationState.sleeping)
            _ZzzOverlay(size: widget.size, t: _time),
          if (_pose.heartEyes > 0.4)
            _HeartOverlay(size: widget.size, t: _time),
        ],
      ),
    );
  }
}

class _ZzzOverlay extends StatelessWidget {
  const _ZzzOverlay({required this.size, required this.t});
  final double size;
  final double t;

  @override
  Widget build(BuildContext context) {
    final phase = (t % 2.4) / 2.4;
    return Positioned(
      top: size * (0.04 - 0.12 * phase),
      right: size * (0.08 + 0.04 * math.sin(t * 2)),
      child: Opacity(
        opacity: (1 - phase).clamp(0.0, 1.0),
        child: Text(
          'Zzz',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: size * 0.12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HeartOverlay extends StatelessWidget {
  const _HeartOverlay({required this.size, required this.t});
  final double size;
  final double t;

  @override
  Widget build(BuildContext context) {
    final phase = (t % 1.4) / 1.4;
    return Positioned(
      top: size * (-0.02 - 0.16 * phase),
      child: Opacity(
        opacity: (1 - phase).clamp(0.0, 1.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💖', style: TextStyle(fontSize: size * 0.11)),
            SizedBox(width: size * 0.18),
            Text('💖', style: TextStyle(fontSize: size * 0.15)),
          ],
        ),
      ),
    );
  }
}

class _PuppetPainter extends CustomPainter {
  _PuppetPainter({
    required this.pose,
    required this.topColor,
    required this.bottomColor,
    required this.isBunny,
    required this.devastated,
    required this.angry,
    required this.t,
  });

  final PuppetPose pose;
  final Color topColor;
  final Color bottomColor;
  final bool isBunny;
  final bool devastated;
  final bool angry;
  final double t;

  static const _skin = _LayeredPersonAvatarState._skin;
  static const _hair = _LayeredPersonAvatarState._hair;
  static const _outline = _LayeredPersonAvatarState._outline;
  static const _shoe = _LayeredPersonAvatarState._shoe;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0 || !w.isFinite || !h.isFinite) return;
    final stroke = (w * 0.028).clamp(1.6, 4.2);

    // Squash from the feet so hops and stomps don't pancake the figure.
    final footY = h * 0.93;
    canvas.save();
    canvas.translate(w / 2, footY);
    canvas.scale(pose.squashX, pose.squashY);
    canvas.translate(-w / 2, -footY);
    canvas.translate(0, pose.headY * h * 0.5);

    _drawShadow(canvas, w, h);

    final neck = Offset(w / 2, h * 0.445);
    final headC = Offset(w / 2, h * 0.30);
    final headR = w * 0.20;

    // Arms after the shirt so inward hands stay in front of the body.
    _drawPants(canvas, w, h, stroke);
    _drawShoes(canvas, w, h, stroke);
    _drawNeck(canvas, w, h, stroke);
    _drawShirt(canvas, w, h, stroke);
    _drawArm(canvas, w, h, left: true, stroke: stroke);
    _drawArm(canvas, w, h, left: false, stroke: stroke);

    canvas.save();
    canvas.translate(headC.dx, neck.dy);
    canvas.rotate(pose.headTilt);
    canvas.translate(-headC.dx, -neck.dy);

    if (isBunny) {
      _drawGirlHairBack(canvas, headC, headR, stroke);
    }

    _fillStrokeCircle(canvas, headC, headR, _skin, stroke);
    _drawEarsOnHead(canvas, headC, headR, stroke);
    if (isBunny) {
      _drawGirlHairFront(canvas, headC, headR, stroke);
    } else {
      _drawHair(canvas, headC, headR, stroke);
    }
    _drawFace(canvas, headC, headR, stroke);
    if (angry) {
      _drawAngerMark(canvas, headC, headR);
    }

    canvas.restore();
    canvas.restore();
  }

  void _drawShadow(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.955),
        width: w * 0.42,
        height: h * 0.05,
      ),
      paint,
    );
  }

  ({
    double lC,
    double rC,
    double hipTop,
    double ankle,
    double crotchY,
    double hipLegW,
    double ankleW,
  }) _legGeom(double w, double h) {
    final gap = isBunny ? w * 0.072 : w * 0.064;
    final hipW = isBunny ? w * 0.35 : w * 0.325;
    final hipLegW = (hipW - gap) / 2;
    final ankleW = hipLegW * (isBunny ? 0.84 : 0.76);
    final cx = w / 2;
    return (
      lC: cx - (gap / 2 + hipLegW / 2),
      rC: cx + (gap / 2 + hipLegW / 2),
      hipTop: h * 0.648,
      ankle: h * 0.90,
      crotchY: h * 0.702,
      hipLegW: hipLegW,
      ankleW: ankleW,
    );
  }

  void _drawShoes(Canvas canvas, double w, double h, double stroke) {
    final g = _legGeom(w, h);
    final shoeW = g.ankleW * 1.28;
    final shoeH = h * 0.05;
    final y = h * 0.918;
    for (final cx in [g.lC, g.rC]) {
      _fillStrokeRRect(
        canvas,
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, y),
            width: shoeW,
            height: shoeH,
          ),
          Radius.circular(shoeH * 0.45),
        ),
        _shoe,
        stroke,
      );
    }
  }

  void _drawPants(Canvas canvas, double w, double h, double stroke) {
    final g = _legGeom(w, h);
    final rHip = w * 0.032;
    final rAnkle = w * 0.024;
    final lTopO = g.lC - g.hipLegW / 2;
    final lTopI = g.lC + g.hipLegW / 2;
    final lBotO = g.lC - g.ankleW / 2;
    final lBotI = g.lC + g.ankleW / 2;
    final rTopO = g.rC + g.hipLegW / 2;
    final rTopI = g.rC - g.hipLegW / 2;
    final rBotO = g.rC + g.ankleW / 2;
    final rBotI = g.rC - g.ankleW / 2;

    final path = Path()
      ..moveTo(lTopO + rHip, g.hipTop)
      ..lineTo(rTopO - rHip, g.hipTop)
      ..quadraticBezierTo(rTopO, g.hipTop, rTopO, g.hipTop + rHip)
      ..lineTo(rBotO, g.ankle - rAnkle)
      ..quadraticBezierTo(rBotO, g.ankle, rBotO - rAnkle, g.ankle)
      ..lineTo(rBotI + rAnkle * 0.55, g.ankle)
      ..quadraticBezierTo(rBotI, g.ankle, rBotI, g.ankle - rAnkle)
      ..lineTo(rTopI, g.crotchY)
      ..quadraticBezierTo(w / 2, g.crotchY + h * 0.01, lTopI, g.crotchY)
      ..lineTo(lBotI, g.ankle - rAnkle)
      ..quadraticBezierTo(lBotI, g.ankle, lBotI - rAnkle * 0.55, g.ankle)
      ..lineTo(lBotO + rAnkle, g.ankle)
      ..quadraticBezierTo(lBotO, g.ankle, lBotO, g.ankle - rAnkle)
      ..lineTo(lTopO, g.hipTop + rHip)
      ..quadraticBezierTo(lTopO, g.hipTop, lTopO + rHip, g.hipTop)
      ..close();
    _fillStrokePath(canvas, path, bottomColor, stroke * 0.85);
  }

  void _drawNeck(Canvas canvas, double w, double h, double stroke) {
    _fillStrokeRRect(
      canvas,
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, h * 0.455),
          width: w * 0.11,
          height: h * 0.07,
        ),
        Radius.circular(w * 0.055),
      ),
      _skin,
      stroke,
    );
  }

  void _drawShirt(Canvas canvas, double w, double h, double stroke) {
    final shirtH = h * 0.26 * pose.bodySquash;
    final shirtW = w * 0.36;
    final center = Offset(w / 2, h * 0.56);
    final torso = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: center,
        width: shirtW,
        height: shirtH,
      ),
      topLeft: Radius.circular(w * 0.17),
      topRight: Radius.circular(w * 0.17),
      bottomLeft: Radius.circular(w * 0.10),
      bottomRight: Radius.circular(w * 0.10),
    );
    _fillStrokeRRect(canvas, torso, topColor, stroke);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - shirtH * 0.12),
        width: shirtW * 0.42,
        height: shirtH * 0.22,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
  }

  void _drawArm(
    Canvas canvas,
    double w,
    double h, {
    required bool left,
    required double stroke,
  }) {
    final shoulder = Offset(
      w / 2 + (left ? -w * 0.165 : w * 0.165),
      h * 0.49,
    );
    final angle = left ? pose.armL : pose.armR;
    final length = h * 0.235;
    final armW = w * 0.10;

    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(angle);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armW / 2, 0, armW, length),
      Radius.circular(armW),
    );
    _fillStrokeRRect(canvas, rect, _skin, stroke);
    _fillStrokeCircle(canvas, Offset(0, length), armW * 0.48, _skin, stroke);

    final sleeve = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armW / 2, -armW * 0.12, armW, length * 0.36),
      Radius.circular(armW),
    );
    _fillStrokeRRect(canvas, sleeve, topColor, stroke);
    canvas.restore();
  }

  void _drawAngerMark(Canvas canvas, Offset headC, double headR) {
    final phase = (t % 0.42) / 0.42;
    final opacity = (1 - phase).clamp(0.0, 1.0);
    final painter = TextPainter(
      text: TextSpan(
        text: '💢',
        style: TextStyle(fontSize: headR * 0.7),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final origin = Offset(
      headC.dx + headR * 0.58,
      headC.dy - headR * 0.98 - headR * 0.08 * phase,
    );
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(0.86 + 0.22 * phase);
    canvas.saveLayer(
      Rect.fromCenter(
        center: Offset.zero,
        width: painter.width * 1.2,
        height: painter.height * 1.2,
      ),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2),
    );
    canvas.restore();
    canvas.restore();
  }

  void _drawEarsOnHead(Canvas canvas, Offset headC, double headR, double stroke) {
    _fillStrokeCircle(
      canvas,
      Offset(headC.dx - headR * 0.92, headC.dy + headR * 0.08),
      headR * 0.2,
      _skin,
      stroke,
    );
    _fillStrokeCircle(
      canvas,
      Offset(headC.dx + headR * 0.92, headC.dy + headR * 0.08),
      headR * 0.2,
      _skin,
      stroke,
    );
  }

  Offset _hp(Offset c, double r, double x, double y) =>
      Offset(c.dx + r * x, c.dy + r * y);

  Path _hairLock(Offset a, Offset tip, Offset b) {
    final midAb = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(
        (a.dx + tip.dx) / 2 + (a.dx - b.dx) * 0.08,
        (a.dy + tip.dy) / 2,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        (b.dx + tip.dx) / 2 + (b.dx - a.dx) * 0.08,
        (b.dy + tip.dy) / 2,
        b.dx,
        b.dy,
      )
      ..quadraticBezierTo(midAb.dx, midAb.dy, a.dx, a.dy)
      ..close();
  }

  void _paintLock(Canvas canvas, Path path, double stroke) {
    _fillStrokePath(canvas, path, _hair, stroke);
  }

  void _paintShine(Canvas canvas, Offset a, Offset b, double width) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = const Color(0xFF6E6E6E)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawHair(Canvas canvas, Offset headC, double headR, double stroke) {
    Offset p(double x, double y) => _hp(headC, headR, x, y);

    _paintLock(
      canvas,
      Path()
        ..moveTo(p(-0.92, -0.28).dx, p(-0.92, -0.28).dy)
        ..cubicTo(
          p(-1.05, -0.78).dx,
          p(-1.05, -0.78).dy,
          p(-0.4, -1.2).dx,
          p(-0.4, -1.2).dy,
          p(0.1, -1.1).dx,
          p(0.1, -1.1).dy,
        )
        ..cubicTo(
          p(0.58, -1.22).dx,
          p(0.58, -1.22).dy,
          p(1.08, -0.75).dx,
          p(1.08, -0.75).dy,
          p(0.94, -0.22).dx,
          p(0.94, -0.22).dy,
        )
        ..quadraticBezierTo(
          p(0.05, -0.62).dx,
          p(0.05, -0.62).dy,
          p(-0.92, -0.28).dx,
          p(-0.92, -0.28).dy,
        ),
      stroke,
    );

    _paintLock(
      canvas,
      _hairLock(p(-0.55, -0.62), p(-0.62, -1.18), p(-0.12, -0.78)),
      stroke,
    );
    _paintLock(
      canvas,
      _hairLock(p(-0.12, -0.78), p(0.18, -1.38), p(0.42, -0.7)),
      stroke,
    );
    _paintLock(
      canvas,
      _hairLock(p(0.22, -0.68), p(0.62, -1.32), p(0.72, -0.42)),
      stroke,
    );

    _paintLock(
      canvas,
      _hairLock(p(-0.8, -0.4), p(-0.62, -0.12), p(-0.42, -0.44)),
      stroke,
    );
    _paintLock(
      canvas,
      _hairLock(p(-0.28, -0.46), p(0.02, -0.1), p(0.2, -0.44)),
      stroke,
    );
    _paintLock(
      canvas,
      _hairLock(p(0.34, -0.42), p(0.6, -0.1), p(0.84, -0.36)),
      stroke,
    );

    _paintShine(canvas, p(-0.04, -0.96), p(0.24, -1.14), headR * 0.07);
    _paintShine(canvas, p(0.22, -1.04), p(0.38, -1.18), headR * 0.045);
  }

  Path _girlWaveLock(Offset headC, double headR, {required bool left}) {
    final s = left ? -1.0 : 1.0;
    final length = left ? 1.12 : 1.22;
    Offset p(double x, double y) => _hp(headC, headR, s * x, y);
    return Path()
      ..moveTo(p(0.55, -0.22).dx, p(0.55, -0.22).dy)
      ..cubicTo(
        p(1.1, 0.08).dx,
        p(1.1, 0.08).dy,
        p(1.16, 0.52).dx,
        p(1.16, 0.52).dy,
        p(1.0, 0.88).dx,
        p(1.0, 0.88).dy,
      )
      ..quadraticBezierTo(
        p(0.9, length).dx,
        p(0.9, length).dy,
        p(0.7, length - 0.1).dx,
        p(0.7, length - 0.1).dy,
      )
      ..cubicTo(
        p(0.66, 0.58).dx,
        p(0.66, 0.58).dy,
        p(0.56, 0.12).dx,
        p(0.56, 0.12).dy,
        p(0.48, -0.14).dx,
        p(0.48, -0.14).dy,
      )
      ..close();
  }

  void _drawGirlHairBack(
    Canvas canvas,
    Offset headC,
    double headR,
    double stroke,
  ) {
    _paintLock(canvas, _girlWaveLock(headC, headR, left: true), stroke);
    _paintLock(canvas, _girlWaveLock(headC, headR, left: false), stroke);
  }

  void _drawGirlHairFront(Canvas canvas, Offset headC, double headR, double stroke) {
    Offset p(double x, double y) => _hp(headC, headR, x, y);

    _paintLock(
      canvas,
      Path()
        ..moveTo(p(-0.92, -0.32).dx, p(-0.92, -0.32).dy)
        ..cubicTo(
          p(-1.0, -0.82).dx,
          p(-1.0, -0.82).dy,
          p(-0.35, -1.26).dx,
          p(-0.35, -1.26).dy,
          p(0.14, -1.16).dx,
          p(0.14, -1.16).dy,
        )
        ..cubicTo(
          p(0.6, -1.28).dx,
          p(0.6, -1.28).dy,
          p(1.08, -0.8).dx,
          p(1.08, -0.8).dy,
          p(0.94, -0.26).dx,
          p(0.94, -0.26).dy,
        )
        ..quadraticBezierTo(
          p(-0.08, -0.62).dx,
          p(-0.08, -0.62).dy,
          p(-0.92, -0.32).dx,
          p(-0.92, -0.32).dy,
        ),
      stroke,
    );

    _paintLock(
      canvas,
      _hairLock(p(-0.7, -0.5), p(-0.52, -0.18), p(-0.34, -0.52)),
      stroke,
    );
    _paintLock(
      canvas,
      _hairLock(p(-0.22, -0.52), p(0.1, -0.14), p(0.3, -0.5)),
      stroke,
    );
    _paintLock(
      canvas,
      _hairLock(p(0.4, -0.48), p(0.64, -0.14), p(0.86, -0.4)),
      stroke,
    );

    _paintLock(
      canvas,
      _hairLock(p(-0.86, -0.16), p(-0.78, 0.38), p(-0.6, -0.06)),
      stroke * 0.85,
    );
    _paintLock(
      canvas,
      _hairLock(p(0.62, -0.08), p(0.82, 0.34), p(0.88, -0.12)),
      stroke * 0.85,
    );

    final bowFill = Paint()..color = const Color(0xFFFF7AA2);
    final bowStroke = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.5;
    final bowL = p(-0.5, -0.62);
    final bowR = p(-0.28, -0.6);
    canvas.drawCircle(bowL, headR * 0.09, bowFill);
    canvas.drawCircle(bowR, headR * 0.09, bowFill);
    canvas.drawCircle(bowL, headR * 0.09, bowStroke);
    canvas.drawCircle(bowR, headR * 0.09, bowStroke);
    canvas.drawCircle(p(-0.39, -0.61), headR * 0.055, bowFill);
    canvas.drawCircle(p(-0.39, -0.61), headR * 0.055, bowStroke);

    _paintShine(canvas, p(-0.1, -0.94), p(0.2, -1.12), headR * 0.065);
    _paintShine(canvas, p(0.3, -1.02), p(0.48, -1.16), headR * 0.04);
  }

  void _drawFace(Canvas canvas, Offset headC, double headR, double stroke) {
    final eyeY = headC.dy + headR * 0.02;
    final eyeDx = headR * 0.38;
    final eyeR = headR * 0.22;

    _drawBrows(canvas, headC, headR, eyeY, eyeDx, stroke);
    _drawEye(canvas, Offset(headC.dx - eyeDx, eyeY), eyeR);
    _drawEye(canvas, Offset(headC.dx + eyeDx, eyeY), eyeR);
    if (isBunny) {
      _drawLashes(canvas, Offset(headC.dx - eyeDx, eyeY), eyeR, left: true);
      _drawLashes(canvas, Offset(headC.dx + eyeDx, eyeY), eyeR, left: false);
    }

    final blush = Paint()
      ..color = const Color(0xFFFF8AA8).withValues(alpha: 0.45 * pose.blush);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headC.dx - headR * 0.62, headC.dy + headR * 0.28),
        width: headR * 0.28,
        height: headR * 0.12,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headC.dx + headR * 0.62, headC.dy + headR * 0.28),
        width: headR * 0.28,
        height: headR * 0.12,
      ),
      blush,
    );

    final mouthY = headC.dy + headR * 0.42;
    final mouthPaint = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (pose.mouthOpen > 0.08) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headC.dx, mouthY + headR * 0.04),
          width: headR * (0.22 + 0.08 * pose.sparkle),
          height: headR * 0.18 * pose.mouthOpen + headR * 0.07,
        ),
        Paint()..color = const Color(0xFF3A1020),
      );
    } else {
      final smile = pose.mouthSmile;
      final path = Path()
        ..moveTo(headC.dx - headR * 0.18, mouthY)
        ..quadraticBezierTo(
          headC.dx,
          mouthY + headR * 0.16 * smile,
          headC.dx + headR * 0.18,
          mouthY,
        );
      canvas.drawPath(path, mouthPaint);
    }

    if (pose.tear > 0.3) {
      final tearPaint = Paint()..color = const Color(0xFF7EC8FF);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headC.dx - eyeDx, eyeY + headR * 0.42),
          width: headR * 0.11,
          height: headR * 0.2,
        ),
        tearPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headC.dx + eyeDx + headR * 0.02, eyeY + headR * 0.34),
          width: headR * 0.08,
          height: headR * 0.14,
        ),
        tearPaint,
      );
    }

    if (pose.sweat > 0.3) {
      final sweat = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(headC.dx + headR * 0.82, headC.dy - headR * 0.15),
          width: headR * 0.14,
          height: headR * 0.22,
        ));
      canvas.drawPath(sweat, Paint()..color = const Color(0xFFB8E0FF));
      canvas.drawPath(
        sweat,
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.45,
      );
    }
  }

  void _drawBrows(
    Canvas canvas,
    Offset headC,
    double headR,
    double eyeY,
    double eyeDx,
    double stroke,
  ) {
    final paint = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.7
      ..strokeCap = StrokeCap.round;

    void brow(bool left) {
      final cx = headC.dx + (left ? -eyeDx : eyeDx);
      final innerX = cx + (left ? headR * 0.16 : -headR * 0.16);
      final outerX = cx + (left ? -headR * 0.22 : headR * 0.22);
      final innerY = eyeY -
          headR * 0.34 +
          headR * 0.16 * pose.browDown -
          headR * 0.14 * pose.browWorry;
      final outerY = eyeY - headR * 0.32 + headR * 0.04 * pose.browDown;
      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), paint);
    }

    brow(true);
    brow(false);
  }

  void _drawLashes(Canvas canvas, Offset c, double r, {required bool left}) {
    if (pose.eyeOpen < 0.2) return;
    final paint = Paint()
      ..color = _outline
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;
    final dir = left ? -1.0 : 1.0;
    final lid = pose.lidDrop;
    final top = c.dy - r * (0.85 - 0.5 * lid);
    canvas.drawLine(
      Offset(c.dx + dir * r * 0.15, top),
      Offset(c.dx + dir * r * 0.42, top - r * 0.28),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx + dir * r * 0.4, top + r * 0.05),
      Offset(c.dx + dir * r * 0.62, top - r * 0.12),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx - dir * r * 0.05, top),
      Offset(c.dx - dir * r * 0.08, top - r * 0.26),
      paint,
    );
  }

  void _drawClosedEyeLine(Canvas canvas, double r) {
    canvas.drawLine(
      Offset(-r * 0.72, r * 0.04),
      Offset(r * 0.72, r * 0.04),
      Paint()
        ..color = _outline
        ..strokeWidth = r * 0.22
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEye(Canvas canvas, Offset c, double r) {
    if (pose.heartEyes > 0.5) {
      _drawHeart(canvas, c, r * 1.15, const Color(0xFFFF4B6E));
      return;
    }

    final scaleY = pose.eyeScaleY.clamp(0.55, 1.15);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1, scaleY);

    final lid = pose.lidDrop.clamp(0.0, 1.0);
    if (pose.eyeOpen < 0.12 || lid > 0.88) {
      _drawClosedEyeLine(canvas, r);
      canvas.restore();
      return;
    }

    final outline = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18;

    canvas.drawCircle(Offset.zero, r, Paint()..color = Colors.white);
    canvas.drawCircle(Offset.zero, r, outline);
    canvas.drawCircle(Offset.zero, r * 0.62, Paint()..color = _outline);
    canvas.drawCircle(
      Offset(-r * 0.22, -r * 0.28),
      r * 0.18,
      Paint()..color = Colors.white,
    );
    if (pose.sparkle > 0.4) {
      canvas.drawCircle(
        Offset(r * 0.28, r * 0.12),
        r * 0.1,
        Paint()..color = Colors.white,
      );
    }

    if (lid > 0.02) {
      final y = (-r + 2 * r * lid).clamp(-r * 0.92, r * 0.72);
      final halfW = math.sqrt(math.max(r * r * 0.04, r * r - y * y));
      final droop = r * (0.1 + 0.2 * lid);

      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
      final lidPath = Path()
        ..moveTo(-r, -r)
        ..lineTo(r, -r)
        ..lineTo(r, y)
        ..lineTo(halfW, y)
        ..quadraticBezierTo(0, y + droop, -halfW, y)
        ..lineTo(-r, y)
        ..close();
      canvas.drawPath(lidPath, Paint()..color = _skin);
      canvas.restore();

      canvas.drawPath(
        Path()
          ..moveTo(-halfW, y)
          ..quadraticBezierTo(0, y + droop, halfW, y),
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(Offset.zero, r, outline);
    }
    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.35)
      ..cubicTo(
        center.dx - size,
        center.dy - size * 0.35,
        center.dx - size * 0.45,
        center.dy - size,
        center.dx,
        center.dy - size * 0.25,
      )
      ..cubicTo(
        center.dx + size * 0.45,
        center.dy - size,
        center.dx + size,
        center.dy - size * 0.35,
        center.dx,
        center.dy + size * 0.35,
      );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.12,
    );
  }

  void _fillStrokeCircle(
    Canvas canvas,
    Offset c,
    double r,
    Color fill,
    double stroke,
  ) {
    canvas.drawCircle(c, r, Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  void _fillStrokeRRect(Canvas canvas, RRect rrect, Color fill, double stroke) {
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  void _fillStrokePath(Canvas canvas, Path path, Color fill, double stroke) {
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PuppetPainter old) => true;
}
