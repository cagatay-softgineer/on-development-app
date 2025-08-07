import 'package:flutter/material.dart';

class GlowingIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color iconGlowColor;
  const GlowingIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconSize = 28,
    required this.iconColor,
    required this.iconGlowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: iconSize,
                shadows: [
                  Shadow(
                    blurRadius: 18,
                    color: iconGlowColor,
                    offset: Offset(0, 0),
                  ),
                  Shadow(
                    blurRadius: 32,
                    color: iconGlowColor,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
