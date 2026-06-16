import 'package:flutter/widgets.dart';

class SceneModel {
  const SceneModel({
    required this.worldSize,
    required this.groundY,
    required this.gridStep,
  });

  final Size worldSize;
  final double groundY;
  final double gridStep;
}
