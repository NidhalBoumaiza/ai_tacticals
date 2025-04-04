import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../cubit/lineup drawing cubut/drawing__cubit.dart';
import '../../cubit/lineup drawing cubut/drawing__state.dart';
import '../../cubit/video editing cubit/video_editing_cubit.dart';
import '../../cubit/video editing cubit/video_editing_state.dart';
import '../../../../../core/widgets/field_drawing_painter.dart';

// Class to hold drawing position data during dragging
class DrawingPosition {
  final DrawingItem drawing;
  Offset position; // Center position of the drawing for dragging

  DrawingPosition({
    required this.drawing,
    required this.position,
  });
}

class FullScreenVideoPage extends StatefulWidget {
  const FullScreenVideoPage({super.key});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  final GlobalKey _videoKey = GlobalKey();
  final ValueNotifier<bool> _isDialOpen = ValueNotifier(false);
  late List<DrawingPosition> currentDrawings; // Local buffer for dragging
  String? currentlyDraggingDrawingId; // Track which drawing is being dragged

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    currentDrawings = [];
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _isDialOpen.dispose();
    super.dispose();
  }

  // Helper to calculate the center position of a drawing
  Offset _calculateCenter(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    double sumX = 0, sumY = 0;
    for (var point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / points.length, sumY / points.length);
  }

  // Build a draggable drawing widget
  Widget _buildDraggableDrawing(DrawingPosition drawingPosition, bool isDrawing, double videoWidth, double videoHeight) {
    final isDragging = currentlyDraggingDrawingId == drawingPosition.drawing.hashCode.toString();
    final center = drawingPosition.position;

    return Positioned(
      left: center.dx - 20.w, // Adjust for size of feedback widget
      top: center.dy - 20.h,
      child: Draggable(
        feedback: Transform.scale(
          scale: 1.1,
          child: _buildDrawingWidget(drawingPosition.drawing, true),
        ),
        childWhenDragging: Container(),
        child: GestureDetector(
          onTap: () {
            if (!isDrawing) {
              final cubit = context.read<DrawingCubit>();
              cubit.selectDrawing(center);
              print('Tapped drawing: ${drawingPosition.drawing.hashCode}, selected: ${cubit.state.selectedDrawingIndex}');
            }
          },
          child: _buildDrawingWidget(drawingPosition.drawing, isDragging),
        ),
        onDragStarted: () {
          if (!isDrawing) {
            setState(() {
              currentlyDraggingDrawingId = drawingPosition.drawing.hashCode.toString();
            });
          }
        },
        onDragUpdate: (details) {
          if (!isDrawing) {
            setState(() {
              double newX = drawingPosition.position.dx + details.delta.dx;
              double newY = drawingPosition.position.dy + details.delta.dy;

              newX = newX.clamp(0.0, videoWidth - 40.w); // Adjust for widget size
              newY = newY.clamp(0.0, videoHeight - 40.h);

              drawingPosition.position = Offset(newX, newY);

              // Update drawing points relative to new center
              final delta = drawingPosition.position - _calculateCenter(drawingPosition.drawing.points);
              drawingPosition.drawing.points = drawingPosition.drawing.points.map((p) => p + delta).toList();
            });
          }
        },
        onDragEnd: (_) {
          if (!isDrawing) {
            setState(() {
              currentlyDraggingDrawingId = null;
              final timestamp = context.read<VideoEditingCubit>().state.controller?.value.position.inMilliseconds ?? 0;
              context.read<VideoEditingCubit>().addDrawing(drawingPosition.drawing, timestamp);
              print('Drag ended for drawing: ${drawingPosition.drawing.hashCode}');
            });
          }
        },
      ),
    );
  }

  // Simple widget to represent a drawing (customize as needed)
  Widget _buildDrawingWidget(DrawingItem drawing, bool isDragging) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: drawing.color.withOpacity(isDragging ? 0.8 : 0.5),
        border: Border.all(
          color: drawing.color,
          width: isDragging ? 3 : 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DrawingCubit()),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<VideoEditingCubit, VideoEditingState>(
          builder: (context, videoState) {
            return BlocBuilder<DrawingCubit, DrawingState>(
              builder: (context, drawingState) {
                final videoWidth = MediaQuery.of(context).size.width;
                final videoHeight = MediaQuery.of(context).size.height;
                final currentTimestamp = videoState.controller?.value.position.inMilliseconds ?? 0;

                // Update local drawings from VideoEditingCubit when not dragging
                if (currentlyDraggingDrawingId == null) {
                  currentDrawings = videoState.lines
                      .where((line) => (line['timestamp'] as int) == currentTimestamp)
                      .map((line) => DrawingPosition(
                    drawing: line['drawing'] as DrawingItem,
                    position: _calculateCenter((line['drawing'] as DrawingItem).points),
                  ))
                      .toList();
                }

                return Stack(
                  children: [
                    GestureDetector(
                      child: RawGestureDetector(
                        gestures: {
                          PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                                () => PanGestureRecognizer(),
                                (PanGestureRecognizer instance) {
                              instance
                                ..onStart = (details) {
                                  final RenderBox? box = _videoKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (box != null && drawingState.currentMode != DrawingMode.none) {
                                    final localPosition = box.globalToLocal(details.globalPosition);
                                    context.read<DrawingCubit>().startDrawing(localPosition);
                                    print('Drawing started at: $localPosition');
                                  }
                                }
                                ..onUpdate = (details) {
                                  final RenderBox? box = _videoKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (box != null && drawingState.currentMode != DrawingMode.none) {
                                    final localPosition = box.globalToLocal(details.globalPosition);
                                    context.read<DrawingCubit>().updateDrawing(localPosition,
                                        maxWidth: videoWidth, maxHeight: videoHeight);
                                  }
                                }
                                ..onEnd = (_) {
                                  if (drawingState.currentMode != DrawingMode.none) {
                                    context.read<DrawingCubit>().endDrawing();
                                    final timestamp = videoState.controller?.value.position.inMilliseconds ?? 0;
                                    if (drawingState.drawings.isNotEmpty) {
                                      context.read<VideoEditingCubit>().addDrawing(drawingState.drawings.last, timestamp);
                                      print('Drawing ended and added at timestamp: $timestamp');
                                    }
                                  }
                                };
                            },
                          ),
                        },
                        child: SizedBox(
                          width: videoWidth,
                          height: videoHeight,
                          child: RepaintBoundary(
                            key: _videoKey,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (videoState.controller != null && videoState.controller!.value.isInitialized)
                                  VideoPlayer(videoState.controller!)
                                else
                                  const Center(
                                    child: Text(
                                      "Erreur: Vidéo non chargée",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                CustomPaint(
                                  size: Size(videoWidth, videoHeight),
                                  painter: FieldDrawingPainter(
                                    drawingState.isDrawing && drawingState.currentPoints.isNotEmpty
                                        ? [
                                      DrawingItem(
                                        type: drawingState.currentMode,
                                        points: drawingState.currentPoints,
                                        color: drawingState.currentColor,
                                      )
                                    ]
                                        : currentDrawings.map((dp) => dp.drawing).toList(),
                                    drawingState.currentPoints,
                                    drawingState.currentMode,
                                    drawingState.currentColor,
                                    drawingState.selectedDrawingIndex,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Overlay draggable drawings
                    ...currentDrawings.map((dp) => _buildDraggableDrawing(dp, drawingState.isDrawing, videoWidth, videoHeight)),
                    Positioned(
                      bottom: 30.h,
                      left: 30.w,
                      child: _buildRecordButton(context, videoState),
                    ),
                    Positioned(
                      bottom: 30.h,
                      left: 120.w,
                      child: _buildStopButton(context, videoState),
                    ),
                    Positioned(
                      bottom: 30.h,
                      right: 30.w,
                      child: _buildDrawingOptionsButton(context),
                    ),
                    if (videoState.showTimeline && videoState.controller != null)
                      Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: _buildTimeline(videoState),
                      ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: _buildVideoControls(),
                    ),
                    Positioned(
                      top: 25.w,
                      left: 15.w,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context, VideoEditingState videoState) {
    return SizedBox(
      height: 60.w,
      width: 60.w,
      child: FloatingActionButton(
        onPressed: videoState.controller != null && !videoState.isRecording
            ? () async {
          final renderBox = _videoKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final videoPosition = renderBox.localToGlobal(Offset.zero);
            final videoSize = renderBox.size;
            await context.read<VideoEditingCubit>().startRecording(
              context,
              Rect.fromLTWH(
                videoPosition.dx,
                videoPosition.dy,
                videoSize.width,
                videoSize.height,
              ),
            );
          }
        }
            : null,
        child: const Icon(Icons.fiber_manual_record, color: Colors.black),
        backgroundColor: Colors.lightGreen,
      ),
    );
  }

  Widget _buildStopButton(BuildContext context, VideoEditingState videoState) {
    return SizedBox(
      height: 60.w,
      width: 60.w,
      child: FloatingActionButton(
        onPressed: videoState.controller != null && videoState.isRecording
            ? () => context.read<VideoEditingCubit>().stopRecording(context)
            : null,
        child: const Icon(Icons.stop),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildTimeline(VideoEditingState state) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: state.controller!.value.position.inSeconds.toDouble(),
            min: 0,
            max: state.controller!.value.duration.inSeconds.toDouble(),
            onChanged: (value) {
              state.controller!.seekTo(Duration(seconds: value.toInt()));
              context.read<DrawingCubit>().clearDrawings();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(state.controller!.value.position),
                    style: const TextStyle(color: Colors.white)),
                Text(_formatDuration(state.controller!.value.duration),
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return BlocBuilder<VideoEditingCubit, VideoEditingState>(
      builder: (context, state) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.replay_10, color: Colors.white, size: 30.sp),
            onPressed: state.controller != null
                ? () {
              context.read<VideoEditingCubit>().seekBackward();
              context.read<DrawingCubit>().clearDrawings();
            }
                : null,
          ),
          SizedBox(width: 10.w),
          IconButton(
            icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white, size: 30.sp),
            onPressed: state.controller != null
                ? () {
              context.read<VideoEditingCubit>().togglePlayPause(context, videoKey: _videoKey);
              if (state.isPlaying) {
                context.read<DrawingCubit>().clearDrawings();
              }
            }
                : null,
          ),
          SizedBox(width: 10.w),
          IconButton(
            icon: Icon(Icons.forward_10, color: Colors.white, size: 30.sp),
            onPressed: state.controller != null
                ? () {
              context.read<VideoEditingCubit>().seekForward();
              context.read<DrawingCubit>().clearDrawings();
            }
                : null,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _showColorPicker(BuildContext context, DrawingCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: cubit.state.currentColor,
            onColorChanged: (color) => cubit.changeColor(color),
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showDrawingOptions(BuildContext context, DrawingCubit cubit, DrawingState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      builder: (context) {
        return SizedBox(
          height: 400,
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              ListTile(
                leading: const Icon(Icons.brush, color: Colors.black87),
                title: const Text('Draw', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  cubit.setDrawingMode(DrawingMode.free);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.circle_outlined, color: Colors.black87),
                title: const Text('Circle', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  cubit.setDrawingMode(DrawingMode.circle);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.black87),
                title: const Text('Player Icon', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  cubit.setDrawingMode(DrawingMode.player);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_forward, color: Colors.black87),
                title: const Text('Arrow', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  cubit.setDrawingMode(DrawingMode.arrow);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens, color: Colors.black87),
                title: const Text('Change Color', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  _showColorPicker(context, cubit);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.black87),
                title: const Text('Undo', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  if (state.drawings.isNotEmpty) cubit.undoDrawing();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.redo, color: Colors.black87),
                title: const Text('Redo', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  if (state.redoStack.isNotEmpty) cubit.redoDrawing();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.black87),
                title: const Text('Clear', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  if (state.drawings.isNotEmpty) cubit.clearDrawings();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawingOptionsButton(BuildContext context) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, state) {
        final cubit = context.read<DrawingCubit>();
        return SizedBox(
          height: 60.w,
          width: 60.w,
          child: FloatingActionButton(
            onPressed: () {
              if (state.isDrawing) {
                cubit.endDrawing();
                final timestamp = context.read<VideoEditingCubit>().state.controller?.value.position.inMilliseconds ?? 0;
                if (state.drawings.isNotEmpty) {
                  context.read<VideoEditingCubit>().addDrawing(state.drawings.last, timestamp);
                }
              } else {
                _showDrawingOptions(context, cubit, state);
              }
            },
            child: Icon(state.isDrawing ? Icons.stop : Icons.edit),
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}