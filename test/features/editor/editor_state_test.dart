import 'package:flutter_test/flutter_test.dart';
import 'package:prueba/core/constants/scene_constants.dart';
import 'package:prueba/core/physics/models/force_model.dart';
import 'package:prueba/core/physics/models/physical_body.dart';
import 'package:prueba/core/physics/models/physical_scalar.dart';
import 'package:prueba/core/physics/models/physics_problem.dart';
import 'package:prueba/features/editor/editor_state.dart';
import 'package:prueba/features/editor/models/diagram_object.dart';
import 'package:prueba/features/editor/models/scene_model.dart';
import 'package:prueba/features/editor/objects/block/block_model.dart';

void main() {
  group('EditorState - Integridad y validación de asociaciones directas', () {
    late SceneModel scene;
    late PhysicsProblem problem;
    late BlockModel block1;
    late BlockModel block2;
    late PhysicalBody body1;
    late PhysicalBody body2;

    setUp(() {
      scene = const SceneModel(
        worldSize: SceneConstants.worldSize,
        groundY: SceneConstants.groundY,
        gridStep: SceneConstants.gridStep,
      );
      problem = PhysicsProblem(id: 'problem_test');
      block1 = BlockModel(id: 'block_1', x: 100, y: 100, width: 100, height: 100);
      block2 = BlockModel(id: 'block_2', x: 300, y: 100, width: 100, height: 100);
      body1 = PhysicalBody(id: 'body_1', name: 'Cuerpo 1', mass: PhysicalScalar.known(10.0));
      body2 = PhysicalBody(id: 'body_2', name: 'Cuerpo 2', mass: PhysicalScalar.known(20.0));
      problem.addBody(body1);
      problem.addBody(body2);
    });

    test('1. La asociación directa con una figura inexistente es rechazada', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1],
        problem: problem,
      );

      expect(
        () => state.bind('figura_fantasma', body1.id),
        throwsArgumentError,
      );
      expect(state.visualToPhysicalMap, isEmpty);
      expect(state.getVisualObjectId(body1.id), isNull);
    });

    test('2. La asociación directa con un cuerpo inexistente es rechazada', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1],
        problem: problem,
      );

      expect(
        () => state.bind(block1.id, 'cuerpo_fantasma'),
        throwsArgumentError,
      );
      expect(state.visualToPhysicalMap, isEmpty);
      expect(state.getPhysicalBodyId(block1.id), isNull);
    });

    test('3. No se puede asociar una segunda figura al mismo cuerpo', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1, block2],
        problem: problem,
      );

      // Asociación inicial exitosa: block1 <-> body1
      state.bind(block1.id, body1.id);
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));

      // Intento de asociar block2 al mismo body1
      expect(
        () => state.bind(block2.id, body1.id),
        throwsStateError,
      );

      // Verificamos que block2 no quedó asociado y body1 sigue vinculado solo a block1
      expect(state.getPhysicalBodyId(block2.id), isNull);
      expect(state.getVisualObjectId(body1.id), equals(block1.id));
      expect(state.visualToPhysicalMap.length, equals(1));
    });

    test('4. Una asociación duplicada no modifica ninguno de los mapas', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1, block2],
        problem: problem,
      );

      // Asociación inicial: block1 <-> body1
      state.bind(block1.id, body1.id);

      // Intento duplicado 1: asociar block1 a body2
      expect(
        () => state.bind(block1.id, body2.id),
        throwsStateError,
      );
      expect(state.visualToPhysicalMap.length, equals(1));
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));
      expect(state.getVisualObjectId(body2.id), isNull);

      // Intento duplicado 2: reasociar idéntica tupla block1 <-> body1
      expect(
        () => state.bind(block1.id, body1.id),
        throwsStateError,
      );
      expect(state.visualToPhysicalMap.length, equals(1));
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));
    });

    test('5. La inicialización no permite crear asociaciones inconsistentes con visualToPhysicalMap', () {
      // Caso 5.1: Figura inexistente en la lista de objetos
      expect(
        () => EditorState(
          scene: scene,
          objects: <DiagramObject>[block1],
          problem: problem,
          visualToPhysicalMap: {'figura_invalida': body1.id},
        ),
        throwsArgumentError,
      );

      // Caso 5.2: Cuerpo inexistente en PhysicsProblem
      expect(
        () => EditorState(
          scene: scene,
          objects: <DiagramObject>[block1],
          problem: problem,
          visualToPhysicalMap: {block1.id: 'cuerpo_invalido'},
        ),
        throwsArgumentError,
      );

      // Caso 5.3: Dos figuras apuntando al mismo cuerpo físico
      expect(
        () => EditorState(
          scene: scene,
          objects: <DiagramObject>[block1, block2],
          problem: problem,
          visualToPhysicalMap: {
            block1.id: body1.id,
            block2.id: body1.id,
          },
        ),
        throwsStateError,
      );

      // Caso 5.4: Inicialización válida
      final validState = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1, block2],
        problem: problem,
        visualToPhysicalMap: {
          block1.id: body1.id,
          block2.id: body2.id,
        },
      );
      expect(validState.visualToPhysicalMap.length, equals(2));
      expect(validState.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(validState.getPhysicalBodyId(block2.id), equals(body2.id));
      expect(validState.getVisualObjectId(body1.id), equals(block1.id));
      expect(validState.getVisualObjectId(body2.id), equals(block2.id));
    });

    test('6. Después de una operación fallida, las asociaciones válidas anteriores permanecen intactas', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1, block2],
        problem: problem,
      );

      // Vínculo inicial válido
      state.bind(block1.id, body1.id);
      expect(state.visualToPhysicalMap.length, equals(1));
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));

      // Operación fallida 1: cuerpo inexistente
      expect(() => state.bind(block2.id, 'fantasma'), throwsArgumentError);
      expect(state.visualToPhysicalMap.length, equals(1));
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));

      // Operación fallida 2: figura inexistente
      expect(() => state.bind('fantasma', body2.id), throwsArgumentError);
      expect(state.visualToPhysicalMap.length, equals(1));
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));

      // Operación fallida 3: figura ya asociada
      expect(() => state.bind(block1.id, body2.id), throwsStateError);
      expect(state.visualToPhysicalMap.length, equals(1));
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));
      expect(state.getVisualObjectId(body2.id), isNull);

      // Operación fallida 4: cuerpo ya asociado
      expect(() => state.bind(block2.id, body1.id), throwsStateError);
      expect(state.visualToPhysicalMap.length, equals(1));
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));
      expect(state.getPhysicalBodyId(block2.id), isNull);
    });

    test('unbind y unbindPhysical mantienen consistentes ambas direcciones del mapa', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1],
        problem: problem,
      );

      state.bind(block1.id, body1.id);
      expect(state.getPhysicalBodyId(block1.id), equals(body1.id));
      expect(state.getVisualObjectId(body1.id), equals(block1.id));

      final removed = state.unbind(block1.id);
      expect(removed, isTrue);
      expect(state.getPhysicalBodyId(block1.id), isNull);
      expect(state.getVisualObjectId(body1.id), isNull);
      expect(state.visualToPhysicalMap, isEmpty);
      expect(state.unbind(block1.id), isFalse);

      state.bind(block1.id, body1.id);
      final removedPhysical = state.unbindPhysical(body1.id);
      expect(removedPhysical, isTrue);
      expect(state.getPhysicalBodyId(block1.id), isNull);
      expect(state.getVisualObjectId(body1.id), isNull);
      expect(state.unbindPhysical(body1.id), isFalse);
    });

    test('removePhysicalBody elimina cuerpo, fuerzas en cascada y desvincula la figura', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1],
        problem: problem,
      );
      state.addForce(ForceModel(id: 'f1', bodyId: body1.id, type: ForceType.weight));
      state.bind(block1.id, body1.id);

      expect(state.problem.getBody(body1.id), isNotNull);
      expect(state.problem.getForce('f1'), isNotNull);
      expect(state.isVisualObjectBound(block1.id), isTrue);

      final removed = state.removePhysicalBody(body1.id);
      expect(removed, isTrue);

      expect(state.problem.getBody(body1.id), isNull);
      expect(state.problem.getForce('f1'), isNull);
      expect(state.isVisualObjectBound(block1.id), isFalse);
      expect(state.isPhysicalBodyBound(body1.id), isFalse);

      // Eliminar cuerpo inexistente retorna false
      expect(state.removePhysicalBody('inexistente'), isFalse);
    });

    test('copia defensiva en constructor previene mutaciones desde la referencia externa', () {
      final externalProblem = PhysicsProblem(id: 'ext_problem');
      externalProblem.addBody(PhysicalBody(id: 'ext_b1'));

      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1],
        problem: externalProblem,
      );

      expect(state.problem.getBody('ext_b1'), isNotNull);

      // Modificamos externalProblem desde afuera
      externalProblem.addBody(PhysicalBody(id: 'ext_b2'));
      externalProblem.removeBody('ext_b1');

      // El estado interno de EditorState no fue afectado
      expect(state.problem.getBody('ext_b1'), isNotNull);
      expect(state.problem.getBody('ext_b2'), isNull);
    });

    test('objects es inmutable e impide modificaciones estructurales directas', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1],
        problem: problem,
      );

      expect(
        () => state.objects.add(block2),
        throwsUnsupportedError,
      );
      expect(
        () => state.objects.clear(),
        throwsUnsupportedError,
      );
    });

    test('EditorStateView expone solo lectura y no permite cast a EditorState', () {
      final state = EditorState(
        scene: scene,
        objects: <DiagramObject>[block1],
        problem: problem,
      );
      final view = EditorStateView(state);

      expect(view.scene, equals(scene));
      expect(view.objects.length, equals(1));
      expect(view.problem.bodies.length, equals(2));

      expect(() => view as EditorState, throwsA(isA<TypeError>()));
    });
  });
}
