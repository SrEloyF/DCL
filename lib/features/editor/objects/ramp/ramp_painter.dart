import 'package:flutter/material.dart';

class RampPainter extends CustomPainter {
  RampPainter({
    required this.mirrored,
    required this.selected,
  });

  final bool mirrored;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = selected ? Colors.orange : Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (!mirrored) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, 0);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height);
    }

    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant RampPainter oldDelegate) {
    return oldDelegate.mirrored != mirrored || oldDelegate.selected != selected;
  }
}
