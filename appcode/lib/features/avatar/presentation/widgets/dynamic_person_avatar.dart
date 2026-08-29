import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../avatar_view_model.dart';

class DynamicPersonAvatar extends StatefulWidget {
  final AnimationState state;
  final Color topColor;
  final Color bottomColor;
  final bool isBunny;
  final double size;

  const DynamicPersonAvatar({
    super.key,
    required this.state,
    required this.topColor,
    required this.bottomColor,
    this.isBunny = false,
    this.size = 150.0,
  });

  @override
  State<DynamicPersonAvatar> createState() => _DynamicPersonAvatarState();
}

class _DynamicPersonAvatarState extends State<DynamicPersonAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _talkController;

  @override
  void initState() {
    super.initState();
    _talkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _updateControllerState();
  }

  @override
  void didUpdateWidget(covariant DynamicPersonAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateControllerState();
    }
  }

  void _updateControllerState() {
    if (widget.state == AnimationState.talking) {
      _talkController.repeat(reverse: true);
    } else {
      _talkController.stop();
      _talkController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _talkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Determine states for the painter
    final bool isSleeping = widget.state == AnimationState.sleeping;
    final bool isLove = widget.state == AnimationState.reaction;
    final bool isHappy = widget.state == AnimationState.playing || widget.state == AnimationState.petting || widget.state == AnimationState.moodHappy || widget.state == AnimationState.moodExcited;
    final bool isSad = widget.state == AnimationState.moodSad || widget.state == AnimationState.moodDevastated || widget.state == AnimationState.moodTired;

    // 2. Build the base painted character
    Widget character = AnimatedBuilder(
      animation: _talkController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: PersonPainter(
            topColor: widget.topColor,
            bottomColor: widget.bottomColor,
            isBunny: widget.isBunny,
            isSleeping: isSleeping,
            isLove: isLove,
            isHappy: isHappy,
            isSad: isSad,
            mouthOpenAmount: _talkController.value,
          ),
        );
      }
    );

    // 3. Apply flutter_animate layers based on state
    Widget animatedCharacter = character;
    
    switch (widget.state) {
      case AnimationState.idle:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: -4, end: 4, duration: 2.seconds, curve: Curves.easeInOutSine)
          .scaleXY(begin: 1.0, end: 1.02, duration: 2.seconds, curve: Curves.easeInOutSine);
        break;
      case AnimationState.sleeping:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(begin: 0.95, end: 1.0, duration: 3.seconds, curve: Curves.easeInOut)
          .tint(color: Colors.indigo.withOpacity(0.3), duration: 500.ms); // dim slightly
        break;
      case AnimationState.reaction:
        animatedCharacter = character
          .animate()
          .scaleXY(begin: 0.8, end: 1.2, duration: 300.ms, curve: Curves.easeOutBack)
          .then()
          .shake(hz: 4, duration: 400.ms)
          .then()
          .scaleXY(begin: 1.2, end: 1.0, duration: 300.ms, curve: Curves.bounceOut);
        break;
      case AnimationState.talking:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shake(hz: 2, duration: 800.ms) // subtle head bobbing
          .moveY(begin: -2, end: 2, duration: 800.ms);
        break;
      case AnimationState.playing:
      case AnimationState.petting:
      case AnimationState.feeding:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .rotate(begin: -0.05, end: 0.05, duration: 600.ms, curve: Curves.easeInOut)
          .moveX(begin: -4, end: 4, duration: 600.ms, curve: Curves.easeInOut);
        break;
      case AnimationState.walking:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: -8, end: 0, duration: 300.ms, curve: Curves.bounceOut)
          .rotate(begin: -0.05, end: 0.05, duration: 600.ms);
        break;
      case AnimationState.moodHappy:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: -20, end: 0, duration: 250.ms, curve: Curves.easeOutBack) // Fast jumping
          .scaleXY(begin: 0.95, end: 1.1, duration: 250.ms);
        break;
      case AnimationState.moodSad:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 10, end: 15, duration: 3.seconds, curve: Curves.easeInOut) // Slumped down
          .tint(color: Colors.blueGrey.withOpacity(0.3), duration: 500.ms);
        break;
      case AnimationState.moodDevastated:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 15, end: 18, duration: 1.seconds) // Slumped very low
          .shake(hz: 8, duration: 1.seconds) // Shivering
          .tint(color: Colors.blueGrey.withOpacity(0.5), duration: 500.ms);
        break;
      case AnimationState.moodOverwhelmed:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .rotate(begin: -0.15, end: 0.15, duration: 300.ms, curve: Curves.easeInOut) // Wild swinging
          .scaleXY(begin: 0.9, end: 1.1, duration: 300.ms)
          .tint(color: Colors.redAccent.withOpacity(0.2));
        break;
      case AnimationState.moodExcited:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: -10, end: -15, duration: 300.ms, curve: Curves.easeOutBack) // Bouncing up
          .rotate(begin: -0.1, end: 0.1, duration: 400.ms) // Shaking with excitement
          .tint(color: Colors.yellowAccent.withOpacity(0.2));
        break;
      case AnimationState.moodTired:
        animatedCharacter = character
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 5, end: 8, duration: 4.seconds, curve: Curves.easeInOut) // Very slow, heavy bob
          .rotate(begin: 0.05, end: 0.1, duration: 4.seconds); // Slumped to one side
        break;
      default:
        animatedCharacter = character;
    }

    // 4. Overlay Particles
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        animatedCharacter,
        
        // Sleep Particles (Zzz)
        if (isSleeping)
          Positioned(
            top: widget.size * 0.1,
            right: widget.size * 0.1,
            child: const Text('Zzz', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 500.ms)
                .moveY(begin: 0, end: -30, duration: 2.seconds)
                .moveX(begin: 0, end: 10, duration: 2.seconds, curve: Curves.easeInOutSine)
                .fadeOut(delay: 1.seconds, duration: 1.seconds),
          ),
          
        // Love Particles (Hearts)
        if (isLove)
          Positioned(
            top: -10,
            child: const Row(
              children: [
                Text('💖', style: TextStyle(fontSize: 20)),
                SizedBox(width: 40),
                Text('💖', style: TextStyle(fontSize: 28)),
              ],
            )
            .animate()
            .fadeIn(duration: 200.ms)
            .moveY(begin: 20, end: -40, duration: 1.seconds, curve: Curves.easeOutQuad)
            .fadeOut(delay: 600.ms, duration: 400.ms),
          ),
          
        // Devastated Particles (Tears)
        if (widget.state == AnimationState.moodDevastated)
          Positioned(
            top: widget.size * 0.3,
            child: const Row(
              children: [
                Text('💧', style: TextStyle(fontSize: 16)),
                SizedBox(width: 50),
                Text('💧', style: TextStyle(fontSize: 16)),
              ],
            )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 200.ms)
            .moveY(begin: 0, end: 40, duration: 800.ms, curve: Curves.easeIn)
            .fadeOut(delay: 400.ms, duration: 400.ms),
          ),
      ],
    );
  }
}

