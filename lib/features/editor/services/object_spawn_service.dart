import 'dart:math';
import 'dart:ui';

import '../models/camera_model.dart';
import '../models/diagram_object.dart';
import '../models/scene_model.dart';
import 'scene_constraint_service.dart';

class ObjectSpawnService {
  static Offset findSpawnPosition({
    required Size viewportSize,
    required CameraModel camera,
    required DiagramObject object,
    required List<DiagramObject> objects,
    required SceneModel scene,
  }) {
    final objectSize = Size(object.width, object.height);
    // Step 1: Compute screen center
    final screenCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);

    // Step 2: Convert to world center
    final worldCenter = camera.screenToWorld(screenCenter);

    // Step 3: Spiral search
    const constraintService = SceneConstraintService();
    const maxSteps = 15;
    const distanceStep = 50.0;
    final angles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
        .map((a) => a * pi / 180)
        .toList();

    for (int step = 0; step < maxSteps; step++) {
      final distance = step * distanceStep;

      // For distance 0, we only check the center once
      if (distance == 0) {
        final candidate = Rect.fromCenter(
          center: worldCenter,
          width: objectSize.width,
          height: objectSize.height,
        );

        if (constraintService.isValidPlacement(
          candidateObject: object,
          candidateBounds: candidate,
          scene: scene,
          objects: objects,
        )) {
          return candidate.topLeft;
        }
        continue;
      }

      for (final angle in angles) {
        final candidateCenter = Offset(
          worldCenter.dx + distance * cos(angle),
          worldCenter.dy + distance * sin(angle),
        );

        final candidate = Rect.fromCenter(
          center: candidateCenter,
          width: objectSize.width,
          height: objectSize.height,
        );

        if (constraintService.isValidPlacement(
          candidateObject: object,
          candidateBounds: candidate,
          scene: scene,
          objects: objects,
        )) {
          return candidate.topLeft;
        }
      }
    }

    // Fallback: Return original center clamped to world bounds
    final fallbackX = (worldCenter.dx - objectSize.width / 2)
        .clamp(0.0, scene.worldSize.width - objectSize.width);
    final fallbackY = (worldCenter.dy - objectSize.height / 2)
        .clamp(0.0, scene.groundY - objectSize.height);

    return Offset(fallbackX, fallbackY);
  }
}
