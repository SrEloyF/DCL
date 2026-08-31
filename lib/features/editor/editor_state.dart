import 'package:flutter/widgets.dart';

import 'models/camera_model.dart';
import 'models/diagram_object.dart';
import 'models/scene_model.dart';

class EditorState {
  EditorState({
    required this.scene,
    required this.objects,
    this.camera = const CameraModel(),
    this.selectedObject,
  });

  final SceneModel scene;
  final List<DiagramObject> objects;
  CameraModel camera;
  DiagramObject? selectedObject;

  Size get worldSize => scene.worldSize;
  double get groundY => scene.groundY;
  double get gridStep => scene.gridStep;
}
