import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GlowingLinkPoints extends StatelessWidget {
  final int points;
  const GlowingLinkPoints({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xFFFFE066); // Yellow glow

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          FontAwesomeIcons.circle,
          color: Colors.white,
          size: 38,
          shadows: [
            Shadow(blurRadius: 18, color: glowColor, offset: Offset(0, 0)),
            Shadow(blurRadius: 32, color: glowColor, offset: Offset(0, 0)),
          ],
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
