import 'package:flutter/material.dart';

class TriLongLogo extends StatelessWidget {
  final double height;
  final bool isHorizontal;
  final double spacing;

  const TriLongLogo({
    super.key,
    this.height = 80.0,
    this.isHorizontal = true,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: Size(height * 0.75, height),
            painter: DoubleLPainter(),
          ),
          SizedBox(width: spacing),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "TRÍ L",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: height * 0.38,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD4AF37), // Gold
                      letterSpacing: 0,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                      bottom: height * 0.02,
                      left: height * 0.005,
                      right: height * 0.005,
                    ),
                    child: CustomPaint(
                      size: Size(height * 0.32, height * 0.32),
                      painter: DragonOPainter(),
                    ),
                  ),
                  Text(
                    "NG",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: height * 0.38,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F2C59), // Navy Blue to match 'LAND'
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    " LAND",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: height * 0.38,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F2C59), // Navy Blue
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.03),
              Text(
                "KIÊN TẠO SỰ BỀN VỮNG",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: height * 0.12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F2C59), // Matches brand blue exactly
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: Size(height * 0.75, height),
            painter: DoubleLPainter(),
          ),
          SizedBox(height: spacing),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "TRÍ L",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: height * 0.28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD4AF37),
                  letterSpacing: 0,
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  bottom: height * 0.015,
                  left: height * 0.004,
                  right: height * 0.004,
                ),
                child: CustomPaint(
                  size: Size(height * 0.24, height * 0.24),
                  painter: DragonOPainter(),
                ),
              ),
              Text(
                "NG",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: height * 0.28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F2C59), // Navy Blue to match 'LAND'
                  letterSpacing: 0,
                ),
              ),
              Text(
                " LAND",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: height * 0.28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F2C59),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.04),
          Text(
            "KIÊN TẠO SỰ BỀN VỮNG",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: height * 0.09,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F2C59),
              letterSpacing: 2.0,
            ),
          ),
        ],
      );
    }
  }
}

class DoubleLPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Define Gold Gradient
    final Rect rect = Rect.fromLTWH(0, 0, width, height);
    final Gradient goldGradient = const LinearGradient(
      colors: [
        Color(0xFFF9D976), // Bright Gold
        Color(0xFFE5B53B), // Medium Gold
        Color(0xFFB8860B), // Dark Gold
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    final Paint goldPaint = Paint()
      ..shader = goldGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    // 1. Draw outer hollow L
    final Path outerPath = Path()
      ..moveTo(width * 0.12, height * 0.05)
      ..lineTo(width * 0.12, height * 0.85)
      ..lineTo(width * 0.22, height * 0.95)
      ..lineTo(width * 0.95, height * 0.95)
      ..lineTo(width * 0.83, height * 0.83)
      ..lineTo(width * 0.34, height * 0.83)
      ..lineTo(width * 0.24, height * 0.73)
      ..lineTo(width * 0.24, height * 0.17)
      ..close();
    canvas.drawPath(outerPath, goldPaint);

    // 2. Draw inner hollow L
    final Path innerPath = Path()
      ..moveTo(width * 0.38, height * 0.30)
      ..lineTo(width * 0.38, height * 0.65)
      ..lineTo(width * 0.48, height * 0.75)
      ..lineTo(width * 0.78, height * 0.75)
      ..lineTo(width * 0.68, height * 0.65)
      ..lineTo(width * 0.58, height * 0.65)
      ..lineTo(width * 0.48, height * 0.55)
      ..lineTo(width * 0.48, height * 0.40)
      ..close();
    canvas.drawPath(innerPath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DragonOPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.14
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final Gradient goldGradient = const LinearGradient(
      colors: [
        Color(0xFFF9D976),
        Color(0xFFE5B53B),
        Color(0xFFB8860B),
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );

    // Apply shader to the ring paint
    ringPaint.shader = goldGradient.createShader(rect);

    // Draw the main circle body (leaving the top-right open from -60 to 0 degrees)
    // 0 is right, 1.57 is bottom, 3.14 is left, 4.71 is top.
    // Let's start the arc at 0.2 radians (around 11 degrees) and sweep 5.2 radians (around 300 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: w * 0.38),
      0.3,
      5.2,
      false,
      ringPaint,
    );

    // Draw the dragon head at the top-right curving left and inward
    final Path dragonPath = Path();
    dragonPath.moveTo(w * 0.78, h * 0.48); // Connect to the right side of the circle arc

    // Outer curve of head going up and left
    dragonPath.quadraticBezierTo(w * 0.85, h * 0.15, w * 0.52, h * 0.12);
    // Horn / crest at the back of the head
    dragonPath.lineTo(w * 0.56, h * 0.02);
    dragonPath.lineTo(w * 0.46, h * 0.08);
    // Top head curve
    dragonPath.quadraticBezierTo(w * 0.32, h * 0.08, w * 0.26, h * 0.18);
    // Snout / Nose pointing left
    dragonPath.lineTo(w * 0.20, h * 0.22);
    // Open mouth / jaw
    dragonPath.lineTo(w * 0.28, h * 0.26);
    dragonPath.lineTo(w * 0.22, h * 0.30); // Lower jaw
    dragonPath.lineTo(w * 0.32, h * 0.33);
    // Inner curve going back to join the inner boundary of the circle
    dragonPath.quadraticBezierTo(w * 0.55, h * 0.33, w * 0.65, h * 0.46);
    dragonPath.close();

    final Paint fillPaint = Paint()
      ..shader = goldGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(dragonPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
