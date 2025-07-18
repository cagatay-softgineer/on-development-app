import 'dart:math';
import 'package:flutter/material.dart';

class PieTimeSelector extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const PieTimeSelector({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PieTimeSelectorState createState() => _PieTimeSelectorState();
}

class _PieTimeSelectorState extends State<PieTimeSelector> {
  double get angle =>
      ((widget.value - widget.min) / (widget.max - widget.min)) * 2 * pi;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset center = renderBox.size.center(Offset.zero);
        final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
        final double dx = localPosition.dx - center.dx;
        final double dy = localPosition.dy - center.dy;
        double theta = atan2(dy, dx);
        if (theta < 0) theta += 2 * pi;
        int newValue = (widget.min + (theta / (2 * pi)) * (widget.max - widget.min)).round();
        newValue = newValue.clamp(widget.min, widget.max);
        widget.onChanged(newValue);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _PieTimePainter(angle: angle),
              child: Center(
                child: Text(
                  '${widget.value}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieTimePainter extends CustomPainter {
  final double angle;
  _PieTimePainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 10;
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width / 2) - strokeWidth;
    final Paint basePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, basePaint);

    final Paint progressPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, angle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _PieTimePainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
