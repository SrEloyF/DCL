import 'package:flutter_test/flutter_test.dart';
import 'package:prueba/core/physics/models/physical_scalar.dart';

void main() {
  group('PhysicalScalar - KnownScalar', () {
    test('construye con valor positivo y símbolo opcional', () {
      final s = PhysicalScalar.known(12.5, symbol: 'm');
      expect(s.isKnown, isTrue);
      expect(s.isUnknown, isFalse);
      expect(s.isUnspecified, isFalse);
      expect(s.valueOrNull, equals(12.5));
      expect(s.symbol, equals('m'));
      expect((s as KnownScalar).value, equals(12.5));
    });

    test('el valor cero (0.0) es un valor conocido válido', () {
      final s = PhysicalScalar.known(0.0, symbol: 'F');
      expect(s.isKnown, isTrue);
      expect(s.valueOrNull, equals(0.0));
      expect((s as KnownScalar).value, equals(0.0));
    });

    test('un valor negativo es válido para un escalar general', () {
      final s = PhysicalScalar.known(-9.81, symbol: 'g');
      expect(s.isKnown, isTrue);
      expect(s.valueOrNull, equals(-9.81));
    });

    test('lanza ArgumentError si el valor no es finito (NaN, Infinity, -Infinity)', () {
      expect(() => PhysicalScalar.known(double.nan), throwsArgumentError);
      expect(() => PhysicalScalar.known(double.infinity), throwsArgumentError);
      expect(() => PhysicalScalar.known(double.negativeInfinity), throwsArgumentError);
    });
  });

  group('PhysicalScalar - UnknownScalar', () {
    test('representa una incógnita matemática sin valor asignado', () {
      const s = PhysicalScalar.unknown(symbol: 'F_N');
      expect(s.isKnown, isFalse);
      expect(s.isUnknown, isTrue);
      expect(s.isUnspecified, isFalse);
      expect(s.valueOrNull, isNull);
      expect(s.symbol, equals('F_N'));
    });
  });

  group('PhysicalScalar - UnspecifiedScalar', () {
    test('representa un dato pendiente de configuración sin valor asignado', () {
      const s = PhysicalScalar.unspecified(symbol: 'μ');
      expect(s.isKnown, isFalse);
      expect(s.isUnknown, isFalse);
      expect(s.isUnspecified, isTrue);
      expect(s.valueOrNull, isNull);
      expect(s.symbol, equals('μ'));
    });
  });

  group('PhysicalScalar - Distinción semántica estricta', () {
    test('distingue entre cero conocido, incógnita y dato no especificado', () {
      final zero = PhysicalScalar.known(0.0);
      const unknown = PhysicalScalar.unknown();
      const unspecified = PhysicalScalar.unspecified();

      expect(zero, isNot(equals(unknown)));
      expect(zero, isNot(equals(unspecified)));
      expect(unknown, isNot(equals(unspecified)));

      expect(zero.valueOrNull, equals(0.0));
      expect(unknown.valueOrNull, isNull);
      expect(unspecified.valueOrNull, isNull);
    });

    test('permite pattern matching exhaustivo en Dart 3', () {
      String describe(PhysicalScalar scalar) => switch (scalar) {
            KnownScalar(:final value, :final symbol) => '$symbol=$value',
            UnknownScalar(:final symbol) => '$symbol=?',
            UnspecifiedScalar(:final symbol) => '$symbol:pendiente',
          };

      expect(describe(PhysicalScalar.known(5.0, symbol: 'm')), equals('m=5.0'));
      expect(describe(const PhysicalScalar.unknown(symbol: 'F')), equals('F=?'));
      expect(describe(const PhysicalScalar.unspecified(symbol: 'a')), equals('a:pendiente'));
    });
  });

  group('PhysicalScalar - Igualdad, hashCode y toString', () {
    test('igualdad entre KnownScalar', () {
      final s1 = PhysicalScalar.known(10.0, symbol: 'm');
      final s2 = PhysicalScalar.known(10.0, symbol: 'm');
      final s3 = PhysicalScalar.known(10.0, symbol: 'F');
      final s4 = PhysicalScalar.known(20.0, symbol: 'm');

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
      expect(s1, isNot(equals(s4)));
    });

    test('igualdad entre UnknownScalar', () {
      const u1 = PhysicalScalar.unknown(symbol: 'x');
      const u2 = PhysicalScalar.unknown(symbol: 'x');
      const u3 = PhysicalScalar.unknown(symbol: 'y');

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
      expect(u1, isNot(equals(u3)));
    });

    test('igualdad entre UnspecifiedScalar', () {
      const p1 = PhysicalScalar.unspecified(symbol: 'x');
      const p2 = PhysicalScalar.unspecified(symbol: 'x');
      const p3 = PhysicalScalar.unspecified(symbol: 'y');

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('toString retorna formato legible según el estado', () {
      expect(PhysicalScalar.known(5.0, symbol: 'm').toString(), equals('KnownScalar(m = 5.0)'));
      expect(PhysicalScalar.known(5.0).toString(), equals('KnownScalar(5.0)'));
      expect(const PhysicalScalar.unknown(symbol: 'F').toString(), equals('UnknownScalar(F = ?)'));
      expect(const PhysicalScalar.unknown().toString(), equals('UnknownScalar(?)'));
      expect(const PhysicalScalar.unspecified(symbol: 'a').toString(), equals('UnspecifiedScalar(a: pendiente)'));
      expect(const PhysicalScalar.unspecified().toString(), equals('UnspecifiedScalar(pendiente)'));
    });
  });
}
