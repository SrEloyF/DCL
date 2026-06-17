import 'dart:math';
import 'dart:ui';
import '../../../core/constants/scene_constants.dart';
import 'handle_model.dart';

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

  List<HandleModel> get handles;

  Rect get bounds => Rect.fromLTWH(x, y, width, height);

  Offset get center => Offset(x + width / 2, y + height / 2);

  void move(double dx, double dy) {
    x += dx;
    y += dy;
  }

  void applyBounds(Rect newBounds) {
    x = newBounds.left;
    y = newBounds.top;
    width = max(SceneConstants.objectMinSize, newBounds.width);
    height = max(SceneConstants.objectMinSize, newBounds.height);
  }

  Rect transformResize(HandleAnchor anchor, Offset delta) {
    double nextX = x;
    double nextY = y;
    double nextWidth = width;
    double nextHeight = height;

    switch (anchor) {
      case HandleAnchor.left:
        nextX += delta.dx;
        nextWidth -= delta.dx;
        break;
      case HandleAnchor.right:
        nextWidth += delta.dx;
        break;
      case HandleAnchor.top:
        nextY += delta.dy;
        nextHeight -= delta.dy;
        break;
      case HandleAnchor.bottom:
        nextHeight += delta.dy;
        break;
      default:
        break;
    }

    return Rect.fromLTWH(nextX, nextY, nextWidth, nextHeight);
  }

  void rotate(double deltaAngle) {
    if (!canRotate) return;
    angle += deltaAngle;
  }

  void flipX() {}

  bool containsWorldPoint(Offset point) => bounds.contains(point);
}
