---
trigger: always_on
description: Architecture, structure, interaction rules, and conventions for the 2D interactive scene editor.
---

# Project Overview: Prueba Editor

This project is a 2D interactive scene editor built with Flutter. It enables users to place, drag, resize, rotate, and flip various geometric objects (Blocks, Ramps, Spheres) on an expansive 2D canvas with pan and zoom capabilities. The project combines Flutter's `CustomPainter` rendering with an extensible object-oriented architecture, custom Separating Axis Theorem (SAT) collision detection, smart spiral spawning, and gesture-driven interaction overlays.

## Core Technologies
- **Flutter & Dart:** UI framework and language (Material 3 enabled).
- **Custom Painter:** Low-level 2D rendering for the scene canvas (grid, ground) and individual objects.
- **InteractiveViewer & TransformationController:** Camera pan and zoom navigation across the scene.
- **Separating Axis Theorem (SAT):** Fine-grained collision detection between convex polygons (rectangles, triangles) and circles.
- **ChangeNotifier & AnimatedBuilder:** Reactive state management for editor mutations and viewport updates.

---

## Directory & File Structure

```text
lib/
├── app.dart                                # MaterialApp entry point, theme configuration
├── main.dart                               # Application runner
├── core/                                   # Cross-cutting foundational utilities and geometry
│   ├── constants/
│   │   └── scene_constants.dart            # Global world dimensions, grid step, ground level, scale limits
│   ├── geometry/
│   │   ├── hit_test.dart                   # Point-in-rect testing helper
│   │   ├── scene_collision.dart            # SAT collision engine (Circle, Polygon, Box, Triangle)
│   │   ├── snap.dart                       # Grid snapping algorithm
│   │   └── world_bounds.dart               # Rectangular world bounds data model
│   └── utils/
│       └── id_generator.dart               # Auto-incrementing unique ID provider for diagram objects
├── shared/
│   └── theme/
│       └── app_theme.dart                  # Material 3 light theme definitions
└── features/
    └── editor/                             # Main editor feature module
        ├── editor_controller.dart          # Central ChangeNotifier orchestrating state & interactions
        ├── editor_screen.dart              # Top-level screen, HUD overlays, object action bar
        ├── editor_state.dart               # Holds scene model, object list, camera, active selection
        ├── interactions/
        │   └── interaction_calculator.dart # Resize deltas and angular rotation calculations (atan2)
        ├── models/
        │   ├── camera_model.dart           # Camera translation, scale, and screen-to-world conversion
        │   ├── diagram_object.dart         # Base abstract model for all placeable entities
        │   ├── handle_model.dart           # Enums for HandleType and HandleAnchor, HandleModel definition
        │   └── scene_model.dart            # Scene specifications (worldSize, groundY, gridStep)
        ├── objects/                        # Modular object definitions (Model, Constraints, Painter)
        │   ├── block/
        │   │   ├── block_constraints.dart  # Block capability flags (canRotate: true, canFlipX: false)
        │   │   ├── block_model.dart        # Block data & resize/rotate handle configuration
        │   │   └── block_painter.dart      # CustomPainter rendering rectangular body and borders
        │   ├── ramp/
        │   │   ├── ramp_constraints.dart   # Ramp capability flags (canRotate: false, canFlipX: true)
        │   │   ├── ramp_model.dart         # Ramp data, mirrored state, flip handles
        │   │   └── ramp_painter.dart       # CustomPainter rendering right-angle triangle path
        │   └── sphere/
        │       ├── sphere_constraints.dart # Sphere capability flags (canRotate: false, canFlipX: false)
        │       ├── sphere_model.dart       # Sphere data, uniform aspect ratio, radius resizing
        │       └── sphere_painter.dart     # CustomPainter rendering circle/oval body and borders
        ├── painters/
        │   └── scene_painter.dart          # CustomPainter for background, grid lines, ground plane
        ├── services/
        │   ├── object_spawn_service.dart   # Viewport-centered spiral search for collision-free spawning
        │   └── scene_constraint_service.dart # Placement validator (world boundaries, ground limit, SAT collisions)
        └── widgets/
            ├── editor_canvas.dart          # Canvas stack (ScenePainter + backdrop click + ObjectOverlays)
            ├── editor_viewport.dart        # InteractiveViewer wrapper syncing camera & viewport size
            ├── handle_widget.dart          # Visual representation of handles (color/icon by HandleType)
            ├── object_overlay.dart         # Gestures, rotation transform, and handles per object
            └── helpers/
                └── handle_position_calculator.dart # Anchor-to-offset mapping for handle positioning
```

