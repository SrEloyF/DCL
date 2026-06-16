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
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.controller.state.scene;

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
  }
}