class PersonPainter extends CustomPainter {
  final Color topColor;
  final Color bottomColor;
  final bool isBunny;
  final bool isSleeping;
  final bool isLove;
  final bool isHappy;
  final bool isSad;
  final double mouthOpenAmount; // 0.0 to 1.0

  PersonPainter({
    required this.topColor,
    required this.bottomColor,
    this.isBunny = false,
    this.isSleeping = false,
    this.isLove = false,
    this.isHappy = false,
    this.isSad = false,
    this.mouthOpenAmount = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    
    final Paint paint = Paint()..style = PaintingStyle.fill;
    
    // Proportions
    final double headRadius = width * 0.25;
    final Offset headCenter = Offset(width / 2, height * 0.3);
    
    final double bodyWidth = width * 0.45;
    final double bodyHeight = height * 0.35;
    final Rect bodyRect = Rect.fromCenter(
      center: Offset(width / 2, height * 0.65),
      width: bodyWidth,
      height: bodyHeight,
    );
    
    final double legWidth = width * 0.15;
    final double legHeight = height * 0.15;
    final double legSpacing = width * 0.05;

    // --- 1. BACK HAIR (drawn behind everything) ---
    paint.color = Colors.black; // Black hair
    if (isBunny) {
      // Long hair falling behind the body (stops above the legs)
      final RRect backHair = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          headCenter.dx - headRadius * 1.15, 
          headCenter.dy, 
          headRadius * 2.3, 
          headRadius * 2.0 // falls down to the waist, not the feet
        ),
        Radius.circular(headRadius * 0.5),
      );
      canvas.drawRRect(backHair, paint);
    }