---

## Core Architecture & Key Modules

### 1. State Management & Flow
- **`EditorController` (`ChangeNotifier`):**
  - Owns `EditorState`.
  - Coordinates adding (`addBlock`, `addRamp`, `addSphere`), moving, resizing, rotating, flipping, and deleting objects.
  - Maintains camera and viewport size synced from `EditorViewport`.
  - Delegates geometric constraints validation to `SceneConstraintService`.
  - Delegates spawn positioning to `ObjectSpawnService`.
- **`EditorState`:**
  - Encapsulates the `SceneModel`, active `List<DiagramObject>`, current `CameraModel`, and `DiagramObject? selectedObject`.
- **`EditorCanvas` & `EditorScreen`:**
  - Listen to `EditorController` via `AnimatedBuilder` to trigger targeted repaints on state updates.

### 2. Coordinate Systems & Camera
- **World Space:** A fixed virtual coordinate canvas defined in `SceneConstants.worldSize` (e.g. 2600 x 1800). The ground line is located at `SceneConstants.groundY` (1250).
- **Screen / Viewport Space:** Physical pixel dimensions of the user's screen or window.
- **`CameraModel`:**
  - Maintains camera translation `offset` and zoom `scale`.
  - Converts screen touch coordinates to world coordinates via `screenToWorld(Offset screenPoint)`:
    $$\text{worldPoint} = \frac{\text{screenPoint} - \text{offset}}{\text{scale}}$$
- **`EditorViewport`:**
  - Wraps the canvas in Flutter's `InteractiveViewer` with `boundaryMargin`, `minScale` (0.4), and `maxScale` (3.0).
  - Listens to `TransformationController` mutations to keep `EditorController.updateCamera` and `EditorController.updateViewportSize` updated.

### 3. Collision Detection & Constraints (`SceneConstraintService` & `scene_collision.dart`)
- **Separating Axis Theorem (SAT):**
  - Objects are converted into geometric collision shapes (`CollisionCircle` or `CollisionPolygon`) via `getShapeFromObject`.
  - `checkCollision`: Evaluates separating axes between circle-circle, polygon-polygon, and polygon-circle pairs.
  - Supports rotated rectangles (Blocks) and oriented right triangles (Ramps, normal or mirrored).
- **Placement Validation (`isValidPlacement`):**
  - **World Bounds Check:** Entire transformed shape bounds must reside within `[0, 0]` and `[worldSize.width, worldSize.height]`.
  - **Ground Level Check:** Shape must remain strictly above the ground (`rect.bottom <= scene.groundY`).
  - **No Interpenetration:** Candidate shape must not collide with any existing scene object (excluding itself).
- **Enforcement:**
  - Moving, resizing, rotating, and flipping are each guarded (`canMove`, `canResize`, `canRotate`, `canFlip`). Actions that violate constraints are rejected.

### 4. Smart Object Spawning (`ObjectSpawnService`)
- When creating a new object, the initial target is the **center of the current viewport converted to world coordinates**.
- If the center is occupied or invalid, a **radial spiral search** (`findSpawnPosition`) tests 8 angles (0° to 315° in 45° increments) at increasing radii (step size 50px, up to 15 steps).
- The first valid placement that passes `isValidPlacement` is chosen.
- If no valid point is found along the spiral, a fallback position clamped to world bounds is used.

### 5. Interaction & Gesture System
- **Selection:**
  - Tapping or dragging an object's body selects it (`ObjectOverlay.onTapDown`, `onPanStart`).
  - Tapping on the empty canvas backdrop deselects (`EditorCanvas` gesture detector calls `clearSelection()`).
- **Translation / Movement:**
  - Dragging the object body triggers `onPanUpdate`.
  - The gesture delta is rotated by the object's angle using standard 2D rotation:
    $$\Delta x_{\text{world}} = \Delta x \cos\theta - \Delta y \sin\theta$$
    $$\Delta y_{\text{world}} = \Delta x \sin\theta + \Delta y \cos\theta$$
  - Applied only if `SceneConstraintService.canMove` succeeds.
