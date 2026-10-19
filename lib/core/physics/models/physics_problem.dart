import 'dart:collection';

import '../math/vector_2d.dart';
import 'force_model.dart';
import 'physical_body.dart';

/// Interfaz de consulta de solo lectura para un problema de física.
///
/// Expone únicamente getters de lectura y colecciones inmutables,
/// impidiendo la mutación de cuerpos, fuerzas o parámetros globales.
abstract interface class ReadOnlyPhysicsProblem {
  String get id;
  Vector2D get gravity;
  Map<String, PhysicalBody> get bodies;
  Map<String, ForceModel> get forces;
  PhysicalBody? getBody(String bodyId);
  ForceModel? getForce(String forceId);
  List<ForceModel> getForcesForBody(String bodyId);
}

/// Vista envolvente de solo lectura que protege una instancia de [PhysicsProblem].
///
/// Previene que el código consumidor invoque métodos mutadores mediante
/// casts hacia la clase concreta [PhysicsProblem].
final class PhysicsProblemView implements ReadOnlyPhysicsProblem {
  PhysicsProblemView(this._problem);

  final PhysicsProblem _problem;

  @override
  String get id => _problem.id;

  @override
  Vector2D get gravity => _problem.gravity;

  @override
  Map<String, PhysicalBody> get bodies => _problem.bodies;

  @override
  Map<String, ForceModel> get forces => _problem.forces;

  @override
  PhysicalBody? getBody(String bodyId) => _problem.getBody(bodyId);

  @override
  ForceModel? getForce(String forceId) => _problem.getForce(forceId);

  @override
  List<ForceModel> getForcesForBody(String bodyId) =>
      _problem.getForcesForBody(bodyId);
}

/// Agregado raíz que gestiona el conjunto de cuerpos y fuerzas de un problema de física.
///
/// Garantiza la integridad referencial:
/// - Cada cuerpo y fuerza tiene un ID único en el problema.
/// - Toda fuerza debe pertenecer a un cuerpo existente.
/// - La eliminación de un cuerpo elimina en cascada todas sus fuerzas asociadas.
/// - Las colecciones expuestas son inmutables para impedir modificaciones directas.
class PhysicsProblem implements ReadOnlyPhysicsProblem {
  PhysicsProblem({
    required this.id,
    Vector2D? gravity,
    Iterable<PhysicalBody>? bodies,
    Iterable<ForceModel>? forces,
  }) : gravity = gravity ?? Vector2D(0.0, -9.81) {
    if (id.trim().isEmpty) {
      throw ArgumentError('El id del problema físico no puede estar vacío');
    }
    if (bodies != null) {
      for (final body in bodies) {
        addBody(body);
      }
    }
    if (forces != null) {
      for (final force in forces) {
        addForce(force);
      }
    }
  }

  @override
  final String id;

  @override
  Vector2D gravity;

  final Map<String, PhysicalBody> _bodies = <String, PhysicalBody>{};
  final Map<String, ForceModel> _forces = <String, ForceModel>{};

  @override
  Map<String, PhysicalBody> get bodies => UnmodifiableMapView(_bodies);

  @override
  Map<String, ForceModel> get forces => UnmodifiableMapView(_forces);

  /// Agrega un nuevo cuerpo físico al problema.
  ///
  /// Lanza [StateError] si ya existe un cuerpo con el mismo [body.id].
  void addBody(PhysicalBody body) {
    if (_bodies.containsKey(body.id)) {
      throw StateError(
        'Ya existe un cuerpo con id "${body.id}" en el problema',
      );
    }
    _bodies[body.id] = body;
  }

  /// Actualiza un cuerpo existente en el problema reemplazándolo por [body].
  ///
  /// Lanza [ArgumentError] si no existe un cuerpo registrado con [body.id].
  void updateBody(PhysicalBody body) {
    if (!_bodies.containsKey(body.id)) {
      throw ArgumentError(
        'No se puede actualizar: el cuerpo con id "${body.id}" no existe en el problema',
      );
    }
    _bodies[body.id] = body;
  }

  @override
  PhysicalBody? getBody(String bodyId) => _bodies[bodyId];

  /// Elimina el cuerpo físico con identificador [bodyId].
  ///
  /// Aplica borrado en cascada: elimina automáticamente todas las fuerzas
  /// cuyo `force.bodyId == bodyId`.
  /// Retorna `true` si el cuerpo existía y fue eliminado, o `false` si no existía.
  bool removeBody(String bodyId) {
    final removed = _bodies.remove(bodyId);
    if (removed == null) {
      return false;
    }
    _forces.removeWhere((_, force) => force.bodyId == bodyId);
    return true;
  }

  /// Agrega una fuerza al problema físico.
  ///
  /// Lanza [StateError] si ya existe una fuerza con [force.id].
  /// Lanza [ArgumentError] si el cuerpo destino [force.bodyId] no existe en el problema.
  void addForce(ForceModel force) {
    if (_forces.containsKey(force.id)) {
      throw StateError(
        'Ya existe una fuerza con id "${force.id}" en el problema',
      );
    }
    if (!_bodies.containsKey(force.bodyId)) {
      throw ArgumentError(
        'No se puede agregar la fuerza "${force.id}": el cuerpo destino "${force.bodyId}" no existe en el problema',
      );
    }
    _forces[force.id] = force;
  }

  /// Actualiza una fuerza existente en el problema reemplazándola por [force].
  ///
  /// Lanza [ArgumentError] si la fuerza no existe o si el [force.bodyId] no existe.
  void updateForce(ForceModel force) {
    if (!_forces.containsKey(force.id)) {
      throw ArgumentError(
        'No se puede actualizar: la fuerza con id "${force.id}" no existe en el problema',
      );
    }
    if (!_bodies.containsKey(force.bodyId)) {
      throw ArgumentError(
        'No se puede actualizar: el cuerpo destino "${force.bodyId}" no existe en el problema',
      );
    }
    _forces[force.id] = force;
  }

  @override
  ForceModel? getForce(String forceId) => _forces[forceId];

  /// Elimina la fuerza con identificador [forceId].
  /// Retorna `true` si la fuerza existía y fue eliminada, o `false` si no existía.
  bool removeForce(String forceId) {
    return _forces.remove(forceId) != null;
  }

  @override
  List<ForceModel> getForcesForBody(String bodyId) {
    return _forces.values
        .where((f) => f.bodyId == bodyId)
        .toList(growable: false);
  }

  /// Elimina todos los cuerpos y fuerzas del problema.
  void clear() {
    _forces.clear();
    _bodies.clear();
  }

  /// Retorna una vista protegida de solo lectura de este problema físico.
  ReadOnlyPhysicsProblem asReadOnly() => PhysicsProblemView(this);
}
