import 'dart:io';
import 'dart:ui' as ui;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../../cubit/lineup drawing cubut/drawing__cubit.dart';
import '../../cubit/lineup drawing cubut/drawing__state.dart';
import '../../cubit/video editing cubit/video_editing_cubit.dart';
import '../../cubit/video editing cubit/video_editing_state.dart';
import '../../../../../core/widgets/field_drawing_painter.dart'; // Assuming this exists

class EditingVideoScreen extends StatefulWidget {
  const EditingVideoScreen({super.key});

  @override
  State<EditingVideoScreen> createState() => _EditingVideoScreenState();
}

class _EditingVideoScreenState extends State<EditingVideoScreen> {
  final GlobalKey _videoKey = GlobalKey();
  final ValueNotifier<bool> _isDialOpen = ValueNotifier(false);

  @override
  void dispose() {
    _isDialOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => VideoEditingCubit()..pickVideo()),
        BlocProvider(create: (_) => DrawingCubit()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Éditeur de Vidéo"),
          actions: [
            BlocBuilder<DrawingCubit, DrawingState>(
              builder: (context, state) => IconButton(
                icon: const Icon(Icons.undo),
                onPressed: state.drawings.isNotEmpty
                    ? () => context.read<DrawingCubit>().undoDrawing()
                    : null,
              ),
            ),
            BlocBuilder<DrawingCubit, DrawingState>(
              builder: (context, state) => IconButton(
                icon: const Icon(Icons.redo),
                onPressed: state.redoStack.isNotEmpty
                    ? () => context.read<DrawingCubit>().redoDrawing()
                    : null,
              ),
            ),
            BlocBuilder<DrawingCubit, DrawingState>(
              builder: (context, state) => IconButton(
                icon: const Icon(Icons.clear),
                onPressed: state.drawings.isNotEmpty
                    ? () => context.read<DrawingCubit>().clearDrawings()
                    : null,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 50.w),
          child: Column(
            children: [
              SizedBox(height: 50.h),
              BlocBuilder<VideoEditingCubit, VideoEditingState>(
                builder: (context, videoState) {
                  return BlocBuilder<DrawingCubit, DrawingState>(
                    builder: (context, drawingState) {
                      final videoWidth = videoState.controller?.value.size.width ?? double.infinity;
                      final videoHeight = 600.h;
                      return GestureDetector(
                        onTapUp: (details) {
                          if (!drawingState.isDrawing && drawingState.currentMode == DrawingMode.none) {
                            final RenderBox? box = _videoKey.currentContext?.findRenderObject() as RenderBox?;
                            if (box != null) {
                              final localPosition = box.globalToLocal(details.globalPosition);
                              context.read<DrawingCubit>().selectDrawing(localPosition);
                            }
                          }
                        },
                        onPanStart: (details) {
                          final RenderBox? box = _videoKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final localPosition = box.globalToLocal(details.globalPosition);
                            if (drawingState.isDrawing && drawingState.currentMode != DrawingMode.none) {
                              context.read<DrawingCubit>().startDrawing(localPosition);
                            } else {
                              context.read<DrawingCubit>().selectDrawing(localPosition);
                            }
                          }
                        },
                        onPanUpdate: (details) {
                          final RenderBox? box = _videoKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final localPosition = box.globalToLocal(details.globalPosition);
                            if (drawingState.isDrawing && drawingState.currentMode != DrawingMode.none) {
                              context.read<DrawingCubit>().updateDrawing(localPosition, maxWidth: videoWidth, maxHeight: videoHeight);
                            } else if (drawingState.selectedDrawingIndex != null) {
                              context.read<DrawingCubit>().moveDrawing(details.delta, maxWidth: videoWidth, maxHeight: videoHeight);
                            }
                          }
                        },
                        onPanEnd: (_) {
                          if (drawingState.isDrawing && drawingState.currentMode != DrawingMode.none) {
                            context.read<DrawingCubit>().endDrawing();
                            final timestamp = videoState.controller?.value.position.inMilliseconds ?? 0;
                            context.read<VideoEditingCubit>().addDrawing(context.read<DrawingCubit>().state.drawings.last, timestamp);
                          }
                        },
                        child: Container(
                          height: videoHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (videoState.controller != null && videoState.controller!.value.isInitialized)
                                AspectRatio(
                                  aspectRatio: videoState.controller!.value.aspectRatio,
                                  child: VideoPlayer(videoState.controller!),
                                )
                              else
                                const Center(child: Text("Aucune vidéo sélectionnée")),
                              CustomPaint(
                                size: Size(videoWidth, videoHeight),
                                painter: FieldDrawingPainter(
                                  drawingState.drawings,
                                  drawingState.currentPoints,
                                  drawingState.currentMode,
                                  drawingState.currentColor,
                                  drawingState.selectedDrawingIndex,
                                ),
                                child: Container(key: _videoKey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              BlocBuilder<VideoEditingCubit, VideoEditingState>(
                builder: (context, state) => state.showTimeline && state.controller != null
                    ? _buildTimeline(state)
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: 50.h),
              _buildVideoControls(),
              SizedBox(height: 20.h),
              _buildRecordingControls(),
              SizedBox(height: 50.h),
              _buildPickVideoButton(),
            ],
          ),
        ),
        floatingActionButton: _buildSpeedDial(),
      ),
    );
  }

  Widget _buildTimeline(VideoEditingState state) {
    return Container(
      color: Colors.black54,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: state.controller!.value.position.inSeconds.toDouble(),
            min: 0,
            max: state.controller!.value.duration.inSeconds.toDouble(),
            onChanged: (value) => state.controller!.seekTo(Duration(seconds: value.toInt())),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(state.controller!.value.position), style: const TextStyle(color: Colors.white)),
                Text(_formatDuration(state.controller!.value.duration), style: const TextStyle(color: Colors.white)),
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
            icon: const Icon(Icons.replay_10),
            onPressed: state.controller != null ? () => context.read<VideoEditingCubit>().seekBackward() : null,
          ),
          IconButton(
            icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: state.controller != null ? () => context.read<VideoEditingCubit>().togglePlayPause(context) : null,
          ),
          IconButton(
            icon: const Icon(Icons.forward_10),
            onPressed: state.controller != null ? () => context.read<VideoEditingCubit>().seekForward() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return BlocBuilder<VideoEditingCubit, VideoEditingState>(
      builder: (context, state) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: state.controller != null && !state.isRecording
                ? () => context.read<VideoEditingCubit>().startRecording()
                : null,
            child: const Text("Start Record"),
          ),
          SizedBox(width: 20.w),
          ElevatedButton(
            onPressed: state.controller != null && state.isRecording
                ? () => context.read<VideoEditingCubit>().stopRecording(context)
                : null,
            child: const Text("Stop Record"),
          ),
        ],
      ),
    );
  }

  Widget _buildPickVideoButton() {
    return BlocBuilder<VideoEditingCubit, VideoEditingState>(
      builder: (context, state) => ElevatedButton(
        onPressed: state.isPickerActive
            ? null
            : () async {
          var status = await Permission.videos.request();
          if (status.isGranted) {
            context.read<VideoEditingCubit>().pickVideo();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video permission denied")));
          }
        },
        child: const Text("Pick a video"),
      ),
    );
  }

  Widget _buildSpeedDial() {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, state) {
        final cubit = context.read<DrawingCubit>();
        return SpeedDial(
          openCloseDial: _isDialOpen,
          icon: state.isDrawing ? Icons.stop : Icons.edit,
          activeIcon: Icons.close,
          spacing: 10,
          childPadding: const EdgeInsets.all(5),
          spaceBetweenChildren: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          children: [
            SpeedDialChild(
              child: const Icon(Icons.brush),
              label: 'Draw',
              onTap: () {
                if (context.read<VideoEditingCubit>().state.controller?.value.isPlaying == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pause the video to draw")));
                } else {
                  cubit.setDrawingMode(DrawingMode.free);
                  _isDialOpen.value = false;
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.circle_outlined),
              label: 'Circle',
              onTap: () {
                if (context.read<VideoEditingCubit>().state.controller?.value.isPlaying == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pause the video to draw")));
                } else {
                  cubit.setDrawingMode(DrawingMode.circle);
                  _isDialOpen.value = false;
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.person),
              label: 'Player Icon',
              onTap: () {
                if (context.read<VideoEditingCubit>().state.controller?.value.isPlaying == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pause the video to draw")));
                } else {
                  cubit.setDrawingMode(DrawingMode.player);
                  _isDialOpen.value = false;
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.arrow_forward),
              label: 'Arrow',
              onTap: () {
                if (context.read<VideoEditingCubit>().state.controller?.value.isPlaying == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pause the video to draw")));
                } else {
                  cubit.setDrawingMode(DrawingMode.arrow);
                  _isDialOpen.value = false;
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.color_lens),
              label: 'Change Color',
              onTap: () => _showColorPicker(context, cubit),
            ),
          ],
          onPress: () {
            if (state.isDrawing) {
              cubit.endDrawing();
              final timestamp = context.read<VideoEditingCubit>().state.controller?.value.position.inMilliseconds ?? 0;
              context.read<VideoEditingCubit>().addDrawing(cubit.state.drawings.last, timestamp);
              _isDialOpen.value = false;
            } else {
              _isDialOpen.value = !_isDialOpen.value;
            }
          },
        );
      },
    );
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
    ).then((_) => _isDialOpen.value = false);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}