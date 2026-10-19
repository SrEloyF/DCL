import 'dart:collection';
import 'package:flutter/widgets.dart';

import '../../core/physics/math/vector_2d.dart';
import '../../core/physics/models/force_model.dart';
import '../../core/physics/models/physical_body.dart';
import '../../core/physics/models/physics_problem.dart';
import 'models/camera_model.dart';
import 'models/diagram_object.dart';
import 'models/scene_model.dart';

/// Interfaz de solo lectura que expone el estado del editor sin permitir mutaciones directas.
abstract interface class ReadOnlyEditorState {
  SceneModel get scene;

  /// Vista inmutable de la lista de figuras presentes en la escena.
  ///
  /// NOTA DE ARQUITECTURA: Las instancias de [DiagramObject] contenidas siguen
  /// siendo mutables en sus propiedades geométricas internas (posición, tamaño, ángulo).
  /// La protección integral de su geometría queda fuera del alcance de este cambio, pero
  /// la estructura de la colección queda protegida contra inserciones o eliminaciones directas.
  List<DiagramObject> get objects;

  CameraModel get camera;
  DiagramObject? get selectedObject;
  ReadOnlyPhysicsProblem get problem;
  Map<String, String> get visualToPhysicalMap;
  String? getPhysicalBodyId(String visualObjectId);
  String? getVisualObjectId(String physicalBodyId);
  bool isVisualObjectBound(String visualObjectId);
  bool isPhysicalBodyBound(String physicalBodyId);
  Size get worldSize;
  double get groundY;
  double get gridStep;
}

/// Vista envolvente que impide el acceso a los métodos mutadores de [EditorState].
final class EditorStateView implements ReadOnlyEditorState {
  EditorStateView(this._state);

  final EditorState _state;

  @override
  SceneModel get scene => _state.scene;

  @override
  List<DiagramObject> get objects => _state.objects;

  @override
  CameraModel get camera => _state.camera;

  @override
  DiagramObject? get selectedObject => _state.selectedObject;

  @override
  ReadOnlyPhysicsProblem get problem => _state.problem;

  @override
  Map<String, String> get visualToPhysicalMap => _state.visualToPhysicalMap;

  @override
  String? getPhysicalBodyId(String visualObjectId) =>
      _state.getPhysicalBodyId(visualObjectId);

  @override
  String? getVisualObjectId(String physicalBodyId) =>
      _state.getVisualObjectId(physicalBodyId);

  @override
  bool isVisualObjectBound(String visualObjectId) =>
      _state.isVisualObjectBound(visualObjectId);

  @override
  bool isPhysicalBodyBound(String physicalBodyId) =>
      _state.isPhysicalBodyBound(physicalBodyId);

  @override
  Size get worldSize => _state.worldSize;

  @override
  double get groundY => _state.groundY;

  @override
  double get gridStep => _state.gridStep;
}

/// Encapsula el estado completo del editor visual y el dominio físico.
class EditorState implements ReadOnlyEditorState {
  EditorState({
    required this.scene,
    required List<DiagramObject> objects,
    this.camera = const CameraModel(),
    this.selectedObject,
    ReadOnlyPhysicsProblem? problem,
    Map<String, String>? visualToPhysicalMap,
  })  : _objects = List<DiagramObject>.from(objects),
        _problem = PhysicsProblem(
          id: problem?.id ?? 'default_problem',
          gravity: problem?.gravity ?? Vector2D(0.0, -9.81),
        ) {
    if (problem != null) {
      // Reconstruye el agregado reutilizando las validaciones de addBody y addForce
      for (final body in problem.bodies.values) {
        _problem.addBody(body.copyWith());
      }
      for (final force in problem.forces.values) {
        _problem.addForce(force.copyWith());
      }
    }
    if (visualToPhysicalMap != null) {
      for (final entry in visualToPhysicalMap.entries) {
        bind(entry.key, entry.value);
      }
    }
  }

  @override
  final SceneModel scene;

  final List<DiagramObject> _objects;

  /// Vista inmutable de la lista de figuras presentes en la escena.
  ///
  /// NOTA DE ARQUITECTURA: Las instancias de [DiagramObject] contenidas siguen
  /// siendo mutables en sus propiedades geométricas internas (posición, tamaño, ángulo).
  /// La protección integral de su geometría queda fuera del alcance de este cambio, pero
  /// la estructura de la colección queda protegida contra inserciones o eliminaciones directas.
  @override
  List<DiagramObject> get objects => UnmodifiableListView(_objects);

  /// Lista interna mutable para uso exclusivo del controlador del editor.
  List<DiagramObject> get mutableObjects => _objects;

  @override
  CameraModel camera;

  @override
  DiagramObject? selectedObject;

  final PhysicsProblem _problem;

  /// Vista de solo lectura del problema físico gestionado por el editor.
  @override
  ReadOnlyPhysicsProblem get problem => _problem.asReadOnly();

