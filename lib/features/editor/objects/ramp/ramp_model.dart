import '../../models/diagram_object.dart';
import '../../models/handle_model.dart';
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

  @override
  List<HandleModel> get handles => [
        const HandleModel(type: HandleType.resize, anchor: HandleAnchor.bottom),
        HandleModel(
          type: HandleType.resize,
          anchor: mirrored ? HandleAnchor.left : HandleAnchor.right,
        ),
        if (canFlipX)
          const HandleModel(type: HandleType.flip, anchor: HandleAnchor.topRight),
      ];
}