- **Transformation Handles (`HandleWidget` & `HandlePositionCalculator`):**
  - **Resize (Red):** Located at anchors (`top`, `bottom`, `left`, `right`). Modifies object bounds via `transformResize`.
  - **Rotate (Green with refresh icon):** Located at `topCenter`. Uses `atan2` relative to the object's center to track touch angular difference.
  - **Flip (Orange with flip icon):** Located at `topRight`. Toggles horizontal reflection (`mirrored`) on supported objects (e.g. Ramp). Shows feedback if blocked.
- **HUD & Context Controls (`EditorScreen`):**
  - Selection info chip displaying object type and current `[x, y]` coordinates.
  - Floating action buttons for deleting (`Icons.delete_outline`) and flipping (`Icons.flip`) when applicable.

---

## Object Architecture & Extensibility Guide

The project uses an object-oriented, capability-based design. Scene objects inherit from `DiagramObject`:

```text
DiagramObject (abstract base)
 ├── BlockModel  (canRotate: true,  canFlipX: false, 4-edge resize + rotation handle)
 ├── RampModel   (canRotate: false, canFlipX: true,  bottom/side resize + flip handle)
 └── SphereModel (canRotate: false, canFlipX: false, uniform aspect ratio, radius resize)
```

### Steps to Add a New Object Type:
1. **Define Object Type:** Add a new value to `DiagramObjectType` enum in [`diagram_object.dart`](file:///media/eloy/DATOS/proyectos/flutter/dcl/lib/features/editor/models/diagram_object.dart).
2. **Create Constraints Class:** Create `lib/features/editor/objects/<type>/<type>_constraints.dart` defining static capabilities (`canRotate`, `canFlipX`, etc.).
3. **Create Model Class:** Create `lib/features/editor/objects/<type>/<type>_model.dart` extending `DiagramObject`. Provide required handles and override methods like `transformResize` or `applyBounds` if custom aspect-ratio or geometry rules apply.
4. **Create Custom Painter:** Create `lib/features/editor/objects/<type>/<type>_painter.dart` extending `CustomPainter`.
5. **Update Collision Geometry:** In [`scene_collision.dart`](file:///media/eloy/DATOS/proyectos/flutter/dcl/lib/core/geometry/scene_collision.dart), map the new type in `getShapeFromObject` to an appropriate `CollisionShape` (`CollisionCircle` or `CollisionPolygon`).
6. **Register Painter in Overlay:** Add the painter rendering case in `_buildObjectBody` within [`object_overlay.dart`](file:///media/eloy/DATOS/proyectos/flutter/dcl/lib/features/editor/widgets/object_overlay.dart).
7. **Expose Spawn Action:** Add an instantiation method in [`editor_controller.dart`](file:///media/eloy/DATOS/proyectos/flutter/dcl/lib/features/editor/editor_controller.dart) and a corresponding UI trigger button in [`editor_screen.dart`](file:///media/eloy/DATOS/proyectos/flutter/dcl/lib/features/editor/editor_screen.dart).

---

## Development Conventions

- **Separation of Concerns:** 
  - Controllers orchestrate logic; widgets build UI and capture gestures; services perform calculations and constraint checks; painters render pixels.
  - Do not put collision or constraint logic directly inside widgets or painter classes.
- **Composition over Inheritance:** Use capability getters (`canRotate`, `canFlipX`, `handles`) rather than deeply nested inheritance hierarchies.
- **Non-blocking Operations:** Keep geometric calculations lightweight. When validating candidate states, test bounding boxes and SAT axes efficiently.
- **Preserve Documentation Integrity:** Retain existing comments, rationale, and docstrings across modifications.

---

## Building, Running, and Testing

### Prerequisites
- Flutter SDK `^3.11.5` (or latest stable compatible).

### Commands
- **Install dependencies:** `flutter pub get`
- **Run the app:** `flutter run`
- **Run tests:** `flutter test`
- **Analyze codebase:** `flutter analyze`
- **Build for Web:** `flutter build web`
- **Build for Android:** `flutter build apk`
