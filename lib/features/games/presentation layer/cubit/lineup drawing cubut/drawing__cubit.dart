import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'drawing__state.dart';

class DrawingCubit extends Cubit<DrawingState> {
  DrawingCubit() : super(const DrawingState());

  void setDrawingMode(DrawingMode mode) {
    emit(state.copyWith(
      isDrawing: true,
      currentMode: mode,
      currentPoints: [],
      selectedDrawingIndex: null,
    ));
    print('Set drawing mode to: $mode');
  }

  void startDrawing(Offset position) {
    if (state.isDrawing && state.currentMode != DrawingMode.none) {
      emit(state.copyWith(currentPoints: [position]));
      print('Started drawing at: $position, mode: ${state.currentMode}');
    }
  }

  void updateDrawing(Offset position, {double? maxWidth, double? maxHeight}) {
    if (!state.isDrawing || state.currentMode == DrawingMode.none) return;

    Offset clampedPosition = position;
    if (maxWidth != null && maxHeight != null) {
      clampedPosition = Offset(
        position.dx.clamp(0.0, maxWidth),
        position.dy.clamp(0.0, maxHeight),
      );
    }

    final newPoints = List<Offset>.from(state.currentPoints);
    if (state.currentMode == DrawingMode.free) {
      newPoints.add(clampedPosition);
    } else if (newPoints.length < 2) {
      newPoints.add(clampedPosition);
    } else {
      newPoints[1] = clampedPosition;
    }
    emit(state.copyWith(currentPoints: newPoints));
    print('Updated drawing to: $clampedPosition, points: ${newPoints.length}');
  }

  void endDrawing() {
    if (state.currentPoints.isNotEmpty && state.currentMode != DrawingMode.none) {
      final newDrawing = DrawingItem(
        type: state.currentMode,
        points: List<Offset>.from(state.currentPoints),
        color: state.currentColor,
      );
      final updatedDrawings = List<DrawingItem>.from(state.drawings)..add(newDrawing);
      emit(state.copyWith(
        isDrawing: false,
        currentMode: DrawingMode.none,
        currentPoints: [],
        drawings: updatedDrawings,
        redoStack: [],
      ));
      print('Ended drawing, added: $newDrawing, total drawings: ${updatedDrawings.length}');
    } else {
      emit(state.copyWith(
        isDrawing: false,
        currentMode: DrawingMode.none,
        currentPoints: [],
      ));
      print('Drawing ended with no points');
    }
  }

  void changeColor(Color color) {
    emit(state.copyWith(currentColor: color));
    print('Changed currentColor to: $color, existing drawings: ${state.drawings.map((d) => d.color).toList()}');
  }

  void undoDrawing() {
    if (state.drawings.isNotEmpty) {
      final lastDrawing = state.drawings.last;
      final updatedDrawings = List<DrawingItem>.from(state.drawings)..removeLast();
      final updatedRedoStack = List<DrawingItem>.from(state.redoStack)..add(lastDrawing);
      emit(state.copyWith(
        drawings: updatedDrawings,
        redoStack: updatedRedoStack,
        selectedDrawingIndex: null,
      ));
      print('Undo: Moved last drawing to redo stack');
    }
  }

  void redoDrawing() {
    if (state.redoStack.isNotEmpty) {
      final lastRedo = state.redoStack.last;
      final updatedRedoStack = List<DrawingItem>.from(state.redoStack)..removeLast();
      final updatedDrawings = List<DrawingItem>.from(state.drawings)..add(lastRedo);
      emit(state.copyWith(
        drawings: updatedDrawings,
        redoStack: updatedRedoStack,
        selectedDrawingIndex: null,
      ));
      print('Redo: Restored last undone drawing');
    }
  }

  void clearDrawings() {
    emit(state.copyWith(
      drawings: [],
      redoStack: [],
      currentPoints: [],
      isDrawing: false,
      currentMode: DrawingMode.none,
      selectedDrawingIndex: null,
    ));
    print('Cleared all drawings');
  }

  void selectDrawing(Offset position) {
    if (state.isDrawing) return;

    int? selectedIndex;
    const double tapTolerance = 20.0;

    for (int i = state.drawings.length - 1; i >= 0; i--) {
      final drawing = state.drawings[i];
      for (var point in drawing.points) {
        if ((point - position).distance < tapTolerance) {
          selectedIndex = i;
          break;
        }
      }
      if (selectedIndex != null) break;
    }

    emit(state.copyWith(selectedDrawingIndex: selectedIndex));
    print('Selected drawing index: $selectedIndex');
  }

  void moveDrawing(Offset delta, {double? maxWidth, double? maxHeight}) {
    if (state.selectedDrawingIndex == null) return;

    final index = state.selectedDrawingIndex!;
    final drawing = state.drawings[index];
    final updatedPoints = drawing.points.map((point) {
      double newDx = (point.dx + delta.dx).clamp(0.0, maxWidth ?? double.infinity);
      double newDy = (point.dy + delta.dy).clamp(0.0, maxHeight ?? double.infinity);
      return Offset(newDx, newDy);
    }).toList();

    final updatedDrawing = drawing.copyWith(points: updatedPoints);
    final updatedDrawings = List<DrawingItem>.from(state.drawings);
    updatedDrawings[index] = updatedDrawing;

    emit(state.copyWith(drawings: updatedDrawings));
    print('Moved drawing $index by delta: $delta');
  }

  void deselectDrawing() {
    emit(state.copyWith(selectedDrawingIndex: null));
    print('Deselected drawing');
  }

  void undoDrawingForFrame(int timestamp, List<Map<String, dynamic>> videoLines, Function(DrawingItem, int) removeCallback) {
    if (state.drawings.isNotEmpty) {
      // Get drawings for the current timestamp from videoLines
      final currentFrameDrawings = videoLines
          .where((line) => line['timestamp'] == timestamp)
          .map((line) => line['drawing'] as DrawingItem)
          .toList();

      if (currentFrameDrawings.isNotEmpty) {
        final lastDrawing = currentFrameDrawings.last;
        final updatedRedoStack = List<DrawingItem>.from(state.redoStack)..add(lastDrawing);

        // Update videoLines by removing the last drawing for this timestamp
        removeCallback(lastDrawing, timestamp);

        // Update DrawingCubit state with the filtered drawings for this frame
        final updatedDrawings = currentFrameDrawings..removeLast();
        emit(state.copyWith(
          drawings: updatedDrawings,
          redoStack: updatedRedoStack,
        ));
      }
    }
  }

  // New method for frame-specific redo
  void redoDrawingForFrame(int timestamp, Function(DrawingItem, int) addCallback) {
    if (state.redoStack.isNotEmpty) {
      final lastRedo = state.redoStack.last;
      final updatedRedoStack = List<DrawingItem>.from(state.redoStack)..removeLast();
      final updatedDrawings = List<DrawingItem>.from(state.drawings)..add(lastRedo);

      // Add the drawing back to VideoEditingCubit for this timestamp
      addCallback(lastRedo, timestamp);

      emit(state.copyWith(
        drawings: updatedDrawings,
        redoStack: updatedRedoStack,
      ));
    }
  }
}