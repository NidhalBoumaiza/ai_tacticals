import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:analysis_ai/features/games/presentation%20layer/pages/match%20details%20screen/player_stats_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain layer/entities/player_per_match_entity.dart';
import '../../cubit/lineup drawing cubut/drawing__cubit.dart';
import '../../cubit/lineup drawing cubut/drawing__state.dart';

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
  final GlobalKey _fieldKey = GlobalKey();
  final ValueNotifier<bool> _isDialOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
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
    _isDialOpen.dispose();
    super.dispose();
  }

  void _showColorPicker(BuildContext context, DrawingCubit cubit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: cubit.state.currentColor,
              onColorChanged: (color) => cubit.changeColor(color),
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
    ).then((_) => _isDialOpen.value = false);
  }

  Widget _buildDraggablePlayer(PlayerPosition position, bool isDrawing) {
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
              newY = newY.clamp(0.0, fieldHeight - 110.h);

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
      // Check and request storage permissions based on Android version
      bool hasPermission = false;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt < 33) {
          // Android 12 and below: Request storage permission
          if (await Permission.storage.isDenied || await Permission.storage.isPermanentlyDenied) {
            final status = await Permission.storage.request();
            hasPermission = status.isGranted;
            if (!hasPermission && status.isPermanentlyDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission permanently denied. Please enable it in Settings.'),
                  action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
                ),
              );
              return;
            }
          } else {
            hasPermission = true;
          }
        } else {
          // Android 13 and above: Request media permissions (photos)
          if (await Permission.photos.isDenied || await Permission.photos.isPermanentlyDenied) {
            final status = await Permission.photos.request();
            hasPermission = status.isGranted;
            if (!hasPermission && status.isPermanentlyDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Media permission permanently denied. Please enable it in Settings.'),
                  action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
                ),
              );
              return;
            }
          } else {
            hasPermission = true;
          }
        }
      } else {
        // For iOS, assume permission is granted or handled by gallery_saver_plus
        hasPermission = true;
      }

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied. Cannot save image.')),
        );
        return;
      }

      // Capture the field as an image
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // Higher quality
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save the image temporarily
      final tempDir = await getTemporaryDirectory();
      final String fileName = 'field_${widget.matchId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String tempPath = '${tempDir.path}/$fileName';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(pngBytes);

      // Save to Gallery in aiTacticals folder
      final bool? success = await GallerySaver.saveImage(
        tempPath,
        albumName: 'aiTacticals', // Creates the aiTacticals folder if it doesn't exist
      );

      // Clean up temporary file
      await tempFile.delete();

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to Gallery in aiTacticals folder')),
        );
      } else {
        throw Exception('Failed to save image to Gallery');
      }

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
      child: BlocBuilder<DrawingCubit, DrawingState>(
        builder: (context, state) {
          final cubit = context.read<DrawingCubit>();
          return RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildFieldBackground(),
                GestureDetector(
                  onTapUp: (details) {
                    if (!state.isDrawing && state.currentMode == DrawingMode.none) {
                      final RenderBox? box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localPosition = box.globalToLocal(details.globalPosition);
                        final previousIndex = state.selectedDrawingIndex;
                        cubit.selectDrawing(localPosition);
                        if (previousIndex != null && cubit.state.selectedDrawingIndex == null) {
                          print('Deselected drawing by tapping elsewhere');
                        } else if (cubit.state.selectedDrawingIndex == previousIndex) {
                          cubit.deselectDrawing();
                          print('Deselected drawing $previousIndex by tapping it again');
                        } else if (cubit.state.selectedDrawingIndex != null) {
                          print('Selected drawing ${cubit.state.selectedDrawingIndex}');
                        }
                      }
                    }
                  },
                  child: RawGestureDetector(
                    gestures: {
                      PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                            () => PanGestureRecognizer(),
                            (PanGestureRecognizer instance) {
                          instance
                            ..onStart = (details) {
                              final RenderBox? box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box != null) {
                                final localPosition = box.globalToLocal(details.globalPosition);
                                if (state.isDrawing && state.currentMode != DrawingMode.none) {
                                  cubit.startDrawing(localPosition);
                                  print('Drawing started at: $localPosition');
                                }
                              }
                            }
                            ..onUpdate = (details) {
                              final RenderBox? box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box != null) {
                                final localPosition = box.globalToLocal(details.globalPosition);
                                if (state.isDrawing && state.currentMode != DrawingMode.none) {
                                  cubit.updateDrawing(localPosition, maxWidth: fieldWidth, maxHeight: fieldHeight);
                                } else if (state.selectedDrawingIndex != null) {
                                  cubit.moveDrawing(details.delta, maxWidth: fieldWidth, maxHeight: fieldHeight);
                                  print('Dragging drawing: ${state.selectedDrawingIndex}, delta: ${details.delta}');
                                }
                              }
                            }
                            ..onEnd = (_) {
                              if (state.isDrawing && state.currentMode != DrawingMode.none) {
                                cubit.endDrawing();
                                print('Drawing ended');
                              }
                            };
                        },
                      ),
                    },
                    child: CustomPaint(
                      size: Size(fieldWidth, fieldHeight),
                      painter: FieldDrawingPainter(
                        state.drawings,
                        state.currentPoints,
                        state.currentMode,
                        state.currentColor,
                        state.selectedDrawingIndex,
                      ),
                      child: Container(key: _fieldKey),
                    ),
                  ),
                ),
                ...homePlayerPositions.map((position) => _buildDraggablePlayer(position, state.isDrawing)),
                ...awayPlayerPositions.map((position) => _buildDraggablePlayer(position, state.isDrawing)),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DrawingCubit(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Edit Field'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveFieldAsImage,
            ),
          ],
        ),
        floatingActionButton: TapRegion(
          onTapOutside: (_) {
            if (_isDialOpen.value) {
              _isDialOpen.value = false;
            }
          },
          child: BlocBuilder<DrawingCubit, DrawingState>(
            builder: (context, state) {
              final cubit = context.read<DrawingCubit>();
              return SpeedDial(
                openCloseDial: _isDialOpen,
                icon: state.isDrawing ? Icons.stop : Icons.edit,
                activeIcon: Icons.close,
                spacing: 10,
                childPadding: const EdgeInsets.all(5),
                spaceBetweenChildren: 4,
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.brush),
                    label: 'Draw',
                    onTap: () {
                      cubit.setDrawingMode(DrawingMode.free);
                      _isDialOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.circle_outlined),
                    label: 'Circle',
                    onTap: () {
                      cubit.setDrawingMode(DrawingMode.circle);
                      _isDialOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.person),
                    label: 'Player Icon',
                    onTap: () {
                      cubit.setDrawingMode(DrawingMode.player);
                      _isDialOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.arrow_forward),
                    label: 'Arrow',
                    onTap: () {
                      cubit.setDrawingMode(DrawingMode.arrow);
                      _isDialOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.color_lens),
                    label: 'Change Color',
                    onTap: () {
                      _showColorPicker(context, cubit);
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.undo),
                    label: 'Undo',
                    onTap: () {
                      cubit.undoDrawing();
                      _isDialOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.redo),
                    label: 'Redo',
                    onTap: () {
                      cubit.redoDrawing();
                      _isDialOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.clear),
                    label: 'Clear All',
                    onTap: () {
                      cubit.clearDrawings();
                      _isDialOpen.value = false;
                    },
                  ),
                ],
                onPress: () {
                  if (state.isDrawing) {
                    cubit.endDrawing();
                    _isDialOpen.value = false;
                  } else {
                    _isDialOpen.value = !_isDialOpen.value;
                  }
                },
                onClose: () {
                  _isDialOpen.value = false;
                },
              );
            },
          ),
        ),
        body: TapRegion(
          onTapOutside: (_) {
            if (_isDialOpen.value) {
              _isDialOpen.value = false;
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: _buildFootballField(),
          ),
        ),
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