import 'package:flutter/material.dart';

class PersonPainter extends CustomPainter {
  final Color topColor;
  final Color bottomColor;
  final bool isBunny;
  final bool isSleeping;
  final bool isLove;
  final bool isHappy;
  final bool isSad;
  final bool isAngry;
  final double mouthOpenAmount; // 0.0 to 1.0

  PersonPainter({
    required this.topColor,
    required this.bottomColor,
    this.isBunny = false,
    this.isSleeping = false,
    this.isLove = false,
    this.isHappy = false,
    this.isSad = false,
    this.isAngry = false,
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
      // Draw normal eyes (slightly tighter when angry)
      final double eyeRadius = headRadius * (isAngry ? 0.09 : 0.12);
      canvas.drawCircle(Offset(headCenter.dx - eyeXOffset, eyeY), eyeRadius, paint);
      canvas.drawCircle(Offset(headCenter.dx + eyeXOffset, eyeY), eyeRadius, paint);
    }

    if (isAngry && !isSleeping && !isLove) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;
      paint.strokeCap = StrokeCap.round;
      paint.color = Colors.black;
      final double browLift = headRadius * 0.28;
      canvas.drawLine(
        Offset(headCenter.dx - eyeXOffset - headRadius * 0.22, eyeY - browLift),
        Offset(headCenter.dx - eyeXOffset + headRadius * 0.12, eyeY - headRadius * 0.08),
        paint,
      );
      canvas.drawLine(
        Offset(headCenter.dx + eyeXOffset + headRadius * 0.22, eyeY - browLift),
        Offset(headCenter.dx + eyeXOffset - headRadius * 0.12, eyeY - headRadius * 0.08),
        paint,
      );
      paint.style = PaintingStyle.fill;

      paint.color = const Color(0xFFF87171).withValues(alpha: 0.45);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx - headRadius * 0.62, headCenter.dy + headRadius * 0.18),
          width: headRadius * 0.28,
          height: headRadius * 0.16,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx + headRadius * 0.62, headCenter.dy + headRadius * 0.18),
          width: headRadius * 0.28,
          height: headRadius * 0.16,
        ),
        paint,
      );
      paint.color = Colors.black;
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
    } else if (isAngry) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;
      paint.strokeCap = StrokeCap.round;
      final double mouthWidth = headRadius * 0.22;
      canvas.drawLine(
        Offset(headCenter.dx - mouthWidth, mouthY + headRadius * 0.04),
        Offset(headCenter.dx + mouthWidth, mouthY + headRadius * 0.04),
        paint,
      );
      canvas.drawLine(
        Offset(headCenter.dx - mouthWidth * 0.35, mouthY - headRadius * 0.02),
        Offset(headCenter.dx - mouthWidth * 0.35, mouthY + headRadius * 0.1),
        paint,
      );
      canvas.drawLine(
        Offset(headCenter.dx + mouthWidth * 0.35, mouthY - headRadius * 0.02),
        Offset(headCenter.dx + mouthWidth * 0.35, mouthY + headRadius * 0.1),
        paint,
      );
      paint.style = PaintingStyle.fill;
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
           oldDelegate.isAngry != isAngry ||
           oldDelegate.mouthOpenAmount != mouthOpenAmount;
  }
}
