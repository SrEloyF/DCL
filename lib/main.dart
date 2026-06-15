import 'dart:math';
import 'package:flutter/material.dart';

import 'features/editor/models/diagram_object.dart';
import 'features/editor/objects/block/block_model.dart';
import 'features/editor/objects/ramp/ramp_model.dart';
import 'features/editor/objects/sphere/sphere_model.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EditorScreen(),
    ),
  );
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  List<DiagramObject> objects = [];
  
  DiagramObject? selectedObject;

  double _initialAngle = 0.0;
  double _initialTouchAngle = 0.0;

  final double padding = 60.0;

  void _addBlock() {
    setState(() {
      final obj = BlockModel(x: 100, y: 100, width: 150, height: 150);
      objects.add(obj);
      selectedObject = obj;
    });
  }

  void _addRamp() {
    setState(() {
      final obj = RampModel(x: 150, y: 150, width: 150, height: 150);
      objects.add(obj);
      selectedObject = obj;
    });
  }

  void _addSphere() {
    setState(() {
      final obj = SphereModel(x: 200, y: 200, width: 150);
      objects.add(obj);
      selectedObject = obj;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => selectedObject = null),
            child: const SizedBox(
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          ...objects.map((obj) => _buildObjectNode(obj)),

          if (selectedObject != null && selectedObject!.canFlipX)
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    selectedObject!.flipX();
                  });
                },
                child: const Icon(Icons.flip, color: Colors.black),
              ),
            ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _addBlock,
                  icon: const Icon(Icons.check_box_outline_blank),
                  label: const Text("Cubo"),
                ),
                ElevatedButton.icon(
                  onPressed: _addRamp,
                  icon: const Icon(Icons.signal_cellular_4_bar),
                  label: const Text("Rampa"),
                ),
                ElevatedButton.icon(
                  onPressed: _addSphere,
                  icon: const Icon(Icons.circle_outlined),
                  label: const Text("Esfera"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CONSTRUCTOR INDIVIDUAL DE CADA OBJETO ---
  Widget _buildObjectNode(DiagramObject object) {
    final bool isSelected = object == selectedObject;
    final double angle = object.canRotate ? object.angle : 0.0;

    return Positioned(
      left: object.x - padding,
      top: object.y - padding,
      child: Transform.rotate(
        angle: angle,
        child: SizedBox(
          width: object.width + (padding * 2),
          height: object.height + (padding * 2),
          child: Stack(
            children: [
              Positioned(
                left: padding,
                top: padding,
                width: object.width,
                height: object.height,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => selectedObject = object),
                  onPanStart: (_) => setState(() => selectedObject = object),
                  onPanUpdate: (details) {
                    setState(() {
                      double dx = details.delta.dx;
                      double dy = details.delta.dy;
                      
                      object.move(
                        dx * cos(angle) - dy * sin(angle),
                        dx * sin(angle) + dy * cos(angle),
                      );
                    });
                  },
                  child: object.render(selected: isSelected),
                ),
              ),

              if (isSelected) ...[
                Positioned(
                  left: padding + object.width - 24,
                  top: padding + object.height - 24,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      setState(() {
                        object.resize(details.delta.dx, details.delta.dy);
                      });
                    },
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(child: _construirTirador(Colors.red)),
                    ),
                  ),
                ),

                if (object.canRotate)
                  Positioned(
                    left: padding + (object.width / 2) - 24,
                    top: padding - 30 - 24,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        final centerX = object.x + object.width / 2;
                        final centerY = object.y + object.height / 2;

                        _initialTouchAngle = atan2(
                          details.globalPosition.dy - centerY,
                          details.globalPosition.dx - centerX,
                        );
                        _initialAngle = object.angle;
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          final centerX = object.x + object.width / 2;
                          final centerY = object.y + object.height / 2;

                          final currentTouchAngle = atan2(
                            details.globalPosition.dy - centerY,
                            details.globalPosition.dx - centerX,
                          );

                          object.angle = _initialAngle + (currentTouchAngle - _initialTouchAngle);
                        });
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(child: _construirTirador(Colors.green)),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirTirador(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}