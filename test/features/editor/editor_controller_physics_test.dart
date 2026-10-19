import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba/core/physics/models/force_model.dart';
import 'package:prueba/core/physics/models/physical_body.dart';
import 'package:prueba/core/physics/models/physical_scalar.dart';
import 'package:prueba/core/physics/models/physics_problem.dart';
import 'package:prueba/features/editor/editor_controller.dart';
import 'package:prueba/features/editor/editor_state.dart';
import 'package:prueba/features/editor/objects/block/block_model.dart';
import 'package:prueba/features/editor/objects/ramp/ramp_model.dart';
import 'package:prueba/features/editor/objects/sphere/sphere_model.dart';

void main() {
  group('EditorController - Integración de Física y Encapsulamiento', () {
    late EditorController controller;

    setUp(() {
      controller = EditorController();
      controller.updateViewportSize(const Size(1000, 800));
    });

    test('se puede asociar un cuerpo existente a un bloque existente mediante operaciones oficiales', () {
      controller.addBlock();
      final block = controller.objects.first as BlockModel;

      final body = PhysicalBody(
        id: 'body_block_1',
        name: 'Bloque 1',
        mass: PhysicalScalar.known(5.0),
      );
      controller.addPhysicalBody(body);

      // Asociación explícita
      controller.bindVisualToPhysical(
        visualObjectId: block.id,
        physicalBodyId: body.id,
      );

      expect(controller.getPhysicalBodyId(block.id), equals('body_block_1'));
      expect(controller.getVisualObjectId('body_block_1'), equals(block.id));
      expect(controller.visualToPhysicalMap[block.id], equals('body_block_1'));
    });

    test('addBlock no crea cuerpos físicos automáticamente', () {
      controller.addBlock();
      expect(controller.objects.length, equals(1));
      expect(controller.problem.bodies, isEmpty);
      expect(controller.visualToPhysicalMap, isEmpty);
    });

    test('rechaza la asociación si la figura visual no existe en la escena', () {
      final body = PhysicalBody(id: 'body_1');
      controller.addPhysicalBody(body);

      expect(
        () => controller.bindVisualToPhysical(
          visualObjectId: 'figura_inexistente',
          physicalBodyId: 'body_1',
        ),
        throwsArgumentError,
      );
      expect(controller.visualToPhysicalMap, isEmpty);
      expect(controller.getVisualObjectId('body_1'), isNull);
    });

    test('rechaza la asociación si el cuerpo físico no existe en el problema', () {
      controller.addBlock();
      final block = controller.objects.first;

      expect(
        () => controller.bindVisualToPhysical(
          visualObjectId: block.id,
          physicalBodyId: 'cuerpo_inexistente',
        ),
        throwsArgumentError,
      );
      expect(controller.visualToPhysicalMap, isEmpty);
      expect(controller.getPhysicalBodyId(block.id), isNull);
    });

    test('rechaza asociaciones duplicadas sin corromper el estado', () {
      controller.addBlock();
      controller.addBlock();
      final b1 = controller.objects[0];
      final b2 = controller.objects[1];

      final body1 = PhysicalBody(id: 'body_1');
      final body2 = PhysicalBody(id: 'body_2');
      controller.addPhysicalBody(body1);
      controller.addPhysicalBody(body2);

      // Vínculo inicial b1 <-> body1
      controller.bindVisualToPhysical(
        visualObjectId: b1.id,
        physicalBodyId: body1.id,
      );

      // Intento 1: vincular b1 con otro cuerpo body2
      expect(
        () => controller.bindVisualToPhysical(
          visualObjectId: b1.id,
          physicalBodyId: body2.id,
        ),
        throwsStateError,
      );
      expect(controller.getPhysicalBodyId(b1.id), equals('body_1'));
      expect(controller.getVisualObjectId('body_2'), isNull);

      // Intento 2: vincular otra figura b2 con body1 (ya vinculado)
      expect(
        () => controller.bindVisualToPhysical(
          visualObjectId: b2.id,
          physicalBodyId: body1.id,
        ),
        throwsStateError,
      );
      expect(controller.getPhysicalBodyId(b2.id), isNull);
      expect(controller.getVisualObjectId('body_1'), equals(b1.id));
    });

    test('mover, redimensionar y rotar visualmente el bloque no altera la masa del cuerpo asociado', () {
      controller.addBlock();
      final block = controller.objects.first as BlockModel;

      final body = PhysicalBody(
        id: 'body_b1',
        mass: PhysicalScalar.known(12.5),
      );
      controller.addPhysicalBody(body);
      controller.bindVisualToPhysical(
        visualObjectId: block.id,
        physicalBodyId: body.id,
      );

      final initialX = block.x;
      final initialHeight = block.height;
      final initialAngle = block.angle;

      controller.moveObject(block, const Offset(20, 20));
      controller.resizeObject(block, const Offset(30, 30));
      controller.rotateObject(block, math.pi / 4);

      expect(block.x, isNot(equals(initialX)));
      expect(block.height, isNot(equals(initialHeight)));
      expect(block.angle, isNot(equals(initialAngle)));

      final recordedBody = controller.problem.getBody('body_b1')!;
      expect(recordedBody.mass.isKnown, isTrue);
      expect(recordedBody.mass.valueOrNull, equals(12.5));
      expect(controller.getPhysicalBodyId(block.id), equals('body_b1'));
    });

    test('deleteSelected elimina bloque, cuerpo físico, fuerzas en cascada y notifica exactamente 1 vez', () {
      controller.addBlock();
      final block = controller.objects.first as BlockModel;

      final body1 = PhysicalBody(id: 'body_1');
      final body2 = PhysicalBody(id: 'body_2');
      controller.addPhysicalBody(body1);
      controller.addPhysicalBody(body2);

      final fPeso = ForceModel(id: 'f_peso', bodyId: 'body_1', type: ForceType.weight);
      final fNorm = ForceModel(id: 'f_norm', bodyId: 'body_1', type: ForceType.normal);
      final fB2 = ForceModel(id: 'f_b2', bodyId: 'body_2', type: ForceType.weight);
      controller.addForce(fPeso);
      controller.addForce(fNorm);
      controller.addForce(fB2);

      controller.bindVisualToPhysical(
        visualObjectId: block.id,
        physicalBodyId: body1.id,
      );

      controller.selectObject(block);

      int notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      controller.deleteSelected();

      // Notificación consolidada única
      expect(notificationCount, equals(1));

      // 1. La figura visual desaparece de la escena
      expect(controller.objects, isEmpty);
      expect(controller.selectedObject, isNull);

      // 2. El vínculo desaparece
      expect(controller.getPhysicalBodyId(block.id), isNull);
      expect(controller.getVisualObjectId('body_1'), isNull);
      expect(controller.visualToPhysicalMap, isEmpty);

      // 3. El cuerpo físico desaparece
      expect(controller.problem.getBody('body_1'), isNull);
      expect(controller.problem.bodies.length, equals(1));
      expect(controller.problem.getBody('body_2'), equals(body2));

      // 4. Las fuerzas asociadas se eliminan en cascada
      expect(controller.problem.getForce('f_peso'), isNull);
      expect(controller.problem.getForce('f_norm'), isNull);
      expect(controller.problem.getForce('f_b2'), equals(fB2));
      expect(controller.problem.forces.length, equals(1));
    });

    test('eliminar un bloque sin asociación física sigue funcionando normalmente', () {
      controller.addBlock();
      final block = controller.objects.first;

      controller.selectObject(block);
      controller.deleteSelected();

      expect(controller.objects, isEmpty);
      expect(controller.selectedObject, isNull);
      expect(controller.visualToPhysicalMap, isEmpty);
      expect(controller.problem.bodies, isEmpty);
    });

    test('las figuras no asociadas (rampas, esferas) mantienen su funcionalidad completa', () {
      controller.addBlock();
      controller.addRamp();
      controller.addSphere();

      final block = controller.objects.firstWhere((o) => o is BlockModel);
      final ramp = controller.objects.firstWhere((o) => o is RampModel) as RampModel;
      final sphere = controller.objects.firstWhere((o) => o is SphereModel);

      final body = PhysicalBody(id: 'body_block');
      controller.addPhysicalBody(body);
      controller.bindVisualToPhysical(
        visualObjectId: block.id,
        physicalBodyId: body.id,
      );

      final initialRampX = ramp.x;
      controller.moveObject(ramp, const Offset(300, 0));
      expect(ramp.x, equals(initialRampX + 300));

      final initialMirrored = ramp.mirrored;
      final flipSuccess = controller.flipObject(ramp);
      expect(flipSuccess, isTrue);
      expect(ramp.mirrored, equals(!initialMirrored));

      final initialSphereX = sphere.x;
      controller.moveObject(sphere, const Offset(-20, 0));
      expect(sphere.x, equals(initialSphereX - 20));

      expect(controller.getPhysicalBodyId(block.id), equals('body_block'));
      expect(controller.getPhysicalBodyId(ramp.id), isNull);
      expect(controller.getPhysicalBodyId(sphere.id), isNull);
    });

    test('el mapa de asociaciones expuesto es inmutable', () {
      expect(
        () => controller.visualToPhysicalMap['bypass'] = 'foo',
        throwsUnsupportedError,
      );
      expect(
        () => controller.visualToPhysicalMap.clear(),
        throwsUnsupportedError,
      );
    });

    test('controller.objects es una lista de solo lectura e impide modificaciones estructurales', () {
      controller.addBlock();
      expect(
        () => controller.objects.add(BlockModel(id: 'hack', x: 0, y: 0, width: 10, height: 10)),
        throwsUnsupportedError,
      );
      expect(
        () => controller.objects.clear(),
        throwsUnsupportedError,
      );
    });

    test('controller.problem y controller.state impiden mutaciones y casts hacia tipos concretos', () {
      final body = PhysicalBody(id: 'b1');
      controller.addPhysicalBody(body);

      // Intento de cast a PhysicsProblem
      expect(() => controller.problem as PhysicsProblem, throwsA(isA<TypeError>()));

      // Intento de cast de state a EditorState
      expect(() => controller.state as EditorState, throwsA(isA<TypeError>()));

      // Mapas de bodies y forces son inmutables
      expect(
        () => controller.problem.bodies['hacked'] = PhysicalBody(id: 'hacked'),
        throwsUnsupportedError,
      );
      expect(
        () => controller.problem.forces['hacked'] = ForceModel(id: 'h', bodyId: 'b1', type: ForceType.normal),
        throwsUnsupportedError,
      );
    });

    test('copia defensiva en constructor y en altas previene fugas de referencias mutables', () {
      final extProblem = PhysicsProblem(id: 'ext');
      extProblem.addBody(PhysicalBody(id: 'b_init'));

      final ctrl = EditorController(initialProblem: extProblem);
      expect(ctrl.problem.getBody('b_init'), isNotNull);

      // Mutamos extProblem desde afuera
      extProblem.addBody(PhysicalBody(id: 'b_ext_leak'));
      expect(ctrl.problem.getBody('b_ext_leak'), isNull);

      // Alta con PhysicalBody: llamador conserva body
      final myBody = PhysicalBody(id: 'my_body', mass: PhysicalScalar.known(10.0));
      ctrl.addPhysicalBody(myBody);

      // Si el llamador intenta copyWith o cambiar variables locales, la interna no cambia
      final alteredBody = myBody.copyWith(mass: PhysicalScalar.known(99.0));
      expect(ctrl.problem.getBody('my_body')!.mass.valueOrNull, equals(10.0));
      expect(alteredBody.mass.valueOrNull, equals(99.0));
    });

    test('removePhysicalBody elimina cuerpo y notifica exactamente 1 vez si tuvo éxito', () {
      controller.addBlock();
      final block = controller.objects.first;
      final body = PhysicalBody(id: 'body_rm');
      controller.addPhysicalBody(body);
      controller.bindVisualToPhysical(visualObjectId: block.id, physicalBodyId: body.id);

      int count = 0;
      controller.addListener(() => count++);

      final success = controller.removePhysicalBody('body_rm');
      expect(success, isTrue);
      expect(count, equals(1));
      expect(controller.problem.getBody('body_rm'), isNull);
      expect(controller.getPhysicalBodyId(block.id), isNull);

      // Eliminar cuerpo inexistente retorna false y no notifica
      final failed = controller.removePhysicalBody('body_rm');
      expect(failed, isFalse);
      expect(count, equals(1)); // Sin nueva notificación
    });
  });
}
