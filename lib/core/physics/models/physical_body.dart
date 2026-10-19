import 'physical_scalar.dart';

/// Modelo inmutable de un cuerpo físico independiente de la representación visual.
///
/// Posee identidad única, nombre pedagógico (ej. "Bloque A") y masa.
/// Es una clase final de Dart 3 sin dependencias de Flutter ni conocimiento
/// de identificadores de figuras geométricas visuales.
final class PhysicalBody {
  PhysicalBody({
    required this.id,
    this.name = '',
    PhysicalScalar? mass,
  }) : mass = mass ?? const PhysicalScalar.unspecified(symbol: 'm') {
    if (id.trim().isEmpty) {
      throw ArgumentError('El id del cuerpo físico no puede estar vacío');
    }
    _validateMass(this.mass);
  }

  /// Identificador único del cuerpo en el dominio físico.
  final String id;

  /// Nombre o etiqueta descriptiva (ej. "Bloque 1", "Masa A").
  final String name;

  /// Masa del cuerpo en kilogramos (kg).
  /// Puede ser conocida, incógnita a despejar o no especificada.
  final PhysicalScalar mass;

  /// Retorna una copia de este cuerpo con los atributos especificados actualizados.
  ///
  /// No permite modificar el identificador [id] para preservar la identidad de la entidad.
  PhysicalBody copyWith({
    String? name,
    PhysicalScalar? mass,
  }) {
    return PhysicalBody(
      id: id,
      name: name ?? this.name,
      mass: mass ?? this.mass,
    );
  }

  static void _validateMass(PhysicalScalar scalar) {
    if (scalar is KnownScalar && scalar.value < 0.0) {
      throw ArgumentError.value(
        scalar.value,
        'mass',
        'La masa de un cuerpo no puede ser negativa (recibido: ${scalar.value})',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhysicalBody &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          mass == other.mass;

  @override
  int get hashCode => Object.hash(id, name, mass);

  @override
  String toString() => 'PhysicalBody(id: $id, name: "$name", mass: $mass)';
}
