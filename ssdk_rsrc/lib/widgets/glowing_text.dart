import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';

class GlowingText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;

  const GlowingText({
    super.key,
    required this.text,
    this.fontSize = 38,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'Montserrat',
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: fontFamily,
        color: ColorPalette.white,
        shadows: [
          Shadow(
            blurRadius: 20, // Bigger for stronger glow
            color: ColorPalette.gold.withOpacity(0.95), // Strong yellow
            offset: Offset(0, 0),
          ),
          Shadow(
            blurRadius: 40, // Extra big for soft, outer glow
            color: ColorPalette.gold.withOpacity(0.75),
            offset: Offset(0, 0),
          ),
          Shadow(
            blurRadius: 80, // Super wide for faded glow
            color: ColorPalette.gold.withOpacity(0.4),
            offset: Offset(0, 0),
          ),
        ],
      ),
    );
  }
}