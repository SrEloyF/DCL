import 'dart:ui';

class CameraModel {
  const CameraModel({
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  final double scale;
  final Offset offset;

  CameraModel copyWith({
    double? scale,
    Offset? offset,
  }) {
    return CameraModel(
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
    );
  }

  Offset screenToWorld(Offset screenPoint) {
    return Offset(
      (screenPoint.dx - offset.dx) / scale,
      (screenPoint.dy - offset.dy) / scale,
    );
  }
}
