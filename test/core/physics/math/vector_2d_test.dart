import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba/core/physics/math/vector_2d.dart';

void main() {
  group('Vector2D - Construcción y validación de finitud', () {
    test('construye vector con componentes finitas válidas', () {
      final v = Vector2D(3.0, -4.5);
      expect(v.x, equals(3.0));
      expect(v.y, equals(-4.5));
    });

    test('Vector2D.zero tiene componentes (0, 0)', () {
      expect(Vector2D.zero.x, equals(0.0));
      expect(Vector2D.zero.y, equals(0.0));
    });

    test('lanza ArgumentError si x es NaN o infinito', () {
      expect(() => Vector2D(double.nan, 2.0), throwsArgumentError);
      expect(() => Vector2D(double.infinity, 2.0), throwsArgumentError);
      expect(() => Vector2D(double.negativeInfinity, 2.0), throwsArgumentError);
    });

    test('lanza ArgumentError si y es NaN o infinito', () {
      expect(() => Vector2D(1.0, double.nan), throwsArgumentError);
      expect(() => Vector2D(1.0, double.infinity), throwsArgumentError);
      expect(() => Vector2D(1.0, double.negativeInfinity), throwsArgumentError);
    });
  });

  group('Vector2D - Operaciones aritméticas', () {
    test('suma de vectores', () {
      final v1 = Vector2D(1.0, 2.0);
      final v2 = Vector2D(3.0, -1.0);
      final r = v1 + v2;
      expect(r, equals(Vector2D(4.0, 1.0)));
    });

    test('resta de vectores', () {
      final v1 = Vector2D(5.0, 2.0);
      final v2 = Vector2D(2.0, 7.0);
      final r = v1 - v2;
      expect(r, equals(Vector2D(3.0, -5.0)));
    });

    test('negación unaria', () {
      final v = Vector2D(3.0, -4.0);
      expect(-v, equals(Vector2D(-3.0, 4.0)));
    });

    test('multiplicación por escalar finito', () {
      final v = Vector2D(2.0, -3.0);
      final r = v * 2.5;
      expect(r, equals(Vector2D(5.0, -7.5)));
    });

    test('multiplicación lanza ArgumentError si el escalar no es finito', () {
      final v = Vector2D(2.0, 3.0);
      expect(() => v * double.nan, throwsArgumentError);
      expect(() => v * double.infinity, throwsArgumentError);
    });

    test('división por escalar finito no nulo', () {
      final v = Vector2D(6.0, -4.0);
      final r = v / 2.0;
      expect(r, equals(Vector2D(3.0, -2.0)));
    });

    test('división lanza ArgumentError ante división por cero o no finito', () {
      final v = Vector2D(1.0, 2.0);
      expect(() => v / 0.0, throwsArgumentError);
      expect(() => v / -0.0, throwsArgumentError);
      expect(() => v / double.nan, throwsArgumentError);
      expect(() => v / double.infinity, throwsArgumentError);
    });
  });

  group('Vector2D - Álgebra y propiedades geométricas', () {
    test('producto escalar (dot product)', () {
      final v1 = Vector2D(2.0, 3.0);
      final v2 = Vector2D(-1.0, 4.0);
      // 2 * (-1) + 3 * 4 = -2 + 12 = 10
      expect(v1.dot(v2), equals(10.0));

      // Vectores ortogonales: producto punto = 0
      final vX = Vector2D(1.0, 0.0);
      final vY = Vector2D(0.0, 1.0);
      expect(vX.dot(vY), equals(0.0));
    });

    test('producto vectorial 2D (cross product)', () {
      final vX = Vector2D(1.0, 0.0);
      final vY = Vector2D(0.0, 1.0);
      // x * y - y * x = 1 * 1 - 0 * 0 = 1
      expect(vX.cross(vY), equals(1.0));
      expect(vY.cross(vX), equals(-1.0));

      // Vectores colineales: producto cruz = 0
      final v1 = Vector2D(2.0, 4.0);
      final v2 = Vector2D(4.0, 8.0);
      expect(v1.cross(v2), equals(0.0));
    });

    test('magnitud y magnitud al cuadrado', () {
      final v = Vector2D(3.0, 4.0);
      expect(v.magnitudeSquared, equals(25.0));
      expect(v.magnitude, equals(5.0));
    });

    test('angle calcula atan2(y, x) correctamente', () {
      expect(Vector2D(1.0, 0.0).angle, equals(0.0));
      expect(Vector2D(0.0, 1.0).angle, closeTo(math.pi / 2, 1e-12));
      expect(Vector2D(-1.0, 0.0).angle, closeTo(math.pi, 1e-12));
      expect(Vector2D(0.0, -1.0).angle, closeTo(-math.pi / 2, 1e-12));
    });

    test('normalized retorna vector unitario con misma dirección', () {
      final v = Vector2D(3.0, 4.0);
      final u = v.normalized;
      expect(u.magnitude, closeTo(1.0, 1e-12));
      expect(u.x, closeTo(0.6, 1e-12));
      expect(u.y, closeTo(0.8, 1e-12));
    });

    test('normalized en Vector2D.zero retorna Vector2D.zero de forma segura', () {
      final u = Vector2D.zero.normalized;
      expect(u, equals(Vector2D.zero));
    });

    test('rotate rota en sentido antihorario', () {
      final v = Vector2D(1.0, 0.0);
      final rotated90 = v.rotate(math.pi / 2);
      expect(rotated90.x, closeTo(0.0, 1e-12));
      expect(rotated90.y, closeTo(1.0, 1e-12));

      final rotated180 = v.rotate(math.pi);
      expect(rotated180.x, closeTo(-1.0, 1e-12));
      expect(rotated180.y, closeTo(0.0, 1e-12));
    });

    test('rotate lanza ArgumentError si el ángulo no es finito', () {
      final v = Vector2D(1.0, 0.0);
      expect(() => v.rotate(double.nan), throwsArgumentError);
      expect(() => v.rotate(double.infinity), throwsArgumentError);
    });
  });

  group('Vector2D - Igualdad, hashCode y toString', () {
    test('igualdad basada en valores', () {
      final v1 = Vector2D(2.5, -1.0);
      final v2 = Vector2D(2.5, -1.0);
      final v3 = Vector2D(2.5, 1.0);

      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));
      expect(v1, isNot(equals(v3)));
    });

    test('toString retorna formato descriptivo', () {
      expect(Vector2D(1.5, -2.0).toString(), equals('Vector2D(x: 1.5, y: -2.0)'));
    });
  });
}
