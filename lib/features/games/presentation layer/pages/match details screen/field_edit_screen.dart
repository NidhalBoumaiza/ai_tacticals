import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:analysis_ai/features/games/presentation%20layer/pages/match%20details%20screen/player_stats_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain layer/entities/player_per_match_entity.dart';

enum DrawingMode { free, circle, arrow, player, none }

class FieldDrawingPainter extends CustomPainter {
  final List<Map<String, dynamic>> drawings;
  final List<Offset> currentPoints;
  final DrawingMode drawingMode;
  final Color drawingColor;

  FieldDrawingPainter(
      this.drawings,
      this.currentPoints,
      this.drawingMode,
      this.drawingColor,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = drawingColor
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    for (var drawing in drawings) {
      paint.color = drawing['color'] ?? drawingColor;
      final points = drawing['points'] as List<Offset>;

      switch (drawing['type']) {
        case 'free':
          for (int i = 0; i < points.length - 1; i++) {
            if (points[i] != null && points[i + 1] != null) {
              canvas.drawLine(points[i], points[i + 1], paint);
            }
          }
          break;
        case 'circle':
          if (points.length == 2) {
            final start = points[0];
            final end = points[1];
            final radius = (start - end).distance;
            canvas.drawCircle(start, radius, paint..style = PaintingStyle.stroke);
          }
          break;
        case 'arrow':
          if (points.length == 2) {
            _drawArrow(canvas, points[0], points[1], paint);
          }
          break;
        case 'player':
          if (points.isNotEmpty) {
            _drawPlayerIcon(canvas, points[0], paint);
          }
          break;
      }
    }

    if (currentPoints.isNotEmpty && drawingMode != DrawingMode.none) {
      paint.color = drawingColor;
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
        default:
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
        drawingColor != oldDelegate.drawingColor;
  }
}

class PlayerPosition {
  final String playerId;
  double x;
  double y;
  final bool isHomeTeam;
  final Color teamColor;
  final PlayerPerMatchEntity player;

  PlayerPosition({
    required this.playerId,
    required this.x,
    required this.y,
    required this.isHomeTeam,
    required this.teamColor,
    required this.player,
  });
}

class FieldEditScreen extends StatefulWidget {
  final int matchId;
  final List<PlayerPosition> homePlayers;
  final List<PlayerPosition> awayPlayers;

  const FieldEditScreen({
    super.key,
    required this.matchId,
    required this.homePlayers,
    required this.awayPlayers,
  });

  @override
  State<FieldEditScreen> createState() => _FieldEditScreenState();
}

class _FieldEditScreenState extends State<FieldEditScreen> {
  late List<PlayerPosition> homePlayerPositions;
  late List<PlayerPosition> awayPlayerPositions;
  String? currentlyDraggingPlayerId;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  // Drawing variables
  bool isDrawing = false;
  final ValueNotifier<List<Offset>> currentPoints = ValueNotifier([]);
  Color drawingColor = Colors.red;
  DrawingMode drawingMode = DrawingMode.none;
  List<Map<String, dynamic>> drawings = [];
  List<Map<String, dynamic>> redoDrawings = [];
  final GlobalKey _fieldKey = GlobalKey();
  final ValueNotifier<bool> isDialOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // Deep copy to avoid modifying the original list directly
    homePlayerPositions = widget.homePlayers.map((p) => PlayerPosition(
      playerId: p.playerId,
      x: p.x,
      y: p.y,
      isHomeTeam: p.isHomeTeam,
      teamColor: p.teamColor,
      player: p.player,
    )).toList();
    awayPlayerPositions = widget.awayPlayers.map((p) => PlayerPosition(
      playerId: p.playerId,
      x: p.x,
      y: p.y,
      isHomeTeam: p.isHomeTeam,
      teamColor: p.teamColor,
      player: p.player,
    )).toList();
  }

