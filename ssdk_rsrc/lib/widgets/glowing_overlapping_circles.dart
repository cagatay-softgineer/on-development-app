// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class GlowingOverlappingCircles extends StatelessWidget {
  final int points;
  const GlowingOverlappingCircles({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xFFFFE066);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 38,
          width: 48,
          child: CustomPaint(
            painter: _CirclesOverlapPainter(glowColor),
          ),
        ),
        SizedBox(height: 2),
        Text(
          points.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 12, color: glowColor, offset: Offset(0, 0)),
              Shadow(blurRadius: 24, color: glowColor, offset: Offset(0, 0)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CirclesOverlapPainter extends CustomPainter {
  final Color glowColor;

  _CirclesOverlapPainter(this.glowColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGlow = Paint()
      ..color = glowColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7);

    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw left circle (glow)
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.55), 13, paintGlow);
    // Draw right circle (glow)
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.55), 13, paintGlow);

    // Draw left circle (white)
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.55), 13, paintWhite);
    // Draw right circle (white)
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.55), 13, paintWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SingleChainIcon extends StatelessWidget {
  final bool active;
  final double size;

  const SingleChainIcon({
    super.key,
    this.active = true,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = Color(0xFFFFE066);
    return SizedBox(
      height: size,
      width: size * 1.25, // controls width of the pair
      child: CustomPaint(
        painter: _CircleOverlapPainter(
          glowColor: glowColor,
          active: active,
        ),
      ),
    );
  }
}

class _CircleOverlapPainter extends CustomPainter {
  final Color glowColor;
  final bool active;

  _CircleOverlapPainter({required this.glowColor, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.height * 0.42;
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);

    final paintGlow = Paint()
      ..color = glowColor.withOpacity(active ? 0.85 : 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 4 : 3
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7);

    final paintStroke = Paint()
      ..color = active ? Colors.white : glowColor.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 2 : 1.2;

    // Glow
    canvas.drawCircle(center, radius, paintGlow);

    // Outline
    canvas.drawCircle(center, radius, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}