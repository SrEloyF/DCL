# Project Overview: Prueba Editor

This project is a 2D interactive scene editor built with Flutter. It allows users to place, move, resize, and rotate various objects (Blocks, Ramps, and Spheres) on a canvas. The project uses a custom rendering engine based on Flutter's `CustomPainter`.

## Core Technologies
- **Flutter:** UI framework and rendering engine.
- **Dart:** Programming language.
- **Custom Painter:** Used for efficient 2D drawing of the scene and objects.

## Architecture

The project follows a feature-driven architecture, with the main editor logic located in `lib/features/editor`.

### Key Components
- **Models (`lib/features/editor/models`):** 
    - `DiagramObject`: Base abstract class for all scene objects.
    - `SceneModel`: Defines the environment (world size, ground level, grid).
- **Controller & State:**
    - `EditorController`: Orchestrates the editor logic (adding, selecting, moving objects).
    - `EditorState`: Holds the current state of the scene (objects, selection).
- **Objects (`lib/features/editor/objects`):** Specialized object types (Block, Ramp, Sphere), each with its own model and painter.
- **Widgets (`lib/features/editor/widgets`):** 
    - `EditorCanvas`: The main drawing area.
    - `EditorViewport`: Manages the view and interactions (gestures).
    - `ObjectOverlay`: Displays interaction handles (resize, rotate) for the selected object.

## Building and Running

### Prerequisites
- Flutter SDK (version specified in `pubspec.yaml`).

### Commands
- **Run the app:** `flutter run`
- **Install dependencies:** `flutter pub get`
- **Run tests:** `flutter test`
- **Build for Web:** `flutter build web`
- **Build for Android:** `flutter build apk`

## Development Conventions

### Coding Style
- Always write scalable code; if you are going to add new functionality, try to extend existing behavior through new abstractions or components, rather than continually modifying code that already has a defined responsibility.
- Prefer composition over deep inheritance where possible.

### Testing
- Widget tests are located in the `test/` directory.
- Use `flutter test` to run all tests.
- Add new tests for every new feature or bug fix.

### Scene Constants
- Global constants for the scene (e.g., world size, grid step) are defined in `lib/core/constants/scene_constants.dart`.

## Interaction Logic
- **Selection:** Handled by `EditorViewport` through hit testing.
- **Movement:** Objects can be dragged across the canvas.
- **Transformations:** Resizing and rotating are performed via handles displayed on the `ObjectOverlay`.
- **Clamping:** Objects are clamped to the scene boundaries in `EditorController`.
