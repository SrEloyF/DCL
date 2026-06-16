import 'package:flutter/material.dart';

class BlockPainter extends CustomPainter {
  BlockPainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = selected ? Colors.orange : Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant BlockPainter oldDelegate) {
    return oldDelegate.selected != selected;
  }
}
