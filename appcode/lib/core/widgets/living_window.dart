import 'dart:math' as math;

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

class LivingWindow extends ConsumerStatefulWidget {
  const LivingWindow({
    super.key,
    required this.scene,
    required this.child,
    this.sleeping = false,
    this.unpaired = false,
    this.onTap,
    this.onLongPress,
    this.rimColor,
  });

  final PartnerScene scene;
  final Widget child;
  final bool sleeping;
  final bool unpaired;
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
    final enabled = TickerMode.of(context) &&
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

    final asset = sceneAsset(widget.scene, unpaired: widget.unpaired);
    final rim = widget.rimColor ?? AppColors.primary;
    final reduce = MediaQuery.disableAnimationsOf(context);

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
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(w * 0.5),
                  bottom: const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: rim.withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipPath(
                clipper: const _WindowClipper(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                      child: Transform.scale(
                        scale: 1.18,
                        alignment: Alignment.topCenter,
                        child: Image.asset(
                          asset,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: sceneWash(widget.scene).first,
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x66141014),
                              ],
                              stops: [0.72, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!reduce && !widget.unpaired)
                      CustomPaint(
                        painter: _AtmospherePainter(
                          scene: widget.scene,
                          time: _time,
                        ),
                      ),
                    IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        color: widget.sleeping
                            ? Colors.black.withValues(alpha: 0.42)
                            : Colors.transparent,
                      ),
                    ),
                    if (widget.sleeping)
                      const Align(
                        alignment: Alignment.topCenter,
                        child: FractionallySizedBox(
                          heightFactor: 0.22,
                          widthFactor: 1,
                          child: ColoredBox(color: Color(0xCC120E12)),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 6,
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WindowClipper extends CustomClipper<Path> {
  const _WindowClipper();

  @override
  Path getClip(Size size) {
    final radius = math.min(size.width * 0.5, size.height * 0.35);
    return Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Offset.zero & size,
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
      );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter({required this.scene, required this.time});

  final PartnerScene scene;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
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
    for (var i = 0; i < 18; i++) {
      final seed = i * 17.3;
      final x = (math.sin(seed) * 0.5 + 0.5) * size.width;
      final y = (math.cos(seed * 1.3) * 0.5 + 0.5) * size.height * 0.45;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(time * 1.4 + seed));
      paint.color = Colors.white.withValues(alpha: twinkle);
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * 0.4, paint);
    }
  }

  void _clouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (var i = 0; i < 3; i++) {
      final x = ((time * 8 + i * 90) % (size.width + 80)) - 40;
      final y = size.height * (0.16 + i * 0.07);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 70, height: 18),
        paint,
      );
    }
  }

  void _motes(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 12; i++) {
      final seed = i * 11.0;
      final x = (math.sin(time * 0.3 + seed) * 0.5 + 0.5) * size.width;
      final y = (size.height * 0.7 -
              ((time * 12 + seed * 20) % (size.height * 0.6)))
          .clamp(0, size.height);
      paint.color = const Color(0xFFE0B56A).withValues(alpha: 0.22);
      canvas.drawCircle(Offset(x, y.toDouble()), 1.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.scene != scene;
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
      padding: const EdgeInsets.only(top: 8, bottom: 2),
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