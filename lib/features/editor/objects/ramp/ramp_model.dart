import 'package:flutter/material.dart';
import '../../models/diagram_object.dart';

class RampModel extends DiagramObject {
  bool mirrored = false;

  RampModel({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
  });

  @override
  bool get canRotate => false;

  @override
  bool get canFlipX => true;

  @override
  void flipX() {
    mirrored = !mirrored;
  }

  @override
  Widget render({
    required bool selected,
  }) {
    return CustomPaint(
      painter: RampPainter(
        mirrored: mirrored,
        selected: selected,
      ),
      size: Size(width, height),
    );
  }
}

class RampPainter extends CustomPainter {
  final bool mirrored;
  final bool selected;

  RampPainter({
    required this.mirrored,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(.25);

    final border = Paint()
      ..color = selected
          ? Colors.orange
          : Colors.green
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

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}