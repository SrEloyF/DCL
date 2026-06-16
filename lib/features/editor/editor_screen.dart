import 'package:flutter/material.dart';

import 'editor_controller.dart';
import 'widgets/editor_viewport.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController controller;

  @override
  void initState() {
    super.initState();
    controller = EditorController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = controller.selectedObject;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: EditorViewport(controller: controller),
              ),

              if (selected != null && selected.canFlipX)
                Positioned(
                  top: 48,
                  right: 16,
                  child: SafeArea(
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: () {
                        controller.flipObject(selected);
                      },
                      child: const Icon(Icons.flip, color: Colors.black),
                    ),
                  ),
                ),

              if (selected != null)
                Positioned(
                  top: 48,
                  left: 16,
                  child: SafeArea(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Seleccionado: ${selected.type.name}  '
                          '[x=${selected.x.toStringAsFixed(0)}, '
                          'y=${selected.y.toStringAsFixed(0)}]',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: controller.addBlock,
                        icon: const Icon(Icons.check_box_outline_blank),
                        label: const Text('Bloque'),
                      ),
                      ElevatedButton.icon(
                        onPressed: controller.addRamp,
                        icon: const Icon(Icons.alt_route),
                        label: const Text('Rampa'),
                      ),
                      ElevatedButton.icon(
                        onPressed: controller.addSphere,
                        icon: const Icon(Icons.circle_outlined),
                        label: const Text('Esfera'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
