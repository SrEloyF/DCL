import 'package:flutter_test/flutter_test.dart';
import 'package:prueba/core/physics/math/vector_2d.dart';
import 'package:prueba/core/physics/models/force_model.dart';
import 'package:prueba/core/physics/models/physical_body.dart';
import 'package:prueba/core/physics/models/physical_scalar.dart';
import 'package:prueba/core/physics/models/physics_problem.dart';

void main() {
  group('PhysicsProblem - Construcción y validaciones', () {
    test('construye problema con id válido y gravedad por defecto', () {
      final problem = PhysicsProblem(id: 'problem_1');

      expect(problem.id, equals('problem_1'));
      expect(problem.gravity.x, equals(0.0));
      expect(problem.gravity.y, closeTo(-9.81, 1e-9));
      expect(problem.bodies, isEmpty);
      expect(problem.forces, isEmpty);
    });

    test('permite configurar gravedad personalizada', () {
      final customGravity = Vector2D(0.0, -1.62); // Luna
      final problem = PhysicsProblem(
        id: 'problem_moon',
        gravity: customGravity,
      );

      expect(problem.gravity.y, closeTo(-1.62, 1e-9));
    });

    test('lanza ArgumentError si el id está vacío', () {
      expect(
        () => PhysicsProblem(id: ''),
        throwsArgumentError,
      );
      expect(
        () => PhysicsProblem(id: '   '),
        throwsArgumentError,
      );
    });

    test('permite inicializar con listas de cuerpos y fuerzas válidas', () {
      final b1 = PhysicalBody(id: 'b1');
      final f1 = ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.weight);

      final problem = PhysicsProblem(
        id: 'p1',
        bodies: [b1],
        forces: [f1],
      );

      expect(problem.bodies.length, equals(1));
      expect(problem.forces.length, equals(1));
      expect(problem.getBody('b1'), equals(b1));
      expect(problem.getForce('f1'), equals(f1));
    });
  });

  group('PhysicsProblem - Gestión de cuerpos y validación de IDs', () {
    test('agrega cuerpo y permite consultarlo', () {
      final problem = PhysicsProblem(id: 'p1');
      final body = PhysicalBody(id: 'b1', name: 'Bloque');

      problem.addBody(body);

      expect(problem.bodies.length, equals(1));
      expect(problem.getBody('b1'), equals(body));
      expect(problem.getBody('b_inexistente'), isNull);
    });

    test('lanza StateError si se intenta agregar un cuerpo con ID duplicado', () {
      final problem = PhysicsProblem(id: 'p1');
      final b1 = PhysicalBody(id: 'b1', name: 'Original');
      final b1Dup = PhysicalBody(id: 'b1', name: 'Duplicado');

      problem.addBody(b1);

      expect(
        () => problem.addBody(b1Dup),
        throwsStateError,
      );
      expect(problem.getBody('b1')!.name, equals('Original'));
    });

    test('updateBody actualiza cuerpo existente y rechaza cuerpo inexistente', () {
      final problem = PhysicsProblem(id: 'p1');
      final b1 = PhysicalBody(id: 'b1', name: 'Original', mass: PhysicalScalar.known(10.0));
      problem.addBody(b1);

      final updatedB1 = b1.copyWith(name: 'Modificado', mass: PhysicalScalar.known(20.0));
      problem.updateBody(updatedB1);
      expect(problem.getBody('b1')!.name, equals('Modificado'));
      expect(problem.getBody('b1')!.mass.valueOrNull, equals(20.0));

      final phantom = PhysicalBody(id: 'fantasma');
      expect(() => problem.updateBody(phantom), throwsArgumentError);
    });
  });

  group('PhysicsProblem - Gestión de fuerzas e integridad referencial', () {
    test('agrega fuerza asociada a un cuerpo existente', () {
      final problem = PhysicsProblem(id: 'p1');
      final body = PhysicalBody(id: 'b1');
      final force = ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.applied);

      problem.addBody(body);
      problem.addForce(force);

      expect(problem.forces.length, equals(1));
      expect(problem.getForce('f1'), equals(force));
    });

    test('lanza ArgumentError si la fuerza referencia a un cuerpo que no existe', () {
      final problem = PhysicsProblem(id: 'p1');
      final force = ForceModel(
        id: 'f1',
        bodyId: 'cuerpo_inexistente',
        type: ForceType.applied,
      );

      expect(
        () => problem.addForce(force),
        throwsArgumentError,
      );
      expect(problem.forces, isEmpty);
    });

    test('lanza StateError si se intenta agregar una fuerza con ID duplicado', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1'));

      problem.addForce(ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.weight));

      expect(
        () => problem.addForce(ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.normal)),
        throwsStateError,
      );
      expect(problem.forces.length, equals(1));
      expect(problem.getForce('f1')!.type, equals(ForceType.weight));
    });

    test('getForcesForBody retorna únicamente las fuerzas del cuerpo consultado', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1'));
      problem.addBody(PhysicalBody(id: 'b2'));

      final f1 = ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.weight);
      final f2 = ForceModel(id: 'f2', bodyId: 'b1', type: ForceType.normal);
      final f3 = ForceModel(id: 'f3', bodyId: 'b2', type: ForceType.weight);

      problem.addForce(f1);
      problem.addForce(f2);
      problem.addForce(f3);

      final forcesB1 = problem.getForcesForBody('b1');
      final forcesB2 = problem.getForcesForBody('b2');
      final forcesB3 = problem.getForcesForBody('b3');

      expect(forcesB1.length, equals(2));
      expect(forcesB1, containsAll([f1, f2]));
      expect(forcesB2.length, equals(1));
      expect(forcesB2, contains(f3));
      expect(forcesB3, isEmpty);
    });

    test('updateForce actualiza fuerza existente y valida cuerpo destino', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1'));
      final f1 = ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.weight);
      problem.addForce(f1);

      final updatedF1 = f1.copyWith(name: 'Peso Nuevo', magnitude: PhysicalScalar.known(98.1));
      problem.updateForce(updatedF1);
      expect(problem.getForce('f1')!.name, equals('Peso Nuevo'));
      expect(problem.getForce('f1')!.magnitude.valueOrNull, equals(98.1));

      final phantomForce = ForceModel(id: 'f_fantasma', bodyId: 'b1', type: ForceType.normal);
      expect(() => problem.updateForce(phantomForce), throwsArgumentError);
    });

    test('removeForce elimina solo la fuerza indicada', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1'));

      final f1 = ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.weight);
      final f2 = ForceModel(id: 'f2', bodyId: 'b1', type: ForceType.normal);

      problem.addForce(f1);
      problem.addForce(f2);

      final removed = problem.removeForce('f1');
      expect(removed, isTrue);
      expect(problem.forces.length, equals(1));
      expect(problem.getForce('f1'), isNull);
      expect(problem.getForce('f2'), equals(f2));

      expect(problem.removeForce('f_inexistente'), isFalse);
    });
  });

  group('PhysicsProblem - Eliminación en cascada de fuerzas al eliminar cuerpo', () {
    test('al eliminar un cuerpo se eliminan en cascada todas sus fuerzas asociadas', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1'));
      problem.addBody(PhysicalBody(id: 'b2'));

      final fB1Peso = ForceModel(id: 'f_b1_peso', bodyId: 'b1', type: ForceType.weight);
      final fB1Norm = ForceModel(id: 'f_b1_norm', bodyId: 'b1', type: ForceType.normal);
      final fB2Peso = ForceModel(id: 'f_b2_peso', bodyId: 'b2', type: ForceType.weight);

      problem.addForce(fB1Peso);
      problem.addForce(fB1Norm);
      problem.addForce(fB2Peso);

      expect(problem.bodies.length, equals(2));
      expect(problem.forces.length, equals(3));

      // Eliminamos el cuerpo b1
      final removed = problem.removeBody('b1');
      expect(removed, isTrue);

      // b1 desaparece, b2 se mantiene
      expect(problem.bodies.length, equals(1));
      expect(problem.getBody('b1'), isNull);
      expect(problem.getBody('b2'), isNotNull);

      // Las fuerzas de b1 desaparecen en cascada, las de b2 se mantienen
      expect(problem.forces.length, equals(1));
      expect(problem.getForce('f_b1_peso'), isNull);
      expect(problem.getForce('f_b1_norm'), isNull);
      expect(problem.getForce('f_b2_peso'), isNotNull);
    });

    test('removeBody retorna false si el cuerpo no existía', () {
      final problem = PhysicsProblem(id: 'p1');
      expect(problem.removeBody('fantasma'), isFalse);
    });
  });

  group('PhysicsProblem - Protección de colecciones expuestas (UnmodifiableMapView)', () {
    test('impide modificar el mapa de cuerpos desde el exterior', () {
      final problem = PhysicsProblem(id: 'p1');
      final body = PhysicalBody(id: 'b1');
      problem.addBody(body);

      expect(
        () => problem.bodies['b_bypass'] = PhysicalBody(id: 'b_bypass'),
        throwsUnsupportedError,
      );
      expect(
        () => problem.bodies.remove('b1'),
        throwsUnsupportedError,
      );
      expect(
        () => problem.bodies.clear(),
        throwsUnsupportedError,
      );
    });

    test('impide modificar el mapa de fuerzas desde el exterior', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1'));
      problem.addForce(ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.weight));

      expect(
        () => problem.forces['f_bypass'] = ForceModel(id: 'f_bypass', bodyId: 'b1', type: ForceType.normal),
        throwsUnsupportedError,
      );
      expect(
        () => problem.forces.remove('f1'),
        throwsUnsupportedError,
      );
      expect(
        () => problem.forces.clear(),
        throwsUnsupportedError,
      );
    });

    test('las entidades contenidas son inmutables y copyWith no altera el agregado', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1', mass: PhysicalScalar.known(10.0)));
      problem.addForce(ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.applied, magnitude: PhysicalScalar.known(25.0)));

      final body = problem.bodies['b1']!;
      final newBody = body.copyWith(mass: PhysicalScalar.known(50.0));
      // El agregado sigue teniendo la masa original
      expect(problem.bodies['b1']!.mass.valueOrNull, equals(10.0));
      expect(newBody.mass.valueOrNull, equals(50.0));

      final force = problem.forces['f1']!;
      final newForce = force.copyWith(magnitude: PhysicalScalar.known(100.0));
      // El agregado sigue teniendo la magnitud original
      expect(problem.forces['f1']!.magnitude.valueOrNull, equals(25.0));
      expect(newForce.magnitude.valueOrNull, equals(100.0));
    });
  });

  group('PhysicsProblem - Vista de solo lectura (ReadOnlyPhysicsProblem y PhysicsProblemView)', () {
    test('asReadOnly expone vista de solo lectura y bloquea casts a PhysicsProblem', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1'));
      problem.addForce(ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.weight));

      final readOnly = problem.asReadOnly();
      expect(readOnly.id, equals('p1'));
      expect(readOnly.bodies.length, equals(1));
      expect(readOnly.forces.length, equals(1));
      expect(readOnly.getBody('b1'), isNotNull);
      expect(readOnly.getForce('f1'), isNotNull);

      // Un cast a PhysicsProblem arroja TypeError porque PhysicsProblemView no hereda de PhysicsProblem
      expect(() => readOnly as PhysicsProblem, throwsA(isA<TypeError>()));
    });
  });

  group('PhysicsProblem - Método clear', () {
    test('clear limpia todos los cuerpos y fuerzas del problema', () {
      final problem = PhysicsProblem(id: 'p1');
      problem.addBody(PhysicalBody(id: 'b1'));
      problem.addForce(ForceModel(id: 'f1', bodyId: 'b1', type: ForceType.weight));

      problem.clear();

      expect(problem.bodies, isEmpty);
      expect(problem.forces, isEmpty);
    });
  });
}
