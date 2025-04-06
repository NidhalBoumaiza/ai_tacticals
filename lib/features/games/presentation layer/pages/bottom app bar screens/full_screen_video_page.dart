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
import '../../../../../core/utils/custom_snack_bar.dart';
import '../../../../../core/widgets/field_drawing_painter.dart';

class FullScreenVideoPage extends StatefulWidget {
  const FullScreenVideoPage({super.key});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  final GlobalKey _videoKey = GlobalKey();
  final ValueNotifier<bool> _isDialOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

                final currentDrawings = videoState.lines
                    .where((line) => (line['timestamp'] as int) == currentTimestamp)
                    .map((line) => line['drawing'] as DrawingItem)
                    .toList();

                if (!videoState.isPlaying && !drawingState.isDrawing && drawingState.drawings != currentDrawings) {
                  context.read<DrawingCubit>().emit(drawingState.copyWith(
                    drawings: currentDrawings,
                    selectedDrawingIndex: null,
                  ));
                }

                final allDrawings = drawingState.isDrawing && drawingState.currentPoints.isNotEmpty
                    ? [
                  ...currentDrawings,
                  DrawingItem(
                    type: drawingState.currentMode,
                    points: drawingState.currentPoints,
                    color: drawingState.currentColor,
                  ),
                ]
                    : currentDrawings;

                return Stack(
                  children: [
                    GestureDetector(
                      onTapUp: (details) {
                        if (!drawingState.isDrawing && drawingState.currentMode == DrawingMode.none && !videoState.isPlaying) {
                          final RenderBox? box = _videoKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final localPosition = box.globalToLocal(details.globalPosition);
                            context.read<DrawingCubit>().selectDrawing(localPosition);
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
                                  final RenderBox? box = _videoKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (box != null && drawingState.currentMode != DrawingMode.none && !videoState.isPlaying) {
                                    final localPosition = box.globalToLocal(details.globalPosition);
                                    context.read<DrawingCubit>().startDrawing(localPosition);
                                  }
                                }
                                ..onUpdate = (details) {
                                  final RenderBox? box = _videoKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (box != null && !videoState.isPlaying) {
                                    final localPosition = box.globalToLocal(details.globalPosition);
                                    final drawingCubit = context.read<DrawingCubit>();
                                    if (drawingState.isDrawing && drawingState.currentMode != DrawingMode.none) {
                                      drawingCubit.updateDrawing(
                                        localPosition,
                                        maxWidth: videoWidth,
                                        maxHeight: videoHeight,
                                      );
                                    } else if (drawingState.selectedDrawingIndex != null && drawingState.selectedDrawingIndex! < drawingState.drawings.length) {
                                      drawingCubit.moveDrawing(
                                        details.delta,
                                        maxWidth: videoWidth,
                                        maxHeight: videoHeight,
                                      );
                                      final updatedLines = List<Map<String, dynamic>>.from(videoState.lines)
                                        ..removeWhere((line) => (line['timestamp'] as int) == currentTimestamp);
                                      updatedLines.addAll(drawingCubit.state.drawings.map((drawing) => {
                                        'drawing': drawing,
                                        'timestamp': currentTimestamp,
                                      }));
                                      context.read<VideoEditingCubit>().emit(videoState.copyWith(lines: updatedLines));
                                    }
                                  }
                                }
                                ..onEnd = (_) {
                                  if (drawingState.isDrawing && drawingState.currentMode != DrawingMode.none && !videoState.isPlaying) {
                                    final drawingCubit = context.read<DrawingCubit>();
                                    drawingCubit.endDrawing();
                                    final timestamp = videoState.controller?.value.position.inMilliseconds ?? 0;
                                    if (drawingCubit.state.drawings.isNotEmpty) {
                                      final newDrawing = drawingCubit.state.drawings.last;
                                      context.read<VideoEditingCubit>().addDrawing(newDrawing, timestamp);
                                      drawingCubit.emit(drawingCubit.state.copyWith(
                                        currentPoints: [],
                                        isDrawing: false,
                                        currentMode: DrawingMode.none,
                                      ));
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
                                    allDrawings,
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
        heroTag: 'record_button',
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
        heroTag: 'stop_button',
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
              context.read<DrawingCubit>().emit(context.read<DrawingCubit>().state.copyWith(
                currentPoints: [],
                isDrawing: false,
                currentMode: DrawingMode.none,
              ));
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

  Widget _buildDrawingOptionsButton(BuildContext context) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, drawingState) {
        final cubit = context.read<DrawingCubit>();
        final videoCubit = context.read<VideoEditingCubit>();
        return SizedBox(
          height: 60.w,
          width: 60.w,
          child: FloatingActionButton(
            heroTag: 'drawing_options_button',
            onPressed: () {
              if (drawingState.isDrawing) {
                cubit.endDrawing();
                final timestamp = videoCubit.state.controller?.value.position.inMilliseconds ?? 0;
                if (drawingState.drawings.isNotEmpty) {
                  videoCubit.addDrawing(drawingState.drawings.last, timestamp);
                  cubit.emit(cubit.state.copyWith(
                    currentPoints: [],
                    isDrawing: false,
                    currentMode: DrawingMode.none,
                  ));
                }
              } else if (videoCubit.state.isPlaying) {
                showErrorSnackBar(context, "Cannot draw while the video is playing. Please pause the video first.");
              } else {
                _showDrawingOptions(context, cubit, drawingState);
              }
            },
            child: Icon(drawingState.isDrawing ? Icons.stop : Icons.edit),
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          ),
        );
      },
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
              context.read<DrawingCubit>().emit(context.read<DrawingCubit>().state.copyWith(
                currentPoints: [],
                isDrawing: false,
                currentMode: DrawingMode.none,
              ));
            }
                : null,
          ),
          SizedBox(width: 10.w),
          IconButton(
            icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30.sp),
            onPressed: state.controller != null
                ? () {
              context.read<VideoEditingCubit>().togglePlayPause(context, videoKey: _videoKey);
              if (state.isPlaying) {
                context.read<DrawingCubit>().emit(context.read<DrawingCubit>().state.copyWith(
                  currentPoints: [],
                  isDrawing: false,
                  currentMode: DrawingMode.none,
                ));
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
              context.read<DrawingCubit>().emit(context.read<DrawingCubit>().state.copyWith(
                currentPoints: [],
                isDrawing: false,
                currentMode: DrawingMode.none,
              ));
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
    final videoCubit = context.read<VideoEditingCubit>();
    final currentTimestamp = videoCubit.state.controller?.value.position.inMilliseconds ?? 0;

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
                  if (state.drawings.isNotEmpty) {
                    cubit.undoDrawingForFrame(currentTimestamp, videoCubit.state.lines, videoCubit.removeDrawingForTimestamp);
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.redo, color: Colors.black87),
                title: const Text('Redo', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  if (state.redoStack.isNotEmpty) {
                    cubit.redoDrawingForFrame(currentTimestamp, videoCubit.addDrawing);
                    Navigator.pop(context);
                  }
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
}