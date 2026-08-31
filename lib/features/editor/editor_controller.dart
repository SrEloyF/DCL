import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:prueba/features/editor/models/camera_model.dart';

import '../../core/constants/scene_constants.dart';
import '../../core/utils/id_generator.dart';
import 'editor_state.dart';
import 'models/diagram_object.dart';
import 'models/handle_model.dart';
import 'models/scene_model.dart';
import 'objects/block/block_model.dart';
import 'objects/ramp/ramp_model.dart';
import 'objects/sphere/sphere_model.dart';
import 'services/object_spawn_service.dart';
import 'services/scene_constraint_service.dart';

class EditorController extends ChangeNotifier {

  final SceneConstraintService _constraints = const SceneConstraintService();

  EditorController()
    : state = EditorState(
        scene: const SceneModel(
          worldSize: SceneConstants.worldSize,
          groundY: SceneConstants.groundY,
          gridStep: SceneConstants.gridStep,
        ),
        objects: <DiagramObject>[],
      );

  final EditorState state;
  final IdGenerator _ids = IdGenerator();

  Size _viewportSize = Size.zero;

  DiagramObject? get selectedObject => state.selectedObject;
  List<DiagramObject> get objects => state.objects;

  void updateViewportSize(Size size) {
    _viewportSize = size;
  }

  void updateCamera(Offset offset, double scale) {
    state.camera = CameraModel(offset: offset, scale: scale);
  }

  bool get canFlipSelected => state.selectedObject?.canFlipX ?? false;
  bool get canRotateSelected => state.selectedObject?.canRotate ?? false;

  void selectObject(DiagramObject? object) {
    state.selectedObject = object;
    notifyListeners();
  }

  void clearSelection() {
    if (state.selectedObject == null) return;
    state.selectedObject = null;
    notifyListeners();
  }

  void addObject(DiagramObject object) {
    final pos = ObjectSpawnService.findSpawnPosition(
      viewportSize: _viewportSize,
      camera: state.camera,
      objectSize: Size(object.width, object.height),
      objects: objects,
      scene: state.scene,
    );

    object.applyBounds(
      Rect.fromLTWH(pos.dx, pos.dy, object.width, object.height),
    );

    objects.add(object);
    state.selectedObject = object;
    notifyListeners();
  }

  void addBlock() {
    addObject(
      BlockModel(
        id: _ids.next('block'),
        x: 0,
        y: 0,
        width: 180,
        height: 160,
      ),
    );
  }

  void addRamp() {
    addObject(
      RampModel(
        id: _ids.next('ramp'),
        x: 0,
        y: 0,
        width: 220,
        height: 160,
      ),
    );
  }

  void addSphere() {
    addObject(
      SphereModel(
        id: _ids.next('sphere'),
        x: 0,
        y: 0,
        radius: 75,
      ),
    );
  }

  void deleteSelected() {
    if (state.selectedObject == null) return;
    objects.remove(state.selectedObject);
    state.selectedObject = null;
    notifyListeners();
  }

  void moveObject(DiagramObject object, Offset delta) {
    final nextPosition = Offset(object.x + delta.dx, object.y + delta.dy);

    final allowed = _constraints.canMove(
      object: object,
      nextPosition: nextPosition,
      scene: state.scene,
      objects: objects,
    );

    if (!allowed) return;

    object.move(delta.dx, delta.dy);

    notifyListeners();
  }

  void resizeObject(DiagramObject object, Offset delta) {
    final candidateBounds = object.transformResize(HandleAnchor.bottom, delta);
    updateObjectBounds(object, candidateBounds);
  }

  void updateObjectBounds(DiagramObject object, Rect newBounds) {
    final allowed = _constraints.canResize(
      object: object,
      candidateBounds: newBounds,
      scene: state.scene,
      objects: objects,
    );

    if (!allowed) return;

    object.applyBounds(newBounds);
    notifyListeners();
  }

  void rotateObject(DiagramObject object, double deltaAngle) {
    object.rotate(deltaAngle);
    notifyListeners();
  }

  void flipObject(DiagramObject object) {
    if (!object.canFlipX) return;
    object.flipX();
    notifyListeners();
  }

  /*void _clampToScene(DiagramObject object) {
    final maxX = state.worldSize.width - object.width;
    final maxY = state.groundY - object.height;

    object.x = object.x.clamp(0.0, maxX);
    object.y = object.y.clamp(0.0, maxY);
  }*/

  void setObjectAngle(DiagramObject object, double angle) {
    object.angle = angle;
    notifyListeners();
  }
}
