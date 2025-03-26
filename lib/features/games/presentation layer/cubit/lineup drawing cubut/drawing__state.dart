import 'dart:ui';

import 'package:flutter/material.dart';

enum DrawingMode { none, free, circle, arrow, player }

class DrawingState {
  final bool isDrawing;
  final DrawingMode mode;
  final Color drawingColor;
  final List<Offset> points;

  DrawingState({
    this.isDrawing = false,
    this.mode = DrawingMode.none,
    this.drawingColor = Colors.black,
    this.points = const [],
  });

  DrawingState copyWith({
    bool? isDrawing,
    DrawingMode? mode,
    Color? drawingColor,
    List<Offset>? points,
  }) {
    return DrawingState(
      isDrawing: isDrawing ?? this.isDrawing,
      mode: mode ?? this.mode,
      drawingColor: drawingColor ?? this.drawingColor,
      points: points ?? this.points,
    );
  }
}