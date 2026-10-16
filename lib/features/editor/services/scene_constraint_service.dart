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
      candidateObject: object,
      candidateBounds: candidate,
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
      candidateObject: object,
      candidateBounds: candidateBounds,
      scene: scene,
      objects: objects,
      ignoreId: object.id,
    );
  }

  bool canRotate({
    required DiagramObject object,
    required double candidateAngle,
    required SceneModel scene,
    required List<DiagramObject> objects,
  }) {
    return isValidPlacement(
      candidateObject: object,
      candidateBounds: object.bounds,
      candidateAngle: candidateAngle,
      scene: scene,
      objects: objects,
      ignoreId: object.id,
    );
  }

  bool canFlip({
    required DiagramObject object,
    required bool candidateMirrored,
    required SceneModel scene,
    required List<DiagramObject> objects,
  }) {
    return isValidPlacement(
      candidateObject: object,
      candidateBounds: object.bounds,
      candidateMirrored: candidateMirrored,
      scene: scene,
      objects: objects,
      ignoreId: object.id,
    );
  }

  bool isValidPlacement({
    required DiagramObject candidateObject,
    required Rect candidateBounds,
    double? candidateAngle,
    bool? candidateMirrored,
    required SceneModel scene,
    required List<DiagramObject> objects,
    String? ignoreId,
  }) {
    final shape = getShapeFromObject(candidateObject, candidateBounds, candidateAngle, candidateMirrored);
    final actualBounds = getShapeBounds(shape);

    if (!_insideWorld(actualBounds, scene)) {
      return false;
    }

    if (!_aboveGround(actualBounds, scene)) {
      return false;
    }

    for (final other in objects) {
      if (other.id == ignoreId) continue;

      if (checkCollision(candidateObject, candidateBounds, other, other.bounds, candidateAngleA: candidateAngle, candidateMirroredA: candidateMirrored)) {
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