  final Map<String, String> _visualToPhysicalMap = <String, String>{};
  final Map<String, String> _physicalToVisualMap = <String, String>{};

  /// Vista inmutable del mapa de asociaciones (DiagramObject.id -> PhysicalBody.id).
  @override
  Map<String, String> get visualToPhysicalMap =>
      UnmodifiableMapView(_visualToPhysicalMap);

  /// Retorna el ID del cuerpo físico asociado al ID visual [visualObjectId], o null si no existe vínculo.
  @override
  String? getPhysicalBodyId(String visualObjectId) =>
      _visualToPhysicalMap[visualObjectId];

  /// Retorna el ID de la figura visual asociada al cuerpo físico [physicalBodyId], o null si no existe vínculo.
  @override
  String? getVisualObjectId(String physicalBodyId) =>
      _physicalToVisualMap[physicalBodyId];

  /// Retorna verdadero si la figura visual ya está vinculada a un cuerpo físico.
  @override
  bool isVisualObjectBound(String visualObjectId) =>
      _visualToPhysicalMap.containsKey(visualObjectId);

  /// Retorna verdadero si el cuerpo físico ya está vinculado a una figura visual.
  @override
  bool isPhysicalBodyBound(String physicalBodyId) =>
      _physicalToVisualMap.containsKey(physicalBodyId);

  /// Registra la asociación 1 a 1 entre la figura visual y el cuerpo físico, validando
  /// la existencia de ambas entidades y garantizando que ninguna esté previamente asociada.
  /// Si alguna validación falla, se lanza una excepción y ningún mapa es alterado.
  void bind(String visualObjectId, String physicalBodyId) {
    _validateBinding(visualObjectId, physicalBodyId);
    _visualToPhysicalMap[visualObjectId] = physicalBodyId;
    _physicalToVisualMap[physicalBodyId] = visualObjectId;
  }

  void _validateBinding(String visualObjectId, String physicalBodyId) {
    final visualExists = _objects.any((obj) => obj.id == visualObjectId);
    if (!visualExists) {
      throw ArgumentError(
        'No se puede asociar: la figura visual con id "$visualObjectId" no existe en la escena.',
      );
    }

    final physicalExists = _problem.bodies.containsKey(physicalBodyId);
    if (!physicalExists) {
      throw ArgumentError(
        'No se puede asociar: el cuerpo físico con id "$physicalBodyId" no existe en el problema físico.',
      );
    }

    if (isVisualObjectBound(visualObjectId)) {
      throw StateError(
        'No se puede asociar: la figura visual "$visualObjectId" ya está vinculada al cuerpo físico "${getPhysicalBodyId(visualObjectId)}".',
      );
    }

    if (isPhysicalBodyBound(physicalBodyId)) {
      throw StateError(
        'No se puede asociar: el cuerpo físico "$physicalBodyId" ya está vinculado a la figura visual "${getVisualObjectId(physicalBodyId)}".',
      );
    }
  }

  /// Elimina la asociación existente para la figura visual [visualObjectId] y mantiene coherentes ambos mapas.
  /// Retorna true si existía la asociación y fue eliminada, o false si no estaba vinculada.
  bool unbind(String visualObjectId) {
    final physicalBodyId = _visualToPhysicalMap.remove(visualObjectId);
    if (physicalBodyId != null) {
      _physicalToVisualMap.remove(physicalBodyId);
      return true;
    }
    return false;
  }

  /// Elimina la asociación existente para el cuerpo físico [physicalBodyId] y mantiene coherentes ambos mapas.
  /// Retorna true si existía la asociación y fue eliminada, o false si no estaba vinculado.
  bool unbindPhysical(String physicalBodyId) {
    final visualObjectId = _physicalToVisualMap.remove(physicalBodyId);
    if (visualObjectId != null) {
      _visualToPhysicalMap.remove(visualObjectId);
      return true;
    }
    return false;
  }

  /// Agrega un cuerpo físico al problema gestionado internamente.
  void addPhysicalBody(PhysicalBody body) {
    _problem.addBody(body);
  }

  /// Elimina un cuerpo físico del problema y desvincula cualquier figura visual asociada.
  /// Retorna true si el cuerpo existía y fue eliminado, o false si no existía.
  bool removePhysicalBody(String physicalBodyId) {
    final removed = _problem.removeBody(physicalBodyId);
    if (removed) {
      unbindPhysical(physicalBodyId);
      return true;
    }
    return false;
  }

  /// Agrega una fuerza al problema gestionado internamente.
  void addForce(ForceModel force) {
    _problem.addForce(force);
  }

  /// Elimina una fuerza del problema gestionado internamente.
  bool removeForce(String forceId) {
    return _problem.removeForce(forceId);
  }

  @override
  Size get worldSize => scene.worldSize;

  @override
  double get groundY => scene.groundY;

  @override
  double get gridStep => scene.gridStep;
}