  @override
  void dispose() {
    currentPoints.dispose();
    super.dispose();
  }

  void _startDrawing(Offset position) {
    currentPoints.value = [position];
    print('Start drawing at: $position, mode: $drawingMode');
  }

  void _updateDrawing(Offset position) {
    final fieldWidth = MediaQuery.of(context).size.width;
    final fieldHeight = 1900.h;
    final clampedPosition = Offset(
      position.dx.clamp(0.0, fieldWidth),
      position.dy.clamp(0.0, fieldHeight),
    );
    final newPoints = List<Offset>.from(currentPoints.value);
    if (drawingMode == DrawingMode.free) {
      newPoints.add(clampedPosition);
    } else if (newPoints.length < 2) {
      newPoints.add(clampedPosition);
    } else {
      newPoints[1] = clampedPosition;
    }
    currentPoints.value = newPoints;
    print('Update drawing to: $clampedPosition, points: ${currentPoints.value.length}');
  }

  void _endDrawing() {
    if (currentPoints.value.isNotEmpty) {
      final newDrawing = {
        'type': drawingMode.toString().split('.').last,
        'points': List<Offset>.from(currentPoints.value),
        'color': drawingColor,
      };
      drawings.add(newDrawing);
      redoDrawings.clear();
      print('Drawing ended, added: $newDrawing, total drawings: ${drawings.length}');
    }
    currentPoints.value = [];
  }

  void _clearDrawings() {
    drawings.clear();
    redoDrawings.clear();
    currentPoints.value = [];
    setState(() {});
    print('Cleared all drawings');
  }

  void _undoDrawing() {
    if (drawings.isNotEmpty) {
      redoDrawings.add(drawings.removeLast());
      setState(() {});
      print('Undo: Moved last drawing to redo');
    }
  }

  void _redoDrawing() {
    if (redoDrawings.isNotEmpty) {
      drawings.add(redoDrawings.removeLast());
      setState(() {});
      print('Redo: Restored last undone drawing');
    }
  }

