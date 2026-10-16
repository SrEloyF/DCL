import 'dart:math' as math;
import 'dart:ui';

import '../../features/editor/models/diagram_object.dart';
import '../../features/editor/objects/ramp/ramp_model.dart';

abstract class CollisionShape {}

class CollisionCircle extends CollisionShape {
  CollisionCircle(this.center, this.radius);
  final Offset center;
  final double radius;
}

class CollisionPolygon extends CollisionShape {
  CollisionPolygon(this.vertices);
  final List<Offset> vertices;
}

CollisionShape getShapeFromObject(DiagramObject obj, Rect bounds, [double? candidateAngle, bool? candidateMirrored]) {
  final angle = candidateAngle ?? obj.angle;
  if (obj.type == DiagramObjectType.sphere) {
    // Sphere collision uses its center and radius.
    // The bounds might be a candidate bounds, we derive center/radius from it.
    final radius = bounds.width / 2;
    final center = Offset(bounds.left + radius, bounds.top + radius);
    return CollisionCircle(center, radius);
  } else if (obj.type == DiagramObjectType.ramp) {
    // Ramp is a right triangle.
    final bool mirrored = candidateMirrored ?? ((obj is RampModel) ? obj.mirrored : false);
    final w = bounds.width;
    final h = bounds.height;
    final left = bounds.left;
    final top = bounds.top;

    List<Offset> vertices;
    if (!mirrored) {
      vertices = [
        Offset(left, top + h),
        Offset(left + w, top + h),
        Offset(left + w, top),
      ];
    } else {
      vertices = [
        Offset(left, top),
        Offset(left, top + h),
        Offset(left + w, top + h),
      ];
    }

    // Apply rotation if any (ramps don't typically rotate right now, but just in case)
    if (angle != 0) {
      final center = bounds.center;
      final s = math.sin(angle);
      final c = math.cos(angle);

      vertices = vertices.map((v) {
        final dx = v.dx - center.dx;
        final dy = v.dy - center.dy;
        return Offset(
          center.dx + dx * c - dy * s,
          center.dy + dx * s + dy * c,
        );
      }).toList();
    }

    return CollisionPolygon(vertices);
  } else {
    // Default (e.g. Block) is a rectangle, potentially rotated.
    final center = bounds.center;
    final w = bounds.width;
    final h = bounds.height;

    List<Offset> vertices = [
      Offset(center.dx - w / 2, center.dy - h / 2),
      Offset(center.dx + w / 2, center.dy - h / 2),
      Offset(center.dx + w / 2, center.dy + h / 2),
      Offset(center.dx - w / 2, center.dy + h / 2),
    ];

    if (angle != 0) {
      final s = math.sin(angle);
      final c = math.cos(angle);

      vertices = vertices.map((v) {
        final dx = v.dx - center.dx;
        final dy = v.dy - center.dy;
        return Offset(
          center.dx + dx * c - dy * s,
          center.dy + dx * s + dy * c,
        );
      }).toList();
    }

    return CollisionPolygon(vertices);
  }
}

bool checkCollision(
    DiagramObject a, Rect boundsA, DiagramObject b, Rect boundsB,
    {double? candidateAngleA, bool? candidateMirroredA}) {
  final shapeA = getShapeFromObject(a, boundsA, candidateAngleA, candidateMirroredA);
  final shapeB = getShapeFromObject(b, boundsB);

  if (shapeA is CollisionCircle && shapeB is CollisionCircle) {
    return _circleCircle(shapeA, shapeB);
  } else if (shapeA is CollisionPolygon && shapeB is CollisionPolygon) {
    return _polygonPolygon(shapeA, shapeB);
  } else if (shapeA is CollisionCircle && shapeB is CollisionPolygon) {
    return _polygonCircle(shapeB, shapeA);
  } else if (shapeA is CollisionPolygon && shapeB is CollisionCircle) {
    return _polygonCircle(shapeA, shapeB);
  }

  return false;
}

Rect getShapeBounds(CollisionShape shape) {
  if (shape is CollisionCircle) {
    return Rect.fromCircle(center: shape.center, radius: shape.radius);
  } else if (shape is CollisionPolygon) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    for (final p in shape.vertices) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  return Rect.zero;
}

