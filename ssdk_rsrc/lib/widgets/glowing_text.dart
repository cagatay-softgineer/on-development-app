// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class GlowingText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;
  final Color color;
  final Color glowColor;

  const GlowingText({
    super.key,
    required this.text,
    this.fontSize = 38,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'Montserrat',
    required this.color,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: fontFamily,
        color: color,
        shadows: [
          Shadow(
            blurRadius: 20, // Bigger for stronger glow
            color: glowColor.withOpacity(0.95), // Strong yellow
            offset: Offset(0, 0),
          ),
          Shadow(
            blurRadius: 40, // Extra big for soft, outer glow
            color: glowColor.withOpacity(0.75),
            offset: Offset(0, 0),
          ),
          Shadow(
            blurRadius: 80, // Super wide for faded glow
            color: glowColor.withOpacity(0.4),
            offset: Offset(0, 0),
          ),
        ],
      ),
    );
  }
}
