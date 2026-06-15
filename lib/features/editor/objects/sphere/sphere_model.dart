import 'package:flutter/material.dart';
import '../../models/diagram_object.dart';

class SphereModel extends DiagramObject {
  SphereModel({
    required super.x,
    required super.y,
    required super.width,
  }) : super(height: width);

  @override
  bool get canRotate => false;

  @override
  bool get canFlipX => false;

  @override
  void resize(double dx, double dy) {
    width = (width + dx).clamp(50, 1000);

    height = width;
  }

  @override
  Widget render({
    required bool selected,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.purple.withOpacity(.2),
        border: Border.all(
          color: selected
              ? Colors.orange
              : Colors.purple,
          width: 3,
        ),
      ),
    );
  }
}