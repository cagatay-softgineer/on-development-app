// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/widgets/glowing_overlapping_circles.dart';

class ChainStepProgress extends StatelessWidget {
  final int steps;
  final double iconSize;
  final int activeStep;

  const ChainStepProgress({
    super.key,
    this.steps = 5,
    this.iconSize = 38,
    this.activeStep = 1,
  });

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xFFFFE066);
    // Overlap factor: 0.64 * iconSize to look like your screenshot
    final overlap = iconSize * 0.64;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.black.withOpacity(0.18),
        height: iconSize + 12,
        width:
            iconSize + (steps - 1) * overlap + 24, // 24 for container padding
        child: Stack(
          alignment: Alignment.centerLeft,
          children: List.generate(steps, (i) {
            final isActive = i == 0;
            return Positioned(
              left: i * overlap + 12, // +12 for left container padding
              child: Icon(
                Icons.link,
                size: iconSize,
                color: isActive ? Colors.white : Colors.transparent,
                shadows:
                    isActive
                        ? [
                          Shadow(
                            blurRadius: 16,
                            color: glowColor.withOpacity(0.85),
                            offset: Offset(0, 0),
                          ),
                          Shadow(
                            blurRadius: 36,
                            color: glowColor.withOpacity(0.44),
                            offset: Offset(0, 0),
                          ),
                        ]
                        : [
                          Shadow(
                            blurRadius: 18,
                            color: glowColor.withOpacity(0.44),
                            offset: Offset(0, 0),
                          ),
                          Shadow(
                            blurRadius: 36,
                            color: glowColor.withOpacity(0.15),
                            offset: Offset(0, 0),
                          ),
                        ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class CustomChainStepProgress extends StatelessWidget {
  final int steps;
  final int activeStep; // Which chain to "glow" (1-based)
  final double size;
  final double iconSize;
  const CustomChainStepProgress({
    super.key,
    this.steps = 5,
    this.activeStep = 1,
    this.size = 40,
    this.iconSize = 38,
  });

  @override
  Widget build(BuildContext context) {
    final sized = (iconSize / 5 + size);
    final overlap = sized * 0.64;

    return SizedBox(
      width: sized + (steps) * overlap,
      height: sized + 50,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: List.generate(steps, (i) {
          final isActive = i + 1 <= activeStep; // or: i + 1 == activeStep;
          return Positioned(
            left: i * overlap,
            child: Opacity(
              opacity: isActive ? 1.0 : 0.22, // Dim inactive chains
              child: SingleChainIcon(size: iconSize),
            ),
          );
        }),
      ),
    );
  }
}
