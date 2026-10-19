import 'package:flutter_test/flutter_test.dart';
import 'package:prueba/core/physics/models/physical_body.dart';
import 'package:prueba/core/physics/models/physical_scalar.dart';

void main() {
  group('PhysicalBody - Construcción y validaciones', () {
    test('construye cuerpo con masa positiva conocida', () {
      final body = PhysicalBody(
        id: 'body_1',
        name: 'Bloque A',
        mass: PhysicalScalar.known(5.0),
      );

      expect(body.id, equals('body_1'));
      expect(body.name, equals('Bloque A'));
      expect(body.mass.isKnown, isTrue);
      expect(body.mass.valueOrNull, equals(5.0));
    });

    test('acepta masa cero (0.0) como masa conocida válida', () {
      final body = PhysicalBody(
        id: 'body_massless',
        name: 'Cuerpo ideal',
        mass: PhysicalScalar.known(0.0),
      );

      expect(body.mass.isKnown, isTrue);
      expect(body.mass.valueOrNull, equals(0.0));
    });

    test('acepta masa como incógnita (?)', () {
      final body = PhysicalBody(
        id: 'body_unknown',
        mass: const PhysicalScalar.unknown(),
      );

      expect(body.mass.isUnknown, isTrue);
      expect(body.mass.valueOrNull, isNull);
    });

    test('por defecto asigna masa no especificada con símbolo "m"', () {
      final body = PhysicalBody(id: 'body_default');

      expect(body.mass.isUnspecified, isTrue);
      expect(body.mass.symbol, equals('m'));
      expect(body.mass.valueOrNull, isNull);
    });

    test('lanza ArgumentError si el id está vacío o en blanco', () {
      expect(
        () => PhysicalBody(id: ''),
        throwsArgumentError,
      );
      expect(
        () => PhysicalBody(id: '   '),
        throwsArgumentError,
      );
    });

    test('lanza ArgumentError si la masa conocida es negativa', () {
      expect(
        () => PhysicalBody(
          id: 'body_neg',
          mass: PhysicalScalar.known(-0.1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('PhysicalBody - Inmutabilidad y copyWith', () {
    test('copyWith retorna una nueva instancia con masa actualizada positiva o cero', () {
      final body = PhysicalBody(id: 'b1', name: 'Bloque');
      final updated = body.copyWith(mass: PhysicalScalar.known(10.0));

      expect(identical(body, updated), isFalse);
      expect(updated.id, equals('b1'));
      expect(updated.name, equals('Bloque'));
      expect(updated.mass.valueOrNull, equals(10.0));
      expect(body.mass.isUnspecified, isTrue); // La instancia original no se modifica

      final zeroMass = updated.copyWith(mass: PhysicalScalar.known(0.0));
      expect(zeroMass.mass.valueOrNull, equals(0.0));
    });

    test('copyWith permite actualizar a incógnita o no especificada', () {
      final body = PhysicalBody(id: 'b1', mass: PhysicalScalar.known(10.0));
      final unknownBody = body.copyWith(mass: const PhysicalScalar.unknown(symbol: 'm_1'));
      expect(unknownBody.mass.isUnknown, isTrue);

      final unspecifiedBody = unknownBody.copyWith(mass: const PhysicalScalar.unspecified());
      expect(unspecifiedBody.mass.isUnspecified, isTrue);
    });

    test('copyWith permite actualizar el nombre conservando masa e id', () {
      final body = PhysicalBody(id: 'b1', name: 'Original', mass: PhysicalScalar.known(5.0));
      final renamed = body.copyWith(name: 'Nuevo Nombre');

      expect(renamed.id, equals('b1'));
      expect(renamed.name, equals('Nuevo Nombre'));
      expect(renamed.mass.valueOrNull, equals(5.0));
      expect(body.name, equals('Original'));
    });

    test('lanza ArgumentError si copyWith recibe masa negativa y conserva la original intacta', () {
      final body = PhysicalBody(id: 'b1', mass: PhysicalScalar.known(8.0));
      expect(
        () => body.copyWith(mass: PhysicalScalar.known(-2.0)),
        throwsArgumentError,
      );
      expect(body.mass.valueOrNull, equals(8.0));
    });
  });

  group('PhysicalBody - Igualdad, hashCode y toString', () {
    test('igualdad basada en id, name y mass', () {
      final b1 = PhysicalBody(id: 'b1', name: 'Bloque', mass: PhysicalScalar.known(5.0));
      final b2 = PhysicalBody(id: 'b1', name: 'Bloque', mass: PhysicalScalar.known(5.0));
      final b3 = PhysicalBody(id: 'b2', name: 'Bloque', mass: PhysicalScalar.known(5.0));

      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
      expect(b1, isNot(equals(b3)));
    });

    test('toString retorna formato representativo', () {
      final body = PhysicalBody(id: 'b1', name: 'B1', mass: PhysicalScalar.known(4.0));
      expect(
        body.toString(),
        equals('PhysicalBody(id: b1, name: "B1", mass: KnownScalar(4.0))'),
      );
    });
  });
}
