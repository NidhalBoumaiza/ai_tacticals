import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:video_player/video_player.dart';
import '../../cubit/lineup drawing cubut/drawing__cubit.dart';
import '../../cubit/lineup drawing cubut/drawing__state.dart';
import '../../cubit/video editing cubit/video_editing_cubit.dart';
import '../../cubit/video editing cubit/video_editing_state.dart';
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
        body: BlocBuilder<VideoEditingCubit, VideoEditingState>(
          builder: (context, videoState) {
            return BlocBuilder<DrawingCubit, DrawingState>(
              builder: (context, drawingState) {
                final videoWidth = MediaQuery.of(context).size.width;
                final videoHeight = MediaQuery.of(context).size.height - 100; // Adjust for timeline/controls
                final currentTimestamp = videoState.controller?.value.position.inMilliseconds ?? 0;

                final visibleDrawings = videoState.lines
                    .where((line) => (line['timestamp'] as int) == currentTimestamp)
                    .map((line) => line['drawing'] as DrawingItem)
                    .toList();

                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              GestureDetector(
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
                                          const Center(child: Text("Erreur: Vidéo non chargée")),
                                        CustomPaint(
                                          size: Size(videoWidth, videoHeight),
                                          painter: FieldDrawingPainter(
                                            drawingState.isDrawing ? drawingState.drawings : visibleDrawings,
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
                              Positioned(
                                bottom: 20,
                                left: 20,
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
                                  child: const Icon(Icons.fiber_manual_record),
                                  backgroundColor: Colors.red,
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 100,
                                child: FloatingActionButton(
                                  onPressed: videoState.controller != null && videoState.isRecording
                                      ? () => context.read<VideoEditingCubit>().stopRecording(context)
                                      : null,
                                  child: const Icon(Icons.stop),
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: _buildSpeedDial(context),
                              ),
                            ],
                          ),
                        ),
                        BlocBuilder<VideoEditingCubit, VideoEditingState>(
                          builder: (context, state) => state.showTimeline && state.controller != null
                              ? _buildTimeline(state)
                              : const SizedBox.shrink(),
                        ),
                        _buildVideoControls(),
                      ],
                    ),
                    // Back button positioned at top-left
                    Positioned(
                      top: 20,
                      left: 20,
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
            onChanged: (value) => state.controller!.seekTo(Duration(seconds: value.toInt())),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
            onPressed: state.controller != null
                ? () => context.read<VideoEditingCubit>().togglePlayPause(context, videoKey: _videoKey)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.forward_10),
            onPressed: state.controller != null ? () => context.read<VideoEditingCubit>().seekForward() : null,
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

  Widget _buildSpeedDial(BuildContext context) {
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
            SpeedDialChild(
              child: const Icon(Icons.undo),
              label: 'Undo',
              onTap: () {
                if (state.drawings.isNotEmpty) {
                  cubit.undoDrawing();
                  _isDialOpen.value = false;
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.redo),
              label: 'Redo',
              onTap: () {
                if (state.redoStack.isNotEmpty) {
                  cubit.redoDrawing();
                  _isDialOpen.value = false;
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.clear),
              label: 'Clear',
              onTap: () {
                if (state.drawings.isNotEmpty) {
                  cubit.clearDrawings();
                  _isDialOpen.value = false;
                }
              },
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
}