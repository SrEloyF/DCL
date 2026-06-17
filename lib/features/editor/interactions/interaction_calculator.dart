import 'dart:math';
import 'dart:ui';
import '../models/diagram_object.dart';
import '../models/handle_model.dart';

class InteractionCalculator {
  static Rect calculateResize(DiagramObject object, HandleAnchor anchor, Offset delta) {
    return object.transformResize(anchor, delta);
  }

  static double calculateRotation(DiagramObject object, Offset touchGlobalPosition) {
    final center = object.center;
    return atan2(
      touchGlobalPosition.dy - center.dy,
      touchGlobalPosition.dx - center.dx,
    );
  }
}
