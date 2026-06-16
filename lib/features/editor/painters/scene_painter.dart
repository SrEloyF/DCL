import 'package:flutter/material.dart';

class ScenePainter extends CustomPainter {
  ScenePainter({
    required this.worldSize,
    required this.groundY,
    required this.gridStep,
  });

  final Size worldSize;
  final double groundY;
  final double gridStep;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.grey.shade100;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.18)
      ..strokeWidth = 1;

    for (double x = 0; x <= worldSize.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, worldSize.height), gridPaint);
    }

    for (double y = 0; y <= worldSize.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(worldSize.width, y), gridPaint);
    }

    final groundFillPaint = Paint()
      ..color = Colors.brown.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, groundY, worldSize.width, worldSize.height - groundY),
      groundFillPaint,
    );

    final groundLinePaint = Paint()
      ..color = Colors.brown.withOpacity(0.68)
      ..strokeWidth = 4;

    canvas.drawLine(
      Offset(0, groundY),
      Offset(worldSize.width, groundY),
      groundLinePaint,
    );

    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'SUELO',
        style: TextStyle(
          color: Colors.brown.withOpacity(0.85),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    )..layout();

    labelPainter.paint(canvas, const Offset(16, 16));
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) {
    return oldDelegate.worldSize != worldSize ||
        oldDelegate.groundY != groundY ||
        oldDelegate.gridStep != gridStep;
  }
}
