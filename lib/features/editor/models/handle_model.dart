enum HandleType {
  resize,
  rotate,
  flip,
}

enum HandleAnchor {
  top,
  bottom,
  left,
  right,
  topCenter,
  topRight,
  center,
}

class HandleModel {
  const HandleModel({
    required this.type,
    required this.anchor,
  });

  final HandleType type;
  final HandleAnchor anchor;
}
