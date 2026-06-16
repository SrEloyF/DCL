import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/scene_constants.dart';
import '../editor_controller.dart';
import '../models/diagram_object.dart';
import '../objects/block/block_model.dart';
import '../objects/block/block_painter.dart';
import '../objects/ramp/ramp_model.dart';
import '../objects/ramp/ramp_painter.dart';
import '../objects/sphere/sphere_model.dart';
import '../objects/sphere/sphere_painter.dart';
import 'handle_widget.dart';

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
              if (isSelected) ...[
                Positioned(
                  right: -22,
                  bottom: -22,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      widget.controller.resizeObject(object, details.delta);
                    },
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: HandleWidget(color: Colors.red)),
                    ),
                  ),
                ),
                if (object.canRotate)
                  Positioned(
                    top: -28,
                    left: (object.width / 2) - 22,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        final center = object.center;

                        _initialTouchAngle = atan2(
                          details.globalPosition.dy - center.dy,
                          details.globalPosition.dx - center.dx,
                        );
                        _initialAngle = object.angle;
                      },
                      onPanUpdate: (details) {
                        final center = object.center;

                        final currentTouchAngle = atan2(
                          details.globalPosition.dy - center.dy,
                          details.globalPosition.dx - center.dx,
                        );

                        widget.controller.setObjectAngle(
                          object,
                          _initialAngle +
                              (currentTouchAngle - _initialTouchAngle),
                        );
                      },
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(child: HandleWidget(color: Colors.green)),
                      ),
                    ),
                  ),
                if (object.canFlipX)
                  Positioned(
                    top: -28,
                    right: -22,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        widget.controller.flipObject(object);
                      },
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: HandleWidget(color: Colors.orange),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
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
