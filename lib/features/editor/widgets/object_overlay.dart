import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/scene_constants.dart';
import '../editor_controller.dart';
import '../interactions/interaction_calculator.dart';
import '../models/diagram_object.dart';
import '../models/handle_model.dart';
import '../objects/block/block_model.dart';
import '../objects/block/block_painter.dart';
import '../objects/ramp/ramp_model.dart';
import '../objects/ramp/ramp_painter.dart';
import '../objects/sphere/sphere_model.dart';
import '../objects/sphere/sphere_painter.dart';
import 'handle_widget.dart';
import 'helpers/handle_position_calculator.dart';

class ObjectOverlay extends StatefulWidget {
  const ObjectOverlay({
    super.key,
    required this.controller,
    required this.object,
  });

  final EditorController controller;
  final DiagramObject object;

  @override
  State<ObjectOverlay> createState() => _ObjectOverlayState();
}

class _ObjectOverlayState extends State<ObjectOverlay> {
  double _initialAngle = 0.0;
  double _initialTouchAngle = 0.0;

  static const double _padding = SceneConstants.objectPadding;

  @override
  Widget build(BuildContext context) {
    final object = widget.object;
    final isSelected = widget.controller.selectedObject == object;
    final angle = object.canRotate ? object.angle : 0.0;

    return Positioned(
      left: object.x - _padding,
      top: object.y - _padding,
      child: Transform.rotate(
        angle: angle,
        child: SizedBox(
          width: object.width + (_padding * 2),
          height: object.height + (_padding * 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: _padding,
                top: _padding,
                width: object.width,
                height: object.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    widget.controller.selectObject(object);
                  },
                  onPanStart: (_) {
                    widget.controller.selectObject(object);
                  },
                  onPanUpdate: (details) {
                    final dx = details.delta.dx;
                    final dy = details.delta.dy;

                    widget.controller.moveObject(
                      object,
                      Offset(
                        dx * cos(angle) - dy * sin(angle),
                        dx * sin(angle) + dy * cos(angle),
                      ),
                    );
                  },
                  child: _buildObjectBody(object, isSelected),
                ),
              ),
              if (isSelected) ...object.handles.map((h) => _buildHandle(h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(HandleModel handle) {
    final object = widget.object;
    final position = HandlePositionCalculator.getHandlePosition(handle, object);

    return Positioned(
      left: position.dx + _padding - 12, // Center the 24px handle
      top: position.dy + _padding - 12,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: handle.type == HandleType.rotate
            ? (details) {
                _initialTouchAngle = InteractionCalculator.calculateRotation(
                  object,
                  details.globalPosition,
                );
                _initialAngle = object.angle;
              }
            : null,
        onPanUpdate: (details) {
          switch (handle.type) {
            case HandleType.resize:
              final candidateBounds = InteractionCalculator.calculateResize(
                object,
                handle.anchor,
                details.delta,
              );
              widget.controller.updateObjectBounds(object, candidateBounds);
              break;
            case HandleType.rotate:
              final currentTouchAngle = InteractionCalculator.calculateRotation(
                object,
                details.globalPosition,
              );
              widget.controller.setObjectAngle(
                object,
                _initialAngle + (currentTouchAngle - _initialTouchAngle),
              );
              break;
            case HandleType.flip:
              // Flip usually handled on tap, but we can support pan if needed
              break;
          }
        },
        onTap: handle.type == HandleType.flip
            ? () {
                final success = widget.controller.flipObject(object);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No hay espacio para reflejar el objeto.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            : null,
        child: HandleWidget(type: handle.type, anchor: handle.anchor),
      ),
    );
  }

  Widget _buildObjectBody(DiagramObject object, bool selected) {
    if (object is BlockModel) {
      return CustomPaint(
        painter: BlockPainter(selected: selected),
        size: Size(object.width, object.height),
      );
    }

    if (object is RampModel) {
      return CustomPaint(
        painter: RampPainter(mirrored: object.mirrored, selected: selected),
        size: Size(object.width, object.height),
      );
    }

    if (object is SphereModel) {
      return CustomPaint(
        painter: SpherePainter(selected: selected),
        size: Size(object.width, object.height),
      );
    }

    return const SizedBox.shrink();
  }
}
