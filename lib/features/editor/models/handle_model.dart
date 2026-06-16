import 'package:flutter/material.dart';

enum HandleType {
  move,
  resize,
  rotate,
  flip,
}

class HandleModel {
  const HandleModel({
    required this.type,
    required this.color,
    required this.alignment,
  });

  final HandleType type;
  final Color color;
  final Alignment alignment;
}
