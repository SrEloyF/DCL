import '../../models/diagram_object.dart';
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
  void resize(double dx, double dy) {
    final newRadius = (radius + (dx + dy) / 4).clamp(20.0, 1000.0);
    width = newRadius * 2;
    height = newRadius * 2;
  }
}
