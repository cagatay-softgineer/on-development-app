import 'package:flutter/material.dart';
import 'package:pomodoro/resources/themes.dart';

class CustomCenterGlowTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    // This centers the track in the container vertically, and stretches horizontally
    final double trackHeight = 4.0;
    final double trackLeft = offset.dx + 4;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 8;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final Canvas canvas = context.canvas;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
    ).shift(offset);

    // Draw inactive (full) track - very thin, grayish
    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? ColorPalette.lightGray
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(2)),
      inactivePaint,
    );

    // Draw active (left of thumb) track - thin, white
    final double activeWidth = thumbCenter.dx - trackRect.left;
    if (activeWidth > 0) {
      final Rect activeRect = Rect.fromLTWH(
        trackRect.left,
        trackRect.top,
        activeWidth,
        trackRect.height,
      );
      final Paint activePaint = Paint()
        ..color = sliderTheme.activeTrackColor ?? ColorPalette.white
        ..strokeCap = StrokeCap.round;
      canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, Radius.circular(2)),
        activePaint,
      );
    }

    // Draw gold highlight in center (under thumb) - thick, short, horizontal gradient
    final double highlightWidth = 32.0; // wider for effect
    final double highlightHeight = trackRect.height * 1.5;
    final Rect highlightRect = Rect.fromCenter(
      center: thumbCenter,
      width: highlightWidth,
      height: highlightHeight,
    );

    final double inlightWidth = 32.0; // wider for effect
    final double inlightHeight = trackRect.height * 1.1;
    final Rect inlightRect = Rect.fromCenter(
      center: thumbCenter,
      width: inlightWidth,
      height: inlightHeight,
    );
    final Paint goldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
          ColorPalette.gold.withAlpha((255 * 0.44).toInt()),
        ],
        stops: [0.0, 0.15, 0.25,0.35, 0.5, 0.65, 0.75, 0.85,1.0],
      ).createShader(highlightRect);
    final Paint darkPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          ColorPalette.backgroundColor,
          ColorPalette.backgroundColor,
          ColorPalette.backgroundColor,
          ColorPalette.backgroundColor,
          ColorPalette.backgroundColor,
          ColorPalette.backgroundColor,
          ColorPalette.backgroundColor,
          ColorPalette.backgroundColor,
          ColorPalette.backgroundColor,
        ],
        stops: [0.0, 0.15, 0.25,0.35, 0.5, 0.65, 0.75, 0.85,1.0],
      ).createShader(highlightRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(4)),
      goldPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inlightRect, Radius.circular(4)),
      darkPaint,
    );
  }
}

class CustomGlowThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(10, 10);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = ColorPalette.backgroundColor.withAlpha(0);
    canvas.drawCircle(center, 6, paint); // Small, subtle thumb
  }
}