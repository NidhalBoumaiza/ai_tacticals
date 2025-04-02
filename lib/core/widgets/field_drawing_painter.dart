import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../features/games/presentation layer/cubit/lineup drawing cubut/drawing__state.dart';

class FieldDrawingPainter extends CustomPainter {
  final List<DrawingItem> drawings;
  final List<Offset> currentPoints;
  final DrawingMode drawingMode;
  final Color drawingColor;
  final int? selectedDrawingIndex;

  FieldDrawingPainter(
      this.drawings,
      this.currentPoints,
      this.drawingMode,
      this.drawingColor,
      this.selectedDrawingIndex,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < drawings.length; i++) {
      final drawing = drawings[i];
      paint.color = drawing.color;
      print('Drawing $i color: ${drawing.color}'); // Debug
      final points = drawing.points;

      if (i == selectedDrawingIndex) {
        paint.strokeWidth = 10.0;
        paint.color = drawing.color.withOpacity(0.8);
      } else {
        paint.strokeWidth = 8.0;
        paint.color = drawing.color;
      }

      switch (drawing.type) {
        case DrawingMode.free:
          for (int j = 0; j < points.length - 1; j++) {
            if (points[j] != null && points[j + 1] != null) {
              canvas.drawLine(points[j], points[j + 1], paint);
            }
          }
          break;
        case DrawingMode.circle:
          if (points.length == 2) {
            final start = points[0];
            final end = points[1];
            final radius = (start - end).distance;
            canvas.drawCircle(start, radius, paint..style = PaintingStyle.stroke);
          }
          break;
        case DrawingMode.arrow:
          if (points.length == 2) {
            _drawArrow(canvas, points[0], points[1], paint);
          }
          break;
        case DrawingMode.player:
          if (points.isNotEmpty) {
            _drawPlayerIcon(canvas, points[0], paint);
          }
          break;
        case DrawingMode.none:
          break;
      }
    }

    if (currentPoints.isNotEmpty && drawingMode != DrawingMode.none) {
      paint.color = drawingColor;
      print('Current drawing color: $drawingColor'); // Debug
      paint.strokeWidth = 8.0;
      switch (drawingMode) {
        case DrawingMode.free:
          for (int i = 0; i < currentPoints.length - 1; i++) {
            canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
          }
          break;
        case DrawingMode.circle:
          if (currentPoints.length == 2) {
            final radius = (currentPoints[0] - currentPoints[1]).distance;
            canvas.drawCircle(currentPoints[0], radius, paint..style = PaintingStyle.stroke);
          }
          break;
        case DrawingMode.arrow:
          if (currentPoints.length == 2) {
            _drawArrow(canvas, currentPoints[0], currentPoints[1], paint);
          }
          break;
        case DrawingMode.player:
          if (currentPoints.isNotEmpty) {
            _drawPlayerIcon(canvas, currentPoints[0], paint);
          }
          break;
        case DrawingMode.none:
          break;
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 20.0;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - arrowSize * cos(angle - pi / 6), end.dy - arrowSize * sin(angle - pi / 6))
      ..lineTo(end.dx - arrowSize * cos(angle + pi / 6), end.dy - arrowSize * sin(angle + pi / 6))
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  void _drawPlayerIcon(Canvas canvas, Offset position, Paint paint) {
    const size = 30.0;
    canvas.drawCircle(position, size * 0.2, paint..style = PaintingStyle.fill);
    final bodyStart = Offset(position.dx, position.dy + size * 0.2);
    final bodyEnd = Offset(position.dx, position.dy + size * 0.8);
    canvas.drawLine(bodyStart, bodyEnd, paint);
    final leftArmStart = Offset(position.dx - size * 0.3, position.dy + size * 0.4);
    final leftArmEnd = Offset(position.dx + size * 0.3, position.dy + size * 0.4);
    canvas.drawLine(leftArmStart, leftArmEnd, paint);
    final leftLegStart = Offset(position.dx - size * 0.2, position.dy + size * 0.8);
    final leftLegEnd = Offset(position.dx, position.dy + size * 1.2);
    canvas.drawLine(leftLegStart, leftLegEnd, paint);
    final rightLegStart = Offset(position.dx + size * 0.2, position.dy + size * 0.8);
    final rightLegEnd = Offset(position.dx, position.dy + size * 1.2);
    canvas.drawLine(rightLegStart, rightLegEnd, paint);
  }

  @override
  bool shouldRepaint(FieldDrawingPainter oldDelegate) {
    return drawings != oldDelegate.drawings ||
        currentPoints != oldDelegate.currentPoints ||
        drawingMode != oldDelegate.drawingMode ||
        drawingColor != oldDelegate.drawingColor ||
        selectedDrawingIndex != oldDelegate.selectedDrawingIndex;
  }
}