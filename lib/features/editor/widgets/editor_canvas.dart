import 'package:flutter/material.dart';

import '../editor_controller.dart';
import '../painters/scene_painter.dart';
import 'object_overlay.dart';

class EditorCanvas extends StatelessWidget {
  const EditorCanvas({
    super.key,
    required this.controller,
  });

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scene = controller.state.scene;

        return SizedBox(
          width: scene.worldSize.width,
          height: scene.worldSize.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: ScenePainter(
                    worldSize: scene.worldSize,
                    groundY: scene.groundY,
                    gridStep: scene.gridStep,
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.clearSelection,
                  child: const SizedBox.expand(),
                ),
              ),
              ...controller.objects.map(
                (object) => ObjectOverlay(
                  key: ValueKey(object.id),
                  controller: controller,
                  object: object,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
