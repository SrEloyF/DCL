import '../../models/diagram_object.dart';
import 'block_constraints.dart';

class BlockModel extends DiagramObject {
  BlockModel({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
  }) : super(type: DiagramObjectType.block);

  @override
  bool get canRotate => BlockConstraints.canRotate;

  @override
  bool get canFlipX => BlockConstraints.canFlipX;
}
