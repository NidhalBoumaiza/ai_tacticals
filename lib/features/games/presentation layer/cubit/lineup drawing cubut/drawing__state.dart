import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum DrawingMode {
  none,
  free,
  circle,
  arrow,
  player
}

@immutable
class DrawingItem {
  final DrawingMode type;
  final List<Offset> points;
  final Color color;
  final String? playerId;

  const DrawingItem({
    required this.type,
    required this.points,
    required this.color,
    this.playerId,
  });

  DrawingItem copyWith({
    DrawingMode? type,
    List<Offset>? points,
    Color? color,
    String? playerId,
  }) {
    return DrawingItem(
      type: type ?? this.type,
      points: points ?? this.points,
      color: color ?? this.color,
      playerId: playerId ?? this.playerId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawingItem &&
        other.type == type &&
        listEquals(other.points, points) &&
        other.color == color &&
        other.playerId == playerId;
  }

  @override
  int get hashCode => Object.hash(type, points, color, playerId);
}

@immutable
class DrawingState {
  final bool isDrawing;
  final DrawingMode currentMode;
  final Color currentColor;
  final List<Offset> currentPoints;
  final List<DrawingItem> drawings;
  final List<DrawingItem> redoStack;
  final int? selectedDrawingIndex;

  const DrawingState({
    this.isDrawing = false,
    this.currentMode = DrawingMode.none,
    this.currentColor = Colors.red,
    this.currentPoints = const [],
    this.drawings = const [],
    this.redoStack = const [],
    this.selectedDrawingIndex,
  });

  DrawingState copyWith({
    bool? isDrawing,
    DrawingMode? currentMode,
    Color? currentColor,
    List<Offset>? currentPoints,
    List<DrawingItem>? drawings,
    List<DrawingItem>? redoStack,
    int? selectedDrawingIndex,
  }) {
    return DrawingState(
      isDrawing: isDrawing ?? this.isDrawing,
      currentMode: currentMode ?? this.currentMode,
      currentColor: currentColor ?? this.currentColor,
      currentPoints: currentPoints ?? this.currentPoints,
      drawings: drawings ?? this.drawings,
      redoStack: redoStack ?? this.redoStack,
      selectedDrawingIndex: selectedDrawingIndex ?? this.selectedDrawingIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawingState &&
        other.isDrawing == isDrawing &&
        other.currentMode == currentMode &&
        other.currentColor == currentColor &&
        listEquals(other.currentPoints, currentPoints) &&
        listEquals(other.drawings, drawings) &&
        listEquals(other.redoStack, redoStack) &&
        other.selectedDrawingIndex == selectedDrawingIndex;
  }

  @override
  int get hashCode {
    return Object.hash(
      isDrawing,
      currentMode,
      currentColor,
      currentPoints,
      drawings,
      redoStack,
      selectedDrawingIndex,
    );
  }
}