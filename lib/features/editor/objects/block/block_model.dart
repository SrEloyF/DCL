import 'package:flutter/material.dart';
import '../../models/diagram_object.dart';

class BlockModel extends DiagramObject {
  BlockModel({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
  });

  @override
  bool get canRotate => true;

  @override
  bool get canFlipX => false;

  @override
  Widget render({
    required bool selected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.2),
        border: Border.all(
          color: selected
              ? Colors.orange
              : Colors.blue,
          width: 3,
        ),
      ),
    );
  }
}