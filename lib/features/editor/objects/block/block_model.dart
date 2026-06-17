import '../../models/diagram_object.dart';
import '../../models/handle_model.dart';
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

  @override
  List<HandleModel> get handles => [
        const HandleModel(type: HandleType.resize, anchor: HandleAnchor.top),
        const HandleModel(type: HandleType.resize, anchor: HandleAnchor.bottom),
        const HandleModel(type: HandleType.resize, anchor: HandleAnchor.left),
        const HandleModel(type: HandleType.resize, anchor: HandleAnchor.right),
        if (canRotate)
          const HandleModel(type: HandleType.rotate, anchor: HandleAnchor.topCenter),
      ];
}