bool _circleCircle(CollisionCircle a, CollisionCircle b) {
  final dx = a.center.dx - b.center.dx;
  final dy = a.center.dy - b.center.dy;
  final distanceSq = dx * dx + dy * dy;
  final radiusSum = a.radius + b.radius;
  return distanceSq < (radiusSum * radiusSum);
}

bool _polygonPolygon(CollisionPolygon a, CollisionPolygon b) {
  final polys = [a, b];
  for (int i = 0; i < polys.length; i++) {
    final poly = polys[i];
    for (int i1 = 0; i1 < poly.vertices.length; i1++) {
      final i2 = (i1 + 1) % poly.vertices.length;
      final p1 = poly.vertices[i1];
      final p2 = poly.vertices[i2];

      final normal = Offset(p2.dy - p1.dy, p1.dx - p2.dx);

      double minA = double.infinity;
      double maxA = double.negativeInfinity;
      for (final p in a.vertices) {
        final projected = normal.dx * p.dx + normal.dy * p.dy;
        if (projected < minA) minA = projected;
        if (projected > maxA) maxA = projected;
      }

      double minB = double.infinity;
      double maxB = double.negativeInfinity;
      for (final p in b.vertices) {
        final projected = normal.dx * p.dx + normal.dy * p.dy;
        if (projected < minB) minB = projected;
        if (projected > maxB) maxB = projected;
      }

      // If we find a separating axis, polygons do not overlap.
      // (Using <= or >= if we want to allow touching, but standard overlap is < )
      if (maxA <= minB || maxB <= minA) {
        return false; 
      }
    }
  }
  return true; // No separating axis found -> collision
}

bool _polygonCircle(CollisionPolygon poly, CollisionCircle circle) {
  // Test polygon edges as separating axes
  for (int i = 0; i < poly.vertices.length; i++) {
    final p1 = poly.vertices[i];
    final p2 = poly.vertices[(i + 1) % poly.vertices.length];
    final normal = Offset(p2.dy - p1.dy, p1.dx - p2.dx);
    final len = math.sqrt(normal.dx * normal.dx + normal.dy * normal.dy);
    if (len == 0) continue;
    final normalizedNormal = Offset(normal.dx / len, normal.dy / len);

    double minA = double.infinity;
    double maxA = double.negativeInfinity;
    for (final p in poly.vertices) {
      final projected =
          normalizedNormal.dx * p.dx + normalizedNormal.dy * p.dy;
      if (projected < minA) minA = projected;
      if (projected > maxA) maxA = projected;
    }

    final circleProjected = normalizedNormal.dx * circle.center.dx +
        normalizedNormal.dy * circle.center.dy;
    final minB = circleProjected - circle.radius;
    final maxB = circleProjected + circle.radius;

    if (maxA <= minB || maxB <= minA) {
      return false; // Separating axis found
    }
  }

  // Test circle center to closest vertex as separating axis
  Offset? closestVertex;
  double minDistanceSq = double.infinity;
  for (final p in poly.vertices) {
    final dx = p.dx - circle.center.dx;
    final dy = p.dy - circle.center.dy;
    final distSq = dx * dx + dy * dy;
    if (distSq < minDistanceSq) {
      minDistanceSq = distSq;
      closestVertex = p;
    }
  }

  if (closestVertex != null) {
    final axis = Offset(
        closestVertex.dx - circle.center.dx, closestVertex.dy - circle.center.dy);
    final len = math.sqrt(axis.dx * axis.dx + axis.dy * axis.dy);
    if (len > 0) {
      final normalizedAxis = Offset(axis.dx / len, axis.dy / len);

      double minA = double.infinity;
      double maxA = double.negativeInfinity;
      for (final p in poly.vertices) {
        final projected =
            normalizedAxis.dx * p.dx + normalizedAxis.dy * p.dy;
        if (projected < minA) minA = projected;
        if (projected > maxA) maxA = projected;
      }

      final circleProjected = normalizedAxis.dx * circle.center.dx +
          normalizedAxis.dy * circle.center.dy;
      final minB = circleProjected - circle.radius;
      final maxB = circleProjected + circle.radius;

      if (maxA <= minB || maxB <= minA) {
        return false; // Separating axis found
      }
    }
  }

  return true;
}