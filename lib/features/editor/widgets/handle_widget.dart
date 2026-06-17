import 'package:flutter/material.dart';
import '../models/handle_model.dart';

class HandleWidget extends StatelessWidget {
  const HandleWidget({
    super.key,
    required this.type,
    required this.anchor,
  });

  final HandleType type;
  final HandleAnchor anchor;

  @override
  Widget build(BuildContext context) {
    Color color;
    Widget? icon;

    switch (type) {
      case HandleType.resize:
        color = Colors.red;
        break;
      case HandleType.rotate:
        color = Colors.green;
        icon = const Icon(Icons.refresh, size: 14, color: Colors.white);
        break;
      case HandleType.flip:
        color = Colors.orange;
        icon = const Icon(Icons.flip, size: 14, color: Colors.white);
        break;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4),
        ],
      ),
      child: icon != null ? Center(child: icon) : null,
    );
  }
}
