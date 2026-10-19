import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba/core/physics/models/force_model.dart';
import 'package:prueba/core/physics/models/physical_scalar.dart';

void main() {
  group('ForceModel - Construcción y validaciones', () {
    test('construye fuerza con datos válidos', () {
      final force = ForceModel(
        id: 'f1',
        bodyId: 'b1',
        type: ForceType.applied,
        name: 'Fuerza aplicada',
        magnitude: PhysicalScalar.known(50.0),
        direction: PhysicalScalar.known(math.pi / 4),
      );

      expect(force.id, equals('f1'));
      expect(force.bodyId, equals('b1'));
      expect(force.type, equals(ForceType.applied));
      expect(force.name, equals('Fuerza aplicada'));
      expect(force.magnitude.isKnown, isTrue);
      expect(force.magnitude.valueOrNull, equals(50.0));
      expect(force.direction.isKnown, isTrue);
      expect(force.direction.valueOrNull, equals(math.pi / 4));
    });

    test('acepta magnitud cero (0.0) como válida', () {
      final force = ForceModel(
        id: 'f0',
        bodyId: 'b1',
        type: ForceType.friction,
        magnitude: PhysicalScalar.known(0.0),
      );

      expect(force.magnitude.valueOrNull, equals(0.0));
    });

    test('acepta dirección negativa en radianes', () {
      final force = ForceModel(
        id: 'f_neg',
        bodyId: 'b1',
        type: ForceType.applied,
        direction: PhysicalScalar.known(-math.pi / 2),
      );

      expect(force.direction.valueOrNull, equals(-math.pi / 2));
    });

    test('acepta magnitud y dirección como incógnita o no especificada', () {
      final f1 = ForceModel(
        id: 'f1',
        bodyId: 'b1',
        type: ForceType.tension,
        magnitude: const PhysicalScalar.unknown(symbol: 'T'),
        direction: const PhysicalScalar.unknown(symbol: 'θ'),
      );
      expect(f1.magnitude.isUnknown, isTrue);
      expect(f1.direction.isUnknown, isTrue);

      final f2 = ForceModel(
        id: 'f2',
        bodyId: 'b1',
        type: ForceType.weight,
      );
      expect(f2.magnitude.isUnspecified, isTrue);
      expect(f2.direction.isUnspecified, isTrue);
    });

    test('lanza ArgumentError si id o bodyId están vacíos', () {
      expect(
        () => ForceModel(id: '', bodyId: 'b1', type: ForceType.applied),
        throwsArgumentError,
      );
      expect(
        () => ForceModel(id: 'f1', bodyId: '  ', type: ForceType.applied),
        throwsArgumentError,
      );
    });

    test('lanza ArgumentError si la magnitud conocida es negativa', () {
      expect(
        () => ForceModel(
          id: 'f_neg',
          bodyId: 'b1',
          type: ForceType.applied,
          magnitude: PhysicalScalar.known(-1.0),
        ),
        throwsArgumentError,
      );
    });
  });

  group('ForceModel - Inmutabilidad y copyWith', () {
    test('permite actualizar magnitud a valor positivo o cero mediante copyWith', () {
      final force = ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.applied);
      final updated = force.copyWith(magnitude: PhysicalScalar.known(40.0));
      expect(updated.magnitude.valueOrNull, equals(40.0));
      expect(force.magnitude.isUnspecified, isTrue); // Inmutable

      final zeroMag = updated.copyWith(magnitude: PhysicalScalar.known(0.0));
      expect(zeroMag.magnitude.valueOrNull, equals(0.0));
    });

    test('lanza ArgumentError al actualizar magnitud con valor negativo y conserva la original', () {
      final force = ForceModel(
        id: 'f1',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(30.0),
      );
      expect(
        () => force.copyWith(magnitude: PhysicalScalar.known(-5.0)),
        throwsArgumentError,
      );
      expect(force.magnitude.valueOrNull, equals(30.0));
    });

    test('permite actualizar dirección con ángulo positivo, negativo o cero mediante copyWith', () {
      final force = ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.applied);
      final posDir = force.copyWith(direction: PhysicalScalar.known(math.pi / 3));
      expect(posDir.direction.valueOrNull, equals(math.pi / 3));

      final negDir = force.copyWith(direction: PhysicalScalar.known(-math.pi / 6));
      expect(negDir.direction.valueOrNull, equals(-math.pi / 6));

      final zeroDir = force.copyWith(direction: PhysicalScalar.known(0.0));
      expect(zeroDir.direction.valueOrNull, equals(0.0));
    });

    test('permite actualizar nombre y tipo de fuerza', () {
      final force = ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.applied, name: 'Viejo');
      final updated = force.copyWith(name: 'Nuevo', type: ForceType.friction);
      expect(updated.name, equals('Nuevo'));
      expect(updated.type, equals(ForceType.friction));
      expect(force.name, equals('Viejo'));
      expect(force.type, equals(ForceType.applied));
    });
  });

  group('ForceModel - Cálculo vectorial (descomposición en cuadrantes)', () {
    test('Cuadrante 1: ángulo 30° (pi/6 rad)', () {
      final force = ForceModel(
        id: 'f_c1',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(100.0),
        direction: PhysicalScalar.known(math.pi / 6),
      );

      final v = force.vector;
      expect(v, isNotNull);
      expect(v!.x, closeTo(100.0 * math.sqrt(3) / 2, 1e-9));
      expect(v.y, closeTo(50.0, 1e-9));
    });

    test('Cuadrante 2: ángulo 120° (2*pi/3 rad)', () {
      final force = ForceModel(
        id: 'f_c2',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(60.0),
        direction: PhysicalScalar.known(2 * math.pi / 3),
      );

      final v = force.vector;
      expect(v, isNotNull);
      expect(v!.x, closeTo(-30.0, 1e-9));
      expect(v.y, closeTo(60.0 * math.sqrt(3) / 2, 1e-9));
    });

    test('Cuadrante 3: ángulo -135° (-3*pi/4 rad)', () {
      final force = ForceModel(
        id: 'f_c3',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(40.0),
        direction: PhysicalScalar.known(-3 * math.pi / 4),
      );

      final v = force.vector;
      expect(v, isNotNull);
      expect(v!.x, closeTo(-40.0 * math.sqrt(2) / 2, 1e-9));
      expect(v.y, closeTo(-40.0 * math.sqrt(2) / 2, 1e-9));
    });

    test('Cuadrante 4: ángulo -60° (-pi/3 rad)', () {
      final force = ForceModel(
        id: 'f_c4',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(80.0),
        direction: PhysicalScalar.known(-math.pi / 3),
      );

      final v = force.vector;
      expect(v, isNotNull);
      expect(v!.x, closeTo(40.0, 1e-9));
      expect(v.y, closeTo(-80.0 * math.sqrt(3) / 2, 1e-9));
    });

    test('Alineada con los ejes cardinales', () {
      final fRight = ForceModel(
        id: 'f_right',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(10.0),
        direction: PhysicalScalar.known(0.0),
      );
      expect(fRight.vector!.x, closeTo(10.0, 1e-9));
      expect(fRight.vector!.y, closeTo(0.0, 1e-9));

      final fUp = ForceModel(
        id: 'f_up',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(10.0),
        direction: PhysicalScalar.known(math.pi / 2),
      );
      expect(fUp.vector!.x, closeTo(0.0, 1e-9));
      expect(fUp.vector!.y, closeTo(10.0, 1e-9));
    });

    test('magnitud 0 retorna Vector2D.zero', () {
      final fZero = ForceModel(
        id: 'f_zero',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(0.0),
        direction: PhysicalScalar.known(math.pi / 4),
      );
      expect(fZero.vector!.x, closeTo(0.0, 1e-9));
      expect(fZero.vector!.y, closeTo(0.0, 1e-9));
    });

    test('retorna null si magnitud o dirección no son conocidas', () {
      final fUnknownMag = ForceModel(
        id: 'f_u1',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: const PhysicalScalar.unknown(),
        direction: PhysicalScalar.known(0.0),
      );
      expect(fUnknownMag.vector, isNull);

      final fUnspecifiedDir = ForceModel(
        id: 'f_u2',
        bodyId: 'b1',
        type: ForceType.applied,
        magnitude: PhysicalScalar.known(10.0),
        direction: const PhysicalScalar.unspecified(),
      );
      expect(fUnspecifiedDir.vector, isNull);
    });
  });

  group('ForceModel - Igualdad, hashCode y toString', () {
    test('igualdad basada en sus atributos', () {
      final f1 = ForceModel(
        id: 'f1',
        bodyId: 'b1',
        type: ForceType.weight,
        magnitude: PhysicalScalar.known(20.0),
      );
      final f2 = ForceModel(
        id: 'f1',
        bodyId: 'b1',
        type: ForceType.weight,
        magnitude: PhysicalScalar.known(20.0),
      );
      final f3 = ForceModel(
        id: 'f2',
        bodyId: 'b1',
        type: ForceType.weight,
        magnitude: PhysicalScalar.known(20.0),
      );

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1, isNot(equals(f3)));
    });

    test('toString retorna formato legible', () {
      final f = ForceModel(
        id: 'f1',
        bodyId: 'b1',
        type: ForceType.weight,
        name: 'Peso',
        magnitude: PhysicalScalar.known(98.1),
        direction: PhysicalScalar.known(-math.pi / 2),
      );
      expect(f.toString(), contains('ForceModel(id: f1, bodyId: b1'));
    });
  });
}
