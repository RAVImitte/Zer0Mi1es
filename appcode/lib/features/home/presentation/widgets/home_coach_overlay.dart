import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radii.dart';

class CoachStep {
  const CoachStep({
    required this.key,
    required this.title,
    required this.body,
    this.radius = 20,
    this.padding = 8,
  });

  final GlobalKey key;
  final String title;
  final String body;
  final double radius;
  final double padding;
}

class HomeCoachOverlay extends StatefulWidget {
  const HomeCoachOverlay({
    super.key,
    required this.step,
    required this.steps,
    required this.onNext,
    required this.onSkip,
  });

  final int step;
  final List<CoachStep> steps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<HomeCoachOverlay> createState() => _HomeCoachOverlayState();
}

class _HomeCoachOverlayState extends State<HomeCoachOverlay>
    with TickerProviderStateMixin {
  static const _cardMaxWidth = 312.0;
  static const _screenPad = 20.0;
  static const _gap = 16.0;
  static const _caretSize = Size(22, 10);

  late final AnimationController _move;
  late final AnimationController _pulse;
  late final AnimationController _appear;
  late final Listenable _tick;

  Rect? _fromHole;
  Rect? _hole;
  Size _overlaySize = Size.zero;
  int _measureTries = 0;

  CoachStep get _current => widget.steps[widget.step];

  @override
  void initState() {
    super.initState();
    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _appear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _tick = Listenable.merge([_move, _pulse]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HomeCoachOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _fromHole = _hole;
      _measureTries = 0;
      _measure();
      _move.forward(from: 0);
    } else if (_hole == null) {
      _measure();
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _pulse.dispose();
    _appear.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) {
      _retryMeasure();
      return;
    }
    _overlaySize = overlayBox.size;
    final next = _rectFor(_current, overlayBox);
    if (next == null) {
      _retryMeasure();
      return;
    }
    _measureTries = 0;
    setState(() => _hole = next);
  }

  void _retryMeasure() {
    if (_measureTries >= 90) return;
    _measureTries++;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  Rect? _rectFor(CoachStep step, RenderBox overlayBox) {
    final ctx = step.key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    final overlayOrigin = overlayBox.localToGlobal(Offset.zero);
    final local = origin - overlayOrigin;
    return Rect.fromLTWH(
      local.dx,
      local.dy,
      box.size.width,
      box.size.height,
    ).inflate(step.padding);
  }

  Rect? _lerpHole(double t) {
    final to = _hole;
    if (to == null) return _fromHole;
    final from = _fromHole ?? to;
    return Rect.lerp(from, to, t);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _appear, curve: Curves.easeOut),
        child: AnimatedBuilder(
          animation: _tick,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_move.value);
            final hole = _lerpHole(t);
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) widget.onSkip();
              },
              child: Semantics(
                container: true,
                label: 'Home tour, step ${widget.step + 1} of ${widget.steps.length}',
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      hole: hole,
                      radius: _current.radius,
                      pulse: _pulse.value,
                    ),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: AbsorbPointer(child: SizedBox.expand()),
                        ),
                        if (hole != null)
                          Positioned.fromRect(
                            rect: hole.inflate(4),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.onNext();
                              },
                            ),
                          ),
                        if (hole != null) _tooltip(context, hole),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tooltip(BuildContext context, Rect hole) {
    final size = _overlaySize == Size.zero
        ? MediaQuery.sizeOf(context)
        : _overlaySize;
    final mq = MediaQuery.of(context);
    final safe = Rect.fromLTRB(
      math.max(_screenPad, mq.padding.left + 12),
      math.max(_screenPad, mq.padding.top + 8),
      size.width - math.max(_screenPad, mq.padding.right + 12),
      size.height - math.max(_screenPad, mq.padding.bottom + 8),
    );

    final width = math.min(_cardMaxWidth, safe.width);
    final spaceAbove = hole.top - safe.top;
    final spaceBelow = safe.bottom - hole.bottom;
    const minComfort = 148.0;
    final placeBelow = spaceBelow >= minComfort && spaceBelow >= spaceAbove ||
        spaceAbove < minComfort && spaceBelow > spaceAbove;

    var left = hole.center.dx - width / 2;
    left = left.clamp(safe.left, safe.right - width);

    final maxHeight = placeBelow
        ? math.max(0.0, safe.bottom - (hole.bottom + _gap))
        : math.max(0.0, hole.top - _gap - safe.top);

    var caretDx = hole.center.dx - left;
    caretDx = caretDx.clamp(28.0, width - 28.0);

    final card = _CoachCard(
      step: widget.step,
      total: widget.steps.length,
      title: _current.title,
      body: _current.body,
      caretOnTop: placeBelow,
      caretDx: caretDx,
      caretSize: _caretSize,
      onNext: () {
        HapticFeedback.selectionClick();
        widget.onNext();
      },
      onSkip: widget.onSkip,
    );

    return AnimatedPositioned(
      duration: AppMotion.slow,
      curve: Curves.easeInOutCubic,
      left: left,
      width: width,
      top: placeBelow ? hole.bottom + _gap : null,
      bottom: placeBelow ? null : size.height - hole.top + _gap,
      child: AnimatedSwitcher(
        duration: AppMotion.base,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, placeBelow ? 0.08 : -0.08),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(widget.step),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: math.max(maxHeight, 96)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  placeBelow ? Alignment.topCenter : Alignment.bottomCenter,
              child: SizedBox(width: width, child: card),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.step,
    required this.total,
    required this.title,
    required this.body,
    required this.caretOnTop,
    required this.caretDx,
    required this.caretSize,
    required this.onNext,
    required this.onSkip,
  });

  final int step;
  final int total;
  final String title;
  final String body;
  final bool caretOnTop;
  final double caretDx;
  final Size caretSize;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static const _cream = Color(0xFFF6F0E8);
  static const _ink = Color(0xFF2A1614);
  static const _muted = Color(0xFF5A4A44);

  @override
  Widget build(BuildContext context) {
    final last = step >= total - 1;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: caretOnTop ? caretSize.height - 1 : 0,
            bottom: caretOnTop ? 0 : caretSize.height - 1,
          ),
          child: Material(
            color: _cream,
            elevation: 16,
            shadowColor: Colors.black54,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: _ink,
                                height: 1.15,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${step + 1} / $total',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _ink.withValues(alpha: 0.42),
                                fontFeatures: const [ui.FontFeature.tabularFigures()],
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _muted,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < total; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        AnimatedContainer(
                          duration: AppMotion.fast,
                          width: i == step ? 16 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == step
                                ? AppColors.primary
                                : const Color(0x66C4A090),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!last)
                        TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: _ink.withValues(alpha: 0.48),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Skip'),
                        ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: onNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: _ink,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          minimumSize: const Size(0, 40),
                          elevation: 0,
                        ),
                        child: Text(last ? 'Got it' : 'Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: caretDx - caretSize.width / 2,
          top: caretOnTop ? 0 : null,
          bottom: caretOnTop ? null : 0,
          child: CustomPaint(
            size: caretSize,
            painter: _CaretPainter(pointUp: caretOnTop, color: _cream),
          ),
        ),
      ],
    );
  }
}

class _CaretPainter extends CustomPainter {
  _CaretPainter({required this.pointUp, required this.color});

  final bool pointUp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CaretPainter oldDelegate) =>
      oldDelegate.pointUp != pointUp || oldDelegate.color != color;
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.pulse,
  });

  final Rect? hole;
  final double radius;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0xD40A080A);
    if (hole == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }

    final rrect = RRect.fromRectAndRadius(
      hole!,
      Radius.circular(radius),
    );
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dim);

    final p = Curves.easeOut.transform(pulse);
    for (final ring in [
      (inflate: 6.0 + 14 * p, alpha: 0.42 * (1 - p), width: 2.4),
      (inflate: 14.0 + 18 * p, alpha: 0.18 * (1 - p), width: 1.4),
    ]) {
      canvas.drawRRect(
        rrect.inflate(ring.inflate),
        Paint()
          ..color = AppColors.primary.withValues(alpha: ring.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring.width,
      );
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xAAF6F0E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.radius != radius ||
      oldDelegate.pulse != pulse;
}
