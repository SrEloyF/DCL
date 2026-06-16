import 'package:flutter/material.dart';

class SpherePainter extends CustomPainter {
  SpherePainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.purple.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = selected ? Colors.orange : Colors.purple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    canvas.drawOval(rect, fillPaint);
    canvas.drawOval(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SpherePainter oldDelegate) {
    return oldDelegate.selected != selected;
  }
}
