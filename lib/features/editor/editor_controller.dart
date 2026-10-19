import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:prueba/features/editor/models/camera_model.dart';

import '../../core/constants/scene_constants.dart';
import '../../core/physics/models/force_model.dart';
import '../../core/physics/models/physical_body.dart';
import '../../core/physics/models/physics_problem.dart';
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

  EditorController({ReadOnlyPhysicsProblem? initialProblem})
      : _state = EditorState(
          scene: const SceneModel(
            worldSize: SceneConstants.worldSize,
            groundY: SceneConstants.groundY,
            gridStep: SceneConstants.gridStep,
          ),
          objects: <DiagramObject>[],
          problem: initialProblem,
        );

  final EditorState _state;
  final IdGenerator _ids = IdGenerator();

  Size _viewportSize = Size.zero;

  /// Vista de solo lectura del estado del editor.
  ///
  /// Impide mutaciones directas a colecciones o entidades que se salten [notifyListeners].
  ReadOnlyEditorState get state => EditorStateView(_state);

  /// Escenario de la escena (conveniencia para no navegar a través de [state]).
  SceneModel get scene => _state.scene;

  DiagramObject? get selectedObject => _state.selectedObject;

  /// Vista inmutable de las figuras en la escena.
  ///
  /// NOTA DE ARQUITECTURA: Impide modificar directamente la estructura de la
  /// lista (ej. `add` o `remove`). Las propiedades geométricas de las instancias
  /// siguen siendo mutables en esta fase del proyecto.
  List<DiagramObject> get objects => _state.objects;

  /// Retorna la vista de solo lectura del problema físico gestionado por el editor.
  ReadOnlyPhysicsProblem get problem => _state.problem;

  /// Retorna la vista inmutable del mapa de asociaciones (DiagramObject.id -> PhysicalBody.id).
  Map<String, String> get visualToPhysicalMap => _state.visualToPhysicalMap;

  /// Retorna el ID del cuerpo físico asociado a la figura visual [visualObjectId], o null si no existe vínculo.
  String? getPhysicalBodyId(String visualObjectId) =>
      _state.getPhysicalBodyId(visualObjectId);

  /// Retorna el ID de la figura visual asociada al cuerpo físico [physicalBodyId], o null si no existe vínculo.
  String? getVisualObjectId(String physicalBodyId) =>
      _state.getVisualObjectId(physicalBodyId);

  void updateViewportSize(Size size) {
    _viewportSize = size;
  }

  void updateCamera(Offset offset, double scale) {
    _state.camera = CameraModel(offset: offset, scale: scale);
  }

  bool get canFlipSelected => _state.selectedObject?.canFlipX ?? false;
  bool get canRotateSelected => _state.selectedObject?.canRotate ?? false;

  void selectObject(DiagramObject? object) {
    _state.selectedObject = object;
    notifyListeners();
  }

  void clearSelection() {
    if (_state.selectedObject == null) return;
    _state.selectedObject = null;
    notifyListeners();
  }

  void addObject(DiagramObject object) {
    final pos = ObjectSpawnService.findSpawnPosition(
      viewportSize: _viewportSize,
      camera: _state.camera,
      object: object,
      objects: _state.objects,
      scene: _state.scene,
    );

    object.applyBounds(
      Rect.fromLTWH(pos.dx, pos.dy, object.width, object.height),
    );

    _state.mutableObjects.add(object);
    _state.selectedObject = object;
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

  /// Elimina la figura visual seleccionada y sincroniza atómicamente el dominio físico.
  ///
  /// Si la figura estaba asociada a un cuerpo físico, elimina el cuerpo de [problem]
  /// (y en cascada sus fuerzas) y disuelve el vínculo. Emite una única notificación.
  void deleteSelected() {
    final selected = _state.selectedObject;
    if (selected == null) return;

    final physicalBodyId = _state.getPhysicalBodyId(selected.id);
    if (physicalBodyId != null) {
      _state.removePhysicalBody(physicalBodyId);
    }

    _state.mutableObjects.remove(selected);
    _state.selectedObject = null;
    notifyListeners();
  }

  // --- Operaciones oficiales de mutación física ---

  /// Agrega un cuerpo físico al problema gestionado por el editor.
  ///
  /// Realiza una copia defensiva profunda del cuerpo mediante [copyWith] para evitar
  /// que mutaciones externas afecten el estado interno. Notifica a los oyentes.
  void addPhysicalBody(PhysicalBody body) {
    _state.addPhysicalBody(body.copyWith());
    notifyListeners();
  }

  /// Elimina un cuerpo físico del problema y desvincula cualquier figura visual asociada.
  ///
  /// Aplica borrado en cascada sobre las fuerzas del cuerpo.
  /// Notifica a los oyentes únicamente si el cuerpo existía y fue eliminado.
  bool removePhysicalBody(String physicalBodyId) {
    final removed = _state.removePhysicalBody(physicalBodyId);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  /// Agrega una fuerza al problema gestionado por el editor.
  ///
  /// Realiza una copia defensiva de la fuerza mediante [copyWith]. Notifica a los oyentes.
  void addForce(ForceModel force) {
    _state.addForce(force.copyWith());
    notifyListeners();
  }

  /// Elimina una fuerza del problema gestionado por el editor.
  ///
  /// Notifica a los oyentes únicamente si la fuerza existía y fue eliminada.
  bool removeForce(String forceId) {
    final removed = _state.removeForce(forceId);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  // --- Operaciones oficiales de asociación visual-física ---

  /// Asocia explícitamente una figura visual existente con un cuerpo físico registrado en el problema.
  ///
  /// Reutiliza las validaciones centralizadas en [EditorState.bind] y notifica a los oyentes tras una asociación exitosa.
  void bindVisualToPhysical({
    required String visualObjectId,
    required String physicalBodyId,
  }) {
    _state.bind(visualObjectId, physicalBodyId);
    notifyListeners();
  }

  /// Desvincula explícitamente una figura visual de su cuerpo físico asociado, si existe.
  void unbindVisual(String visualObjectId) {
    if (_state.unbind(visualObjectId)) {
      notifyListeners();
    }
  }

  void moveObject(DiagramObject object, Offset delta) {
    final nextPosition = Offset(object.x + delta.dx, object.y + delta.dy);

    final allowed = _constraints.canMove(
      object: object,
      nextPosition: nextPosition,
      scene: _state.scene,
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
      scene: _state.scene,
      objects: objects,
    );

    if (!allowed) return;

    object.applyBounds(newBounds);
    notifyListeners();
  }

  void rotateObject(DiagramObject object, double deltaAngle) {
    final nextAngle = object.angle + deltaAngle;
    final allowed = _constraints.canRotate(
      object: object,
      candidateAngle: nextAngle,
      scene: _state.scene,
      objects: objects,
    );

    if (!allowed) return;

    object.rotate(deltaAngle);
    notifyListeners();
  }

  bool flipObject(DiagramObject object) {
    if (!object.canFlipX) return false;

    bool nextMirrored = true;
    if (object is RampModel) {
      nextMirrored = !object.mirrored;
    }

    final allowed = _constraints.canFlip(
      object: object,
      candidateMirrored: nextMirrored,
      scene: _state.scene,
      objects: objects,
    );

    if (!allowed) return false;

    object.flipX();
    notifyListeners();
    return true;
  }

  void setObjectAngle(DiagramObject object, double angle) {
    final allowed = _constraints.canRotate(
      object: object,
      candidateAngle: angle,
      scene: _state.scene,
      objects: objects,
    );
    if (!allowed) return;

    object.angle = angle;
    notifyListeners();
  }
}
