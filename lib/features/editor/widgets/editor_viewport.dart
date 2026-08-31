import 'package:flutter/material.dart';

import '../../../core/constants/scene_constants.dart';
import '../editor_controller.dart';
import 'editor_canvas.dart';

class EditorViewport extends StatefulWidget {
  const EditorViewport({
    super.key,
    required this.controller,
  });

  final EditorController controller;

  @override
  State<EditorViewport> createState() => _EditorViewportState();
}

class _EditorViewportState extends State<EditorViewport> {
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onCameraChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onCameraChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onCameraChanged() {
    final matrix = _transformationController.value;
    final translation = matrix.getTranslation();
    final scale = matrix.getMaxScaleOnAxis();

    widget.controller.updateCamera(
      Offset(translation.x, translation.y),
      scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.controller.state.scene;

    return LayoutBuilder(
      builder: (context, constraints) {
        widget.controller.updateViewportSize(constraints.biggest);

        return InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(SceneConstants.boundaryMargin),
          minScale: SceneConstants.minScale,
          maxScale: SceneConstants.maxScale,
          constrained: false,
          child: SizedBox(
            width: scene.worldSize.width,
            height: scene.worldSize.height,
            child: EditorCanvas(controller: widget.controller),
          ),
        );
      },
    );
  }
}
