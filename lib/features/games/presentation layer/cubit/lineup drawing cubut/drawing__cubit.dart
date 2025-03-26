import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

import 'drawing__state.dart';


class DrawingCubit extends Cubit<DrawingState> {
  DrawingCubit() : super(DrawingState());

  void setDrawingMode(DrawingMode mode, BuildContext context) {
    emit(state.copyWith(isDrawing: true, mode: mode));
  }

  void endDrawing() {
    emit(state.copyWith(isDrawing: false, mode: DrawingMode.none));
  }

  void changeColor(Color color) {
    emit(state.copyWith(drawingColor: color));
  }

  void addPoint(Offset point) {
    final newPoints = List<Offset>.from(state.points)..add(point);
    emit(state.copyWith(points: newPoints));
  }

  void clearPoints() {
    emit(state.copyWith(points: []));
  }
}