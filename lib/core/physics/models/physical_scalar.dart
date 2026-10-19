/// Representación de un escalar físico con distinción explícita de su estado:
/// - [KnownScalar]: Valor numérico conocido y finito (ej. m = 5.0 kg, F = 0.0 N).
/// - [UnknownScalar]: Incógnita matemática del problema (ej. "?" a despejar).
/// - [UnspecifiedScalar]: Dato pendiente de configuración por el usuario.
sealed class PhysicalScalar {
  const PhysicalScalar({this.symbol});

  /// Símbolo opcional de la variable (ej. "m", "F", "a").
  final String? symbol;

  /// Retorna verdadero si el valor es conocido numéricamente.
  bool get isKnown => this is KnownScalar;

  /// Retorna verdadero si el escalar representa una incógnita matemática a resolver.
  bool get isUnknown => this is UnknownScalar;

  /// Retorna verdadero si el escalar aún no ha sido especificado/configurado.
  bool get isUnspecified => this is UnspecifiedScalar;

  /// Retorna el valor numérico si es [KnownScalar], o `null` si es [UnknownScalar] o [UnspecifiedScalar].
  double? get valueOrNull => switch (this) {
        KnownScalar(:final value) => value,
        _ => null,
      };

  /// Crea un escalar conocido con valor finito.
  factory PhysicalScalar.known(double value, {String? symbol}) = KnownScalar;

  /// Crea un escalar que representa una incógnita a resolver.
  const factory PhysicalScalar.unknown({String? symbol}) = UnknownScalar;

  /// Crea un escalar en estado no configurado / pendiente.
  const factory PhysicalScalar.unspecified({String? symbol}) = UnspecifiedScalar;
}

/// Escalar con valor numérico concreto y finito.
class KnownScalar extends PhysicalScalar {
  KnownScalar(this.value, {super.symbol}) {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        'value',
        'El valor escalar conocido debe ser un número finito',
      );
    }
  }

  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnownScalar &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          symbol == other.symbol;

  @override
  int get hashCode => Object.hash(value, symbol);

  @override
  String toString() =>
      symbol != null ? 'KnownScalar($symbol = $value)' : 'KnownScalar($value)';
}

/// Escalar que representa una incógnita matemática formal en el ejercicio.
class UnknownScalar extends PhysicalScalar {
  const UnknownScalar({super.symbol});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnknownScalar &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol;

  @override
  int get hashCode => Object.hash(symbol, 'unknown');

  @override
  String toString() =>
      symbol != null ? 'UnknownScalar($symbol = ?)' : 'UnknownScalar(?)';
}

/// Escalar que aún no ha sido definido por el usuario o interfaz.
class UnspecifiedScalar extends PhysicalScalar {
  const UnspecifiedScalar({super.symbol});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnspecifiedScalar &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol;

  @override
  int get hashCode => Object.hash(symbol, 'unspecified');

  @override
  String toString() =>
      symbol != null ? 'UnspecifiedScalar($symbol: pendiente)' : 'UnspecifiedScalar(pendiente)';
}
