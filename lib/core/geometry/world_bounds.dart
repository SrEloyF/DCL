import 'dart:ui';

class WorldBounds {
  const WorldBounds({
    required this.width,
    required this.height,
    required this.groundY,
  });

  final double width;
  final double height;
  final double groundY;

  Rect get rect => Rect.fromLTWH(0, 0, width, height);
}
