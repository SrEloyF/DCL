import 'dart:ui';

import '../../../core/geometry/scene_collision.dart';
import '../models/diagram_object.dart';
import '../models/scene_model.dart';

class SceneConstraintService {
  const SceneConstraintService();

  bool canMove({
    required DiagramObject object,
    required Offset nextPosition,
    required SceneModel scene,
    required List<DiagramObject> objects,
  }) {
    final candidate = Rect.fromLTWH(
      nextPosition.dx,
      nextPosition.dy,
      object.width,
      object.height,
    );

    return isValidPlacement(
      candidate: candidate,
      scene: scene,
      objects: objects,
      ignoreId: object.id,
    );
  }

  bool canResize({
    required DiagramObject object,
    required Rect candidateBounds,
    required SceneModel scene,
    required List<DiagramObject> objects,
  }) {
    return isValidPlacement(
      candidate: candidateBounds,
      scene: scene,
      objects: objects,
      ignoreId: object.id,
    );
  }

  bool isValidPlacement({
    required Rect candidate,
    required SceneModel scene,
    required List<DiagramObject> objects,
    String? ignoreId,
  }) {
    if (!_insideWorld(candidate, scene)) {
      return false;
    }

    if (!_aboveGround(candidate, scene)) {
      return false;
    }

    for (final other in objects) {
      if (other.id == ignoreId) continue;

      if (overlaps(candidate, other.bounds)) {
        return false;
      }
    }

    return true;
  }

  bool _insideWorld(Rect rect, SceneModel scene) {
    return rect.left >= 0 &&
        rect.top >= 0 &&
        rect.right <= scene.worldSize.width &&
        rect.bottom <= scene.worldSize.height;
  }

  bool _aboveGround(Rect rect, SceneModel scene) {
    return rect.bottom <= scene.groundY;
  }
}