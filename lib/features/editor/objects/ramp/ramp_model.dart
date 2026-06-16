import '../../models/diagram_object.dart';
import 'ramp_constraints.dart';

class RampModel extends DiagramObject {
  RampModel({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
  }) : super(type: DiagramObjectType.ramp);

  bool mirrored = false;

  @override
  bool get canRotate => RampConstraints.canRotate;

  @override
  bool get canFlipX => RampConstraints.canFlipX;

  @override
  void flipX() {
    mirrored = !mirrored;
  }
}
