import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:analysis_ai/core/utils/custom_snack_bar.dart';
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
import '../../../../../core/widgets/field_drawing_painter.dart';
import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain layer/entities/player_per_match_entity.dart';
import '../../cubit/lineup drawing cubut/drawing__cubit.dart';
import '../../cubit/lineup drawing cubut/drawing__state.dart';

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

  Future<void> _saveFieldAsImage(BuildContext context) async {
    try {
      bool hasPermission = false;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt < 33) {
          if (await Permission.storage.isDenied || await Permission.storage.isPermanentlyDenied) {
            final status = await Permission.storage.request();
            hasPermission = status.isGranted;
            if (!hasPermission && status.isPermanentlyDenied) {
              showErrorSnackBar(context, 'Storage permission permanently denied. Please enable it in Settings.');
              return;
            }
          } else {
            hasPermission = true;
          }
        } else {
          if (await Permission.photos.isDenied || await Permission.photos.isPermanentlyDenied) {
            final status = await Permission.photos.request();
            hasPermission = status.isGranted;
            if (!hasPermission && status.isPermanentlyDenied) {
              showErrorSnackBar(context, 'Media permission permanently denied. Please enable it in Settings.');
              return;
            }
          } else {
            hasPermission = true;
          }
        }
      } else {
        hasPermission = true;
      }

      if (!hasPermission) {
        showWarningSnackBar(context, 'Permission denied. Cannot save image.');
        return;
      }

      RenderRepaintBoundary boundary =
      _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final String fileName = 'field_${widget.matchId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String tempPath = '${tempDir.path}/$fileName';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(pngBytes);

      final bool? success = await GallerySaver.saveImage(
        tempPath,
        albumName: 'aiTacticals',
      );

      await tempFile.delete();

      if (success == true) {
        showSuccessSnackBar(context, 'Image saved to Gallery in aiTacticals folder');
      } else {
        showErrorSnackBar(context, 'Failed to save image to Gallery');
      }

      final drawings = context.read<DrawingCubit>().state.drawings;

      Navigator.pop(context, {
        'home': homePlayerPositions,
        'away': awayPlayerPositions,
        'drawings': drawings,
      });
    } catch (e) {
      print('Error saving image: $e');
      showErrorSnackBar(context, 'Failed to save image: $e');
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
            Builder(
              builder: (innerContext) => IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveFieldAsImage(innerContext),
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40.r), // Rounded corners
                ), // Non-circular shape
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