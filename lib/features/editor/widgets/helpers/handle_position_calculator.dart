import 'dart:ui';
import '../../models/diagram_object.dart';
import '../../models/handle_model.dart';

class HandlePositionCalculator {
  static Offset getHandlePosition(HandleModel handle, DiagramObject object) {
    switch (handle.anchor) {
      case HandleAnchor.top:
        return Offset(object.width / 2, 0);
      case HandleAnchor.bottom:
        return Offset(object.width / 2, object.height);
      case HandleAnchor.left:
        return Offset(0, object.height / 2);
      case HandleAnchor.right:
        return Offset(object.width, object.height / 2);
      case HandleAnchor.topCenter:
        return Offset(object.width / 2, -28); // Offset above the object
      case HandleAnchor.topRight:
        return Offset(object.width + 10, -10); // Offset corner
      case HandleAnchor.center:
        return Offset(object.width / 2, object.height / 2);
    }
  }
}
