import 'package:flutter/material.dart';

abstract class DiagramObject {
  double x;
  double y;

  double width;
  double height;

  double angle;

  DiagramObject({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.angle = 0,
  });

  bool get canRotate;

  bool get canFlipX;

  void move(double dx, double dy) {
    x += dx;
    y += dy;
  }

  void resize(double dx, double dy) {
    width = (width + dx).clamp(50, 1000);
    height = (height + dy).clamp(50, 1000);
  }

  void rotate(double deltaAngle) {
    if (!canRotate) return;

    angle += deltaAngle;
  }

  void flipX() {}

  Widget render({
    required bool selected,
  });
}