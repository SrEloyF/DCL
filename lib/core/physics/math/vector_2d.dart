import 'dart:math' as math;

/// Vector bidimensional matemático cartesiano e inmutable.
///
/// La convención matemática utilizada es:
/// - Eje X positivo hacia la derecha.
/// - Eje Y positivo hacia arriba.
/// - Ángulos en radianes con 0 en +X, positivos en sentido antihorario.
class Vector2D {
  /// Crea una instancia de [Vector2D] validando en tiempo de ejecución
  /// que las componentes [x] e [y] sean números finitos.
  Vector2D(this.x, this.y) {
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError(
        'Las componentes del vector deben ser números finitos (x: $x, y: $y)',
      );
    }
  }

  const Vector2D._internal(this.x, this.y);

  /// Vector nulo constante (0.0, 0.0).
  static const Vector2D zero = Vector2D._internal(0.0, 0.0);

  final double x;
  final double y;

  Vector2D operator +(Vector2D other) => Vector2D(x + other.x, y + other.y);

  Vector2D operator -(Vector2D other) => Vector2D(x - other.x, y - other.y);

  Vector2D operator -() => Vector2D(-x, -y);

  Vector2D operator *(double scalar) {
    if (!scalar.isFinite) {
      throw ArgumentError.value(
        scalar,
        'scalar',
        'El escalar debe ser un número finito',
      );
    }
    return Vector2D(x * scalar, y * scalar);
  }

  Vector2D operator /(double scalar) {
    if (!scalar.isFinite || scalar == 0.0) {
      throw ArgumentError.value(
        scalar,
        'scalar',
        'No se puede dividir por cero o por un número no finito',
      );
    }
    return Vector2D(x / scalar, y / scalar);
  }

  /// Producto escalar (dot product): x1 * x2 + y1 * y2.
  double dot(Vector2D other) => x * other.x + y * other.y;

  /// Producto vectorial 2D (pseudo-escalar / determinante 2x2): x1 * y2 - y1 * x2.
  double cross(Vector2D other) => x * other.y - y * other.x;

  /// Magnitud al cuadrado del vector: x^2 + y^2.
  double get magnitudeSquared => x * x + y * y;

  /// Magnitud (módulo) euclídea del vector.
  double get magnitude => math.sqrt(magnitudeSquared);

  /// Ángulo polar en radianes en el rango (-pi, pi], medido desde +X en sentido antihorario.
  double get angle => math.atan2(y, x);

  /// Retorna un vector unitario en la misma dirección.
  /// Si el vector actual tiene magnitud 0, retorna [Vector2D.zero] para evitar divisiones indeterminadas.
  Vector2D get normalized {
    final mag = magnitude;
    if (mag == 0.0) return Vector2D.zero;
    return this / mag;
  }

  /// Rota el vector por [angleRad] radianes en sentido antihorario.
  Vector2D rotate(double angleRad) {
    if (!angleRad.isFinite) {
      throw ArgumentError.value(
        angleRad,
        'angleRad',
        'El ángulo debe ser un número finito',
      );
    }
    final c = math.cos(angleRad);
    final s = math.sin(angleRad);
    return Vector2D(x * c - y * s, x * s + y * c);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector2D &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vector2D(x: $x, y: $y)';
}