    // --- 2. LEGS / SHOES ---
    paint.color = Colors.black; // Shoes are now always black
    final RRect leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(width / 2 - legSpacing - legWidth, height * 0.8, legWidth, legHeight),
      Radius.circular(legWidth / 2),
    );
    final RRect rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(width / 2 + legSpacing, height * 0.8, legWidth, legHeight),
      Radius.circular(legWidth / 2),
    );
    canvas.drawRRect(leftLeg, paint);
    canvas.drawRRect(rightLeg, paint);

    // --- 3. BODY/TORSO ---
    final RRect torso = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: Radius.circular(bodyWidth * 0.4),
      topRight: Radius.circular(bodyWidth * 0.4),
      bottomLeft: Radius.circular(bodyWidth * 0.1),
      bottomRight: Radius.circular(bodyWidth * 0.1),
    );
    
    // Draw entire torso in bottom color (pants/skirt)
    paint.color = bottomColor;
    canvas.drawRRect(torso, paint);

    // Draw top half in top color (shirt)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(bodyRect.left, bodyRect.top, bodyWidth, bodyHeight * 0.55));
    paint.color = topColor;
    canvas.drawRRect(torso, paint);
    canvas.restore();

    // --- 4. ARMS (Top Color, slightly darker/lighter) ---
    paint.color = _darken(topColor, 0.1);
    final double armWidth = width * 0.12;
    // Left Arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyRect.left - armWidth * 0.7, bodyRect.top + armWidth, armWidth, bodyHeight * 0.7),
        Radius.circular(armWidth / 2),
      ),
      paint,
    );
    // Right Arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyRect.right - armWidth * 0.3, bodyRect.top + armWidth, armWidth, bodyHeight * 0.7),
        Radius.circular(armWidth / 2),
      ),
      paint,
    );

    // --- 5. HEAD (Skin Tone) ---
    const Color skinColor = Color(0xFFFFDAB9); // Peach skin tone
    paint.color = skinColor;
    canvas.drawCircle(headCenter, headRadius, paint);
    
    // --- 6. FRONT HAIR (Bangs / Top) ---
    paint.color = Colors.black; // Black hair
    
    if (isBunny) {
      // Cute Top Bun
      canvas.drawCircle(
        Offset(headCenter.dx, headCenter.dy - headRadius * 0.9), 
        headRadius * 0.45, 
        paint
      );
      
      // Front Bangs (same spiky cuts as male avatar)
      final Path bangs = Path();
      bangs.moveTo(headCenter.dx - headRadius, headCenter.dy - headRadius * 0.2);
      bangs.arcToPoint(
        Offset(headCenter.dx + headRadius, headCenter.dy - headRadius * 0.2),
        radius: Radius.circular(headRadius),
        clockwise: true,
      );
      // Spiky bangs
      bangs.lineTo(headCenter.dx + headRadius * 0.8, headCenter.dy - headRadius * 0.5);
      bangs.lineTo(headCenter.dx + headRadius * 0.5, headCenter.dy - headRadius * 0.3);
      bangs.lineTo(headCenter.dx + headRadius * 0.2, headCenter.dy - headRadius * 0.6);
      bangs.lineTo(headCenter.dx - headRadius * 0.2, headCenter.dy - headRadius * 0.3);
      bangs.lineTo(headCenter.dx - headRadius * 0.6, headCenter.dy - headRadius * 0.5);
      bangs.close();
      canvas.drawPath(bangs, paint);
    } else {
      // Short hair for Bear (spiky / cropped)
      final Path hairPath = Path();
      hairPath.moveTo(headCenter.dx - headRadius, headCenter.dy - headRadius * 0.2);
      hairPath.arcToPoint(
        Offset(headCenter.dx + headRadius, headCenter.dy - headRadius * 0.2),
        radius: Radius.circular(headRadius),
        clockwise: true,
      );
      // Give it some spiky bangs
      hairPath.lineTo(headCenter.dx + headRadius * 0.8, headCenter.dy - headRadius * 0.5);
      hairPath.lineTo(headCenter.dx + headRadius * 0.5, headCenter.dy - headRadius * 0.3);
      hairPath.lineTo(headCenter.dx + headRadius * 0.2, headCenter.dy - headRadius * 0.6);
      hairPath.lineTo(headCenter.dx - headRadius * 0.2, headCenter.dy - headRadius * 0.3);
      hairPath.lineTo(headCenter.dx - headRadius * 0.6, headCenter.dy - headRadius * 0.5);
      hairPath.close();
      canvas.drawPath(hairPath, paint);
    }

    // --- EYES ---
    paint.color = Colors.black;
    final double eyeY = headCenter.dy - headRadius * 0.1;
    final double eyeXOffset = headRadius * 0.35;
    
    if (isLove) {
      // Draw Heart Eyes
      _drawHeart(canvas, Offset(headCenter.dx - eyeXOffset, eyeY), headRadius * 0.4, Colors.redAccent);
      _drawHeart(canvas, Offset(headCenter.dx + eyeXOffset, eyeY), headRadius * 0.4, Colors.redAccent);
    } else if (isSleeping) {
      // Draw closed eyes (lines)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;
      paint.strokeCap = StrokeCap.round;
      
      final double eyeWidth = headRadius * 0.25;
      
      // Left eye
      canvas.drawLine(
        Offset(headCenter.dx - eyeXOffset - eyeWidth/2, eyeY),
        Offset(headCenter.dx - eyeXOffset + eyeWidth/2, eyeY),
        paint,
      );
      // Right eye
      canvas.drawLine(
        Offset(headCenter.dx + eyeXOffset - eyeWidth/2, eyeY),
        Offset(headCenter.dx + eyeXOffset + eyeWidth/2, eyeY),
        paint,
      );
      paint.style = PaintingStyle.fill;
    } else {
      // Draw normal eyes
      final double eyeRadius = headRadius * 0.12;
      canvas.drawCircle(Offset(headCenter.dx - eyeXOffset, eyeY), eyeRadius, paint);
      canvas.drawCircle(Offset(headCenter.dx + eyeXOffset, eyeY), eyeRadius, paint);
    }

    // --- MOUTH ---
    final double mouthY = headCenter.dy + headRadius * 0.3;
    paint.color = Colors.black;
    
    if (mouthOpenAmount > 0) {
      // Talking (Open mouth 'O')
      final double mouthWidth = headRadius * 0.2;
      final double mouthHeight = headRadius * 0.1 + (headRadius * 0.3 * mouthOpenAmount);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(headCenter.dx, mouthY + mouthHeight/2), width: mouthWidth, height: mouthHeight),
        paint,
      );
    } else {
      // Smile or Sad curve
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;
      paint.strokeCap = StrokeCap.round;
      
      final double mouthWidth = headRadius * 0.3;
      final double curveHeight = isSad ? -headRadius * 0.15 : headRadius * 0.15; // smile or frown
      
      final Path mouthPath = Path();
      mouthPath.moveTo(headCenter.dx - mouthWidth/2, mouthY);
      mouthPath.quadraticBezierTo(
        headCenter.dx, mouthY + curveHeight, // control point
        headCenter.dx + mouthWidth/2, mouthY // end point
      );
      
      canvas.drawPath(mouthPath, paint);
      paint.style = PaintingStyle.fill;
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final Paint paint = Paint()..color = color..style = PaintingStyle.fill;
    final Path path = Path();
    
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size, center.dy - size * 0.5, 
      center.dx - size * 0.5, center.dy - size, 
      center.dx, center.dy - size * 0.2
    );
    path.cubicTo(
      center.dx + size * 0.5, center.dy - size, 
      center.dx + size, center.dy - size * 0.5, 
      center.dx, center.dy + size * 0.3
    );
    
    canvas.drawPath(path, paint);
  }

  Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  bool shouldRepaint(covariant PersonPainter oldDelegate) {
    return oldDelegate.topColor != topColor ||
           oldDelegate.bottomColor != bottomColor ||
           oldDelegate.isBunny != isBunny ||
           oldDelegate.isSleeping != isSleeping ||
           oldDelegate.isLove != isLove ||
           oldDelegate.isHappy != isHappy ||
           oldDelegate.isSad != isSad ||
           oldDelegate.mouthOpenAmount != mouthOpenAmount;
  }
}
