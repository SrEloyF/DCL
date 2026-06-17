import 'dart:math';
import 'dart:ui';
import '../../models/diagram_object.dart';
import '../../models/handle_model.dart';
import 'sphere_constraints.dart';

class SphereModel extends DiagramObject {
  SphereModel({
    required super.id,
    required super.x,
    required super.y,
    required double radius,
  })  : super(
          type: DiagramObjectType.sphere,
          width: radius * 2,
          height: radius * 2,
        );

  @override
  bool get canRotate => SphereConstraints.canRotate;

  @override
  bool get canFlipX => SphereConstraints.canFlipX;

  double get radius => width / 2;

  @override
  List<HandleModel> get handles => [
        const HandleModel(type: HandleType.resize, anchor: HandleAnchor.right),
      ];

  @override
  void applyBounds(Rect newBounds) {
    // Ensure the sphere stays square based on the largest dimension
    final size = max(newBounds.width, newBounds.height);
    super.applyBounds(Rect.fromLTWH(newBounds.left, newBounds.top, size, size));
  }

  @override
  Rect transformResize(HandleAnchor anchor, Offset delta) {
    // For spheres, we only support uniform resizing from the 'right' handle as per requirements
    // but InteractionCalculator will interpret this to maintain aspect ratio.
    // However, we can also handle it here for extra safety.
    final change = delta.dx + delta.dy;
    final nextSize = max(40.0, width + change);
    return Rect.fromLTWH(x, y, nextSize, nextSize);
  }
}