  void _changeDrawingColor(Color color) {
    drawingColor = color;
    setState(() {});
    print('Changed drawing color to: $color');
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: drawingColor,
              onColorChanged: _changeDrawingColor,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDraggablePlayer(PlayerPosition position) {
    final isDragging = currentlyDraggingPlayerId == position.playerId;

    return Positioned(
      left: position.x,
      top: position.y,
      child: Draggable(
        feedback: Transform.scale(
          scale: 1.1,
          child: _buildPlayerWidget(position, true),
        ),
        childWhenDragging: Container(),
        child: GestureDetector(
          onTap: () {
            if (!isDrawing && position.player.id != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PlayerStatsModal(
                  matchId: widget.matchId,
                  playerId: position.player.id!,
                  playerName: position.player.name ?? 'Unknown Player',
                ),
              );
            }
          },
          child: _buildPlayerWidget(position, isDragging),
        ),
        onDragStarted: () {
          if (!isDrawing) {
            setState(() {
              currentlyDraggingPlayerId = position.playerId;
            });
          }
        },
        onDragUpdate: (details) {
          if (!isDrawing) {
            setState(() {
              final fieldWidth = MediaQuery.of(context).size.width;
              final fieldHeight = 1900.h;

              double newX = position.x + details.delta.dx;
              double newY = position.y + details.delta.dy;

              newX = newX.clamp(0.0, fieldWidth - 110.w);
              newY = newY.clamp(0.0, fieldHeight - 110.h); // Allow full field movement

              position.x = newX;
              position.y = newY;
            });
          }
        },
        onDragEnd: (_) {
          if (!isDrawing) {
            setState(() {
              currentlyDraggingPlayerId = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildPlayerWidget(PlayerPosition position, bool isDragging) {
    return Transform.scale(
      scale: isDragging ? 1.1 : 1.0,
      child: Column(
        children: [
          Container(
            width: 110.w,
            height: 110.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border.all(
                color: position.teamColor.withOpacity(isDragging ? 1.0 : 0.7),
                width: isDragging ? 3 : 2,
              ),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: 'https://img.sofascore.com/api/v1/player/${position.player.id}/image',
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surface,
                  highlightColor: Theme.of(context).colorScheme.surfaceVariant,
                  child: Container(
                    width: 110.w,
                    height: 110.w,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  size: 60.w,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                fit: BoxFit.cover,
                width: 110.w,
                height: 110.w,
                cacheKey: position.player.id.toString(),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: position.teamColor.withOpacity(isDragging ? 0.4 : 0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            constraints: BoxConstraints(maxWidth: 150.w),
            child: ReusableText(
              text: position.player.name ?? 'N/A',
              textSize: 80.sp,
              textColor: Theme.of(context).colorScheme.onSurface,
              textFontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldBackground() {
    return Container(
      height: 1900.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 1900.h / 2 - 1,
            child: Container(
              height: 2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 150.w,
            top: 1900.h / 2 - 150.h,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 2.w,
            top: 1900.h / 2 - 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Positioned(
            left: 120.w,
            right: 120.w,
            top: -5.h,
            child: Container(
              height: 300.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: 120.w,
            right: 120.w,
            top: 1589.h,
            child: Container(
              height: 300.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: 270.w,
            right: 270.w,
            top: -5.h,
            child: Container(
              height: 90.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: 270.w,
            right: 270.w,
            top: 1797.h,
            child: Container(
              height: 90.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _saveFieldAsImage() async {
    try {
      // Request storage permission (for Android < 13, if needed)
      if (await Permission.storage.request().isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }

      // Capture the field as an image
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // Higher quality
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Get the Downloads directory
      final directory = await getExternalStorageDirectory(); // Fallback directory
      final String fileName = 'field_${widget.matchId}_${DateTime.now().millisecondsSinceEpoch}.png';
      String filePath;

      if (Platform.isAndroid) {
        // Use MediaStore to save to Downloads
        final String relativePath = 'Download'; // Relative path for Downloads folder
        final contentValues = <String, dynamic>{
          'title': fileName,
          'mime_type': 'image/png',
          'relative_path': relativePath,
          'is_pending': 1, // Mark as pending until the file is written
        };

        final uri = await MediaStore.createMediaStoreUri(
          contentValues: contentValues,
          collection: 'images',
        );

        if (uri != null) {
          final contentResolver = await rootBundle.load('');
          await File.fromUri(uri).writeAsBytes(pngBytes);
          await MediaStore.updateMediaStoreUri(
            uri: uri,
            contentValues: {'is_pending': 0}, // Mark as complete
          );
          filePath = 'Downloads/$fileName';
        } else {
          // Fallback to app-specific storage if MediaStore fails
          filePath = '${directory!.path}/$fileName';
          await File(filePath).writeAsBytes(pngBytes);
        }
      } else {
        // For non-Android (e.g., iOS), use app-specific directory
        filePath = '${directory!.path}/$fileName';
        await File(filePath).writeAsBytes(pngBytes);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to $filePath')),
      );

      // Return updated player positions
      Navigator.pop(context, {
        'home': homePlayerPositions,
        'away': awayPlayerPositions,
      });
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }
  Widget _buildFootballField() {
    final fieldWidth = MediaQuery.of(context).size.width;
    final fieldHeight = 1900.h;

    return SizedBox(
      width: fieldWidth,
      height: fieldHeight,
      child: RepaintBoundary(
        key: _repaintBoundaryKey, // Assign the key here
        child: RawGestureDetector(
          gestures: {
            PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                  () => PanGestureRecognizer(),
                  (PanGestureRecognizer instance) {
                instance
                  ..onStart = isDrawing
                      ? (details) {
                    final RenderBox? box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPosition = box.globalToLocal(details.globalPosition);
                      _startDrawing(localPosition);
                    }
                  }
                      : null
                  ..onUpdate = isDrawing
                      ? (details) {
                    final RenderBox? box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPosition = box.globalToLocal(details.globalPosition);
                      _updateDrawing(localPosition);
                    }
                  }
                      : null
                  ..onEnd = isDrawing ? (_) => _endDrawing() : null;
              },
            ),
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildFieldBackground(),
              ValueListenableBuilder<List<Offset>>(
                valueListenable: currentPoints,
                builder: (context, points, child) {
                  return CustomPaint(
                    size: Size(fieldWidth, fieldHeight),
                    painter: FieldDrawingPainter(
                      drawings,
                      points,
                      drawingMode,
                      drawingColor,
                    ),
                    child: Container(key: _fieldKey),
                  );
                },
              ),
              ...homePlayerPositions.map((position) => _buildDraggablePlayer(position)),
              ...awayPlayerPositions.map((position) => _buildDraggablePlayer(position)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Field'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFieldAsImage, // Call the save method here
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: isDrawing ? Icons.stop : Icons.edit,
        activeIcon: Icons.close,
        spacing: 10,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 4,
        openCloseDial: isDialOpen,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.brush),
            label: 'Draw',
            onTap: () {
              setState(() {
                drawingMode = DrawingMode.free;
                isDrawing = true;
                isDialOpen.value = false;
                print('Selected Draw mode');
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.circle_outlined),
            label: 'Circle',
            onTap: () {
              setState(() {
                drawingMode = DrawingMode.circle;
                isDrawing = true;
                isDialOpen.value = false;
                print('Selected Circle mode');
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.person),
            label: 'Player Icon',
            onTap: () {
              setState(() {
                drawingMode = DrawingMode.player;
                isDrawing = true;
                isDialOpen.value = false;
                print('Selected Player Icon mode');
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.arrow_forward),
            label: 'Arrow',
            onTap: () {
              setState(() {
                drawingMode = DrawingMode.arrow;
                isDrawing = true;
                isDialOpen.value = false;
                print('Selected Arrow mode');
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.color_lens),
            label: 'Change Color',
            onTap: () {
              _showColorPicker(context);
              isDialOpen.value = false;
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.undo),
            label: 'Undo',
            onTap: () {
              _undoDrawing();
              isDialOpen.value = false;
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.redo),
            label: 'Redo',
            onTap: () {
              _redoDrawing();
              isDialOpen.value = false;
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.clear),
            label: 'Clear All',
            onTap: () {
              _clearDrawings();
              isDialOpen.value = false;
            },
          ),
        ],
        onPress: () {
          setState(() {
            if (isDialOpen.value) {
              isDialOpen.value = false;
            } else if (!isDrawing) {
              isDialOpen.value = true;
            } else {
              isDrawing = false;
              drawingMode = DrawingMode.none;
              currentPoints.value = [];
              print('Drawing stopped');
            }
          });
        },
      ),
      body: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 20.w , vertical: 20.h),
        child: _buildFootballField(),
      ),
    );
  }
}


class MediaStore {
  static const _platform = MethodChannel('flutter.io/media_store');

  static Future<Uri?> createMediaStoreUri({
    required Map<String, dynamic> contentValues,
    required String collection,
  }) async {
    try {
      final String? result = await _platform.invokeMethod('insert', {
        'collection': collection,
        'values': contentValues,
      });
      return result != null ? Uri.parse(result) : null;
    } catch (e) {
      print('Error creating MediaStore URI: $e');
      return null;
    }
  }

  static Future<void> updateMediaStoreUri({
    required Uri uri,
    required Map<String, dynamic> contentValues,
  }) async {
    try {
      await _platform.invokeMethod('update', {
        'uri': uri.toString(),
        'values': contentValues,
      });
    } catch (e) {
      print('Error updating MediaStore URI: $e');
    }
  }
}