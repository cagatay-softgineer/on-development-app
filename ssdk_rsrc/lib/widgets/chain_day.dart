// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/widgets/glowing_overlapping_circles.dart';
import 'package:ssdk_rsrc/widgets/skeleton_provider.dart';

class ChainDayWidget extends StatelessWidget {
  final bool completed;
  final bool isToday;
  final bool connectLeft;
  final bool connectRight;
  final int? dayNumber;

  const ChainDayWidget({
    super.key,
    required this.completed,
    this.connectLeft = false,
    this.connectRight = false,
    this.dayNumber,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    // You can use a Stack to overlay connectors or a CustomPainter for more advanced effects.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Left connector
        // if (connectLeft)
        //   Align(
        //     alignment: Alignment.centerLeft,
        //     child: Container(
        //       width: 20,
        //       height: 28,
        //       color:
        //           completed
        //               ? ColorPalette.gold.withOpacity(1)
        //               : Colors.transparent,
        //     ),
        //   ),
        // // Right connector
        // if (connectRight)
        //   Align(
        //     alignment: Alignment.centerRight,
        //     child:
        //     Container(
        //       width: 20,
        //       height: 50,
        //       color:
        //           completed
        //               ? ColorPalette.gold.withOpacity(1)
        //               : Colors.transparent,
        //     ),
        //   ),
        if (connectRight)
          Align(
            alignment: Alignment.centerRight,
            child: SingleChainIcon(size: 20),
          ),

        if (connectRight)
          Positioned(
            top: 14,
            right: -18,
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChainIcon(size: 24),
            ),
          ),

        if (connectLeft)
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChainIcon(size: 20),
          ),
        // Chain Link
        Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  completed
                      ? isToday
                          ? ColorPalette
                              .white //ColorPalette.backgroundColor
                          : ColorPalette
                              .backgroundColor //ColorPalette.backgroundColor
                      : ColorPalette.lightGray.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: completed ? ColorPalette.white : Colors.white24,
                width: 2,
              ),
              boxShadow:
                  isToday
                      ? [
                        BoxShadow(
                          color: ColorPalette.gold.withOpacity(0.9),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                      : completed
                      ? [
                        BoxShadow(
                          color: ColorPalette.gold.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: Center(
              child:
                  dayNumber == null
                      ? const SizedBox()
                      : Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color:
                              completed
                                  ? isToday
                                      ? ColorPalette.almostBlack
                                      : ColorPalette.white
                                  : ColorPalette.white.withAlpha(120),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChainDaySkeletonWidget extends StatelessWidget {
  final bool connectLeft;
  final bool connectRight;
  final bool highlight; // "completed" look or not

  const ChainDaySkeletonWidget({
    super.key,
    this.connectLeft = false,
    this.connectRight = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final prov = SkeletonProvider.of(context);

    final chainGlow = BoxShadow(
      color: prov.highlightColor.withOpacity(highlight ? 0.7 : 0.22),
      blurRadius: highlight ? 18 : 8,
      spreadRadius: highlight ? 3 : 1,
    );

    return Stack(
      children: [
        // Left connection bar
        if (connectLeft)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: prov.highlightColor.withOpacity(highlight ? 0.7 : 0.22),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [chainGlow],
              ),
            ),
          ),
        // Right connection bar
        if (connectRight)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: prov.highlightColor.withOpacity(highlight ? 0.7 : 0.22),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [chainGlow],
              ),
            ),
          ),
        // Chain part (glowing rounded square)
        Center(
          child: Shimmer.fromColors(
            baseColor: prov.baseColor,
            highlightColor: prov.highlightColor,
            period: prov.period,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: prov.baseColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: prov.highlightColor.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [chainGlow],
              ),
              child: Center(
                child: Icon(
                  Icons.lock_outline,
                  color:
                      highlight
                          ? prov.highlightColor.withOpacity(0.9)
                          : prov.baseColor.withOpacity(0.4),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
