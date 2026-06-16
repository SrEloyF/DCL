import 'dart:math';
import 'dart:ui';

enum DiagramObjectType { block, ramp, sphere }

abstract class DiagramObject {
  DiagramObject({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.angle = 0.0,
  });

  final String id;
  final DiagramObjectType type;

  double x;
  double y;
  double width;
  double height;
  double angle;

  bool get canRotate;
  bool get canFlipX;

  Rect get bounds => Rect.fromLTWH(x, y, width, height);

  Offset get center => Offset(x + width / 2, y + height / 2);

  void move(double dx, double dy) {
    x += dx;
    y += dy;
  }

  void resize(double dx, double dy) {
    width = max(40.0, width + dx);
    height = max(40.0, height + dy);
  }

  void rotate(double deltaAngle) {
    if (!canRotate) return;
    angle += deltaAngle;
  }

  void flipX() {}

  bool containsWorldPoint(Offset point) => bounds.contains(point);
}
