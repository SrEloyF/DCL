import 'dart:math' as math;

import '../math/vector_2d.dart';
import 'physical_scalar.dart';

/// Tipos de fuerzas fundamentales en problemas de física elemental.
enum ForceType {
  weight,
  normal,
  friction,
  tension,
  applied,
  elastic,
}

/// Modelo inmutable de una fuerza puntual aplicada sobre un cuerpo específico ([bodyId]).
///
/// La magnitud se expresa en Newtons (N) y no puede ser negativa cuando es conocida.
/// La dirección se expresa en radianes respecto al eje global +X (antihorario) y admite valores negativos.
/// Es una clase final de Dart 3 sin dependencias de Flutter.
final class ForceModel {
  ForceModel({
    required this.id,
    required this.bodyId,
    required this.type,
    this.name = '',
    PhysicalScalar? magnitude,
    PhysicalScalar? direction,
  })  : magnitude = magnitude ?? const PhysicalScalar.unspecified(symbol: 'F'),
        direction = direction ?? const PhysicalScalar.unspecified(symbol: 'θ') {
    if (id.trim().isEmpty) {
      throw ArgumentError('El id de la fuerza no puede estar vacío');
    }
    if (bodyId.trim().isEmpty) {
      throw ArgumentError('El id del cuerpo asociado (bodyId) no puede estar vacío');
    }
    _validateMagnitude(this.magnitude);
  }

  /// Identificador único de la fuerza.
  final String id;

  /// Identificador del cuerpo sobre el cual actúa la fuerza.
  final String bodyId;

  /// Clasificación de la fuerza.
  final ForceType type;

  /// Nombre pedagógico de la fuerza (ej. "Peso", "Normal", "Tensión").
  final String name;

  /// Magnitud de la fuerza en Newtons (N).
  final PhysicalScalar magnitude;

  /// Dirección angular de la fuerza en radianes respecto a +X (antihorario).
  final PhysicalScalar direction;

  /// Retorna una copia de esta fuerza con los atributos especificados actualizados.
  ///
  /// No permite modificar el identificador [id] ni el cuerpo destino [bodyId].
  ForceModel copyWith({
    ForceType? type,
    String? name,
    PhysicalScalar? magnitude,
    PhysicalScalar? direction,
  }) {
    return ForceModel(
      id: id,
      bodyId: bodyId,
      type: type ?? this.type,
      name: name ?? this.name,
      magnitude: magnitude ?? this.magnitude,
      direction: direction ?? this.direction,
    );
  }

  static void _validateMagnitude(PhysicalScalar scalar) {
    if (scalar is KnownScalar && scalar.value < 0.0) {
      throw ArgumentError.value(
        scalar.value,
        'magnitude',
        'La magnitud de una fuerza no puede ser negativa (recibido: ${scalar.value})',
      );
    }
  }

  /// Retorna las componentes cartesianas (Fx, Fy) de la fuerza en un [Vector2D].
  ///
  /// Retorna `null` si la magnitud o la dirección no son conocidas ([KnownScalar]).
  Vector2D? get vector {
    final mag = magnitude;
    final dir = direction;
    if (mag is! KnownScalar || dir is! KnownScalar) {
      return null;
    }
    final m = mag.value;
    final theta = dir.value;
    return Vector2D(m * math.cos(theta), m * math.sin(theta));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bodyId == other.bodyId &&
          type == other.type &&
          name == other.name &&
          magnitude == other.magnitude &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(id, bodyId, type, name, magnitude, direction);

  @override
  String toString() =>
      'ForceModel(id: $id, bodyId: $bodyId, type: $type, name: "$name", magnitude: $magnitude, direction: $direction)';
}
