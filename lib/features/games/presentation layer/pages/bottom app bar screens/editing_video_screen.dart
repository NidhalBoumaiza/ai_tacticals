import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_recorder/screen_recorder.dart';
import 'package:video_player/video_player.dart';

import '../../cubit/video editing cubit/video_editing_cubit.dart';
import '../../cubit/video editing cubit/video_editing_state.dart';

class EditingVideoScreen extends StatelessWidget {
  const EditingVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoEditingCubit(),
      child: BlocListener<VideoEditingCubit, VideoEditingState>(
        listener: (context, state) {
          if (state.showSnackbar) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.snackbarMessage!)),
            );
            // Reset the snackbar state
            context.read<VideoEditingCubit>().emit(state.copyWith(
              showSnackbar: false,
              snackbarMessage: null,
            ));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text("Éditeur de Vidéo"),
            actions: [
              BlocBuilder<VideoEditingCubit, VideoEditingState>(
                builder: (context, state) {
                  return IconButton(
                    icon: Icon(Icons.undo),
                    onPressed: state.lines.isNotEmpty
                        ? () => context.read<VideoEditingCubit>().undo()
                        : null,
                  );
                },
              ),
              BlocBuilder<VideoEditingCubit, VideoEditingState>(
                builder: (context, state) {
                  return IconButton(
                    icon: Icon(Icons.redo),
                    onPressed: state.redoLines.isNotEmpty
                        ? () => context.read<VideoEditingCubit>().redo()
                        : null,
                  );
                },
              ),
              BlocBuilder<VideoEditingCubit, VideoEditingState>(
                builder: (context, state) {
                  return IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: state.lines.isNotEmpty
                        ? () => context.read<VideoEditingCubit>().clearDrawings()
                        : null,
                    tooltip: "Clear Drawings",
                  );
                },
              ),
              BlocBuilder<VideoEditingCubit, VideoEditingState>(
                builder: (context, state) {
                  return IconButton(
                    icon: Icon(Icons.save_alt),
                    onPressed: state.recordingEndTime != null
                        ? () => _saveVideoWithDrawings(context)
                        : null,
                    tooltip: "Download Recorded Video",
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.w),
            child: Column(
              children: [
                SizedBox(height: 50.h),
                BlocBuilder<VideoEditingCubit, VideoEditingState>(
                  builder: (context, state) {
                    return GestureDetector(
                      onTapDown: (details) {
                        if (state.isDrawing && state.drawingMode != DrawingMode.free) {
                          context.read<VideoEditingCubit>().addPoint(details.localPosition);
                          context.read<VideoEditingCubit>().endDrawing();
                        } else if (!state.isDrawing) {
                          context.read<VideoEditingCubit>().selectDrawing(details.localPosition);
                        }
                      },
                      onTap: () {
                        if (!state.isDrawing && state.selectedDrawingIndex == null) {
                          context.read<VideoEditingCubit>().toggleTimeline();
                        }
                      },
                      onPanStart: (details) {
                        if (state.isDrawing) {
                          context.read<VideoEditingCubit>().addPoint(details.localPosition);
                        } else {
                          context.read<VideoEditingCubit>().selectDrawing(details.localPosition);
                        }
                      },
                      onPanUpdate: (details) {
                        if (state.isDrawing) {
                          context.read<VideoEditingCubit>().addPoint(details.localPosition);
                        } else if (state.selectedDrawingIndex != null) {
                          context.read<VideoEditingCubit>().moveSelectedDrawing(details.localPosition);
                        }
                      },
                      onPanEnd: (_) {
                        if (state.isDrawing) {
                          context.read<VideoEditingCubit>().endDrawing();
                        } else if (state.selectedDrawingIndex != null) {
                          context.read<VideoEditingCubit>().deselectDrawing();
                        }
                      },
                      child: ScreenRecorder(
                        controller: state.screenRecorderController,
                        height: 600.h, // Match the container height
                        width: double.infinity, // Match the container width
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          height: state.controller != null ? 600.h : null,
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              if (state.controller != null && state.controller!.value.isInitialized)
                                AspectRatio(
                                  aspectRatio: state.controller!.value.aspectRatio,
                                  child: VideoPlayer(state.controller!),
                                )
                              else
                                Center(child: Text("Aucune vidéo sélectionnée")),
                              if (state.controller != null)
                                CustomPaint(
                                  size: Size(double.infinity, 600.h),
                                  painter: DrawingPainter(
                                    context.read<VideoEditingCubit>().getDrawingsForCurrentFrame(),
                                    state.isDrawing ? state.points : [],
                                    state.drawingMode,
                                    state.drawingColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                BlocBuilder<VideoEditingCubit, VideoEditingState>(
                  builder: (context, state) {
                    if (state.showTimeline && state.controller != null) {
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
                              onChanged: (value) {
                                state.controller!.seekTo(Duration(seconds: value.toInt()));
                              },
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(state.controller!.value.position),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    _formatDuration(state.controller!.value.duration),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                SizedBox(height: 50.h),
                BlocBuilder<VideoEditingCubit, VideoEditingState>(
                  builder: (context, state) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.replay_10),
                          onPressed: state.controller != null
                              ? () => context.read<VideoEditingCubit>().seekBackward()
                              : null,
                        ),
                        IconButton(
                          icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: state.controller != null
                              ? () => context.read<VideoEditingCubit>().togglePlayPause()
                              : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.forward_10),
                          onPressed: state.controller != null
                              ? () => context.read<VideoEditingCubit>().seekForward()
                              : null,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20.h),
                BlocBuilder<VideoEditingCubit, VideoEditingState>(
                  builder: (context, state) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: state.controller != null && !state.isRecording
                              ? () => context.read<VideoEditingCubit>().startRecording()
                              : null,
                          child: Text("Start Record"),
                        ),
                        SizedBox(width: 20.w),
                        ElevatedButton(
                          onPressed: state.controller != null && state.isRecording
                              ? () => context.read<VideoEditingCubit>().stopRecording()
                              : null,
                          child: Text("Stop Record"),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 50.h),
                BlocBuilder<VideoEditingCubit, VideoEditingState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.isPickerActive
                          ? null
                          : () async {
                        var status = await Permission.videos.request();
                        if (status.isGranted) {
                          context.read<VideoEditingCubit>().pickVideo();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Video permission denied")),
                          );
                        }
                      },
                      child: Text("Pick a video"),
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: BlocBuilder<VideoEditingCubit, VideoEditingState>(
            builder: (context, state) {
              final cubit = context.read<VideoEditingCubit>();
              final isOpen = ValueNotifier<bool>(false);
              return SpeedDial(
                icon: state.isDrawing ? Icons.stop : Icons.edit,
                activeIcon: Icons.close,
                spacing: 10,
                childPadding: EdgeInsets.all(5),
                spaceBetweenChildren: 4,
                openCloseDial: isOpen,
                children: [
                  SpeedDialChild(
                    child: Icon(Icons.brush),
                    label: 'Draw',
                    onTap: () {
                      cubit.setDrawingMode(DrawingMode.free, context);
                      isOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.circle_outlined),
                    label: 'Circle',
                    onTap: () {
                      cubit.setDrawingMode(DrawingMode.circle, context);
                      isOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: FaIcon(FontAwesomeIcons.person),
                    label: 'Player Icon',
                    onTap: () {
                      cubit.setDrawingMode(DrawingMode.player, context);
                      isOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.arrow_forward),
                    label: 'Arrow',
                    onTap: () {
                      cubit.setDrawingMode(DrawingMode.arrow, context);
                      isOpen.value = false;
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.color_lens),
                    label: 'Change Color',
                    onTap: () {
                      _showColorPicker(context);
                      isOpen.value = false;
                    },
                  ),
                ],
                onOpen: () {},
                onClose: () {},
                onPress: () {
                  if (state.isDrawing) {
                    cubit.stopDrawing();
                    isOpen.value = false;
                  } else {
                    isOpen.value = !isOpen.value;
                  }
                },
              );
            },
          ),
        ),
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

  Future<void> _saveVideoWithDrawings(BuildContext context) async {
    final cubit = context.read<VideoEditingCubit>();
    final state = cubit.state;

    if (state.controller == null ||
        state.originalVideoPath == null ||
        state.recordingStartTime == null ||
        state.recordingEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No recorded video to save.")),
      );
      return;
    }

    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final outputPath =
          '${downloadsDir.path}/recorded_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final originalVideoFile = File(state.originalVideoPath!);
      if (!await originalVideoFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Original video file is missing")),
        );
        throw Exception(
          "Original video file does not exist: ${state.originalVideoPath}",
        );
      }

      final startTimeMs = state.recordingStartTime!;
      final endTimeMs = state.recordingEndTime!;
      final durationSec = (endTimeMs - startTimeMs) / 1000.0;

      final tempDir = await getTemporaryDirectory();
      final tempVideoPath = '${tempDir.path}/temp_recorded.mp4';

      String extractCommand =
          '-i "${state.originalVideoPath}" -ss ${startTimeMs / 1000.0} -t $durationSec -c:v copy -c:a copy "$tempVideoPath"';
      final extractSession = await FFmpegKit.execute(extractCommand);
      final extractReturnCode = await extractSession.getReturnCode();

      if (extractReturnCode?.isValueSuccess() != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to extract recorded portion")),
        );
        return;
      }

      final tempVideoFile = File(tempVideoPath);
      if (!await tempVideoFile.exists()) {
        throw Exception("Temp video file does not exist: $tempVideoPath");
      }

      if (state.lines.isEmpty) {
        String finalCommand =
            '-i "$tempVideoPath" -c:v copy -c:a copy "$outputPath"';
        final finalSession = await FFmpegKit.execute(finalCommand);
        final finalReturnCode = await finalSession.getReturnCode();

        if (finalReturnCode?.isValueSuccess() == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Video saved to Downloads: $outputPath")),
          );

          await tempVideoFile.delete();

          final newController = VideoPlayerController.file(File(outputPath));
          await newController.initialize();
          newController.addListener(cubit.updateControllerState);
          cubit.emit(
            state.copyWith(controller: newController, isPlaying: false),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save video")),
          );
        }
      } else {
        // Add overlay logic here if needed
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving video: $e")),
      );
    }
  }

  Future<String?> _saveDrawingAsImage(
      BuildContext context,
      int timestamp,
      VideoPlayerController controller,
      ) async {
    final drawingsToSave =
    context.read<VideoEditingCubit>().state.lines.where((line) {
      final diff = (line['timestamp'] as int) - timestamp;
      return diff.abs() < 100;
    }).toList();

    if (drawingsToSave.isEmpty) {
      return null;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint =
    Paint()
      ..color = Colors.green
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (var drawing in drawingsToSave) {
      switch (drawing['type']) {
        case 'free':
          final points = drawing['points'] as List<Offset>;
          for (int i = 0; i < points.length - 1; i++) {
            canvas.drawLine(points[i], points[i + 1], paint);
          }
          break;
        case 'circle':
          final center = drawing['center'] as Offset;
          final radius = drawing['radius'] as double;
          canvas.drawCircle(
            center,
            radius,
            paint..style = PaintingStyle.stroke,
          );
          break;
        case 'player':
          final position = drawing['position'] as Offset;
          _drawPlayIcon(canvas, position, paint);
          break;
        case 'arrow':
          final start = drawing['start'] as Offset;
          final end = drawing['end'] as Offset;
          _drawArrow(canvas, start, end, paint);
          break;
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      controller.value.size.width.toInt(),
      controller.value.size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/drawing_$timestamp.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void _drawPlayIcon(Canvas canvas, Offset position, Paint paint) {
    final path =
    Path()
      ..moveTo(position.dx - 10, position.dy - 15)
      ..lineTo(position.dx + 15, position.dy)
      ..lineTo(position.dx - 10, position.dy + 15)
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 10.0;
    final path =
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            end.dx - arrowSize * cos(angle - pi / 6),
            end.dy - arrowSize * sin(angle - pi / 6),
          )
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            end.dx - arrowSize * cos(angle + pi / 6),
            end.dy - arrowSize * sin(angle + pi / 6),
          );
    canvas.drawPath(path, paint);
  }

  void _showColorPicker(BuildContext context) {
    final cubit = context.read<VideoEditingCubit>();
    final currentColor = cubit.state.drawingColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                cubit.changeDrawingColor(color);
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Map<String, dynamic>> drawings;
  final List<Offset> currentPoints;
  final DrawingMode drawingMode;
  final Color drawingColor;

  DrawingPainter(
    this.drawings,
    this.currentPoints,
    this.drawingMode,
    this.drawingColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = drawingColor
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;

    for (var drawing in drawings) {
      switch (drawing['type']) {
        case 'free':
          final points = drawing['points'] as List<Offset>;
          for (int i = 0; i < points.length - 1; i++) {
            canvas.drawLine(points[i], points[i + 1], paint);
          }
          break;
        case 'circle':
          final center = drawing['center'] as Offset;
          final radius = drawing['radius'] as double;
          canvas.drawCircle(
            center,
            radius * 1.5,
            paint..style = PaintingStyle.stroke,
          );
          break;
        case 'player':
          final position = drawing['position'] as Offset;
          _drawPersonRunningIcon(canvas, position, paint);
          break;
        case 'arrow':
          final start = drawing['start'] as Offset;
          final end = drawing['end'] as Offset;
          _drawArrow(canvas, start, end, paint);
          break;
      }
    }

    if (currentPoints.isNotEmpty) {
      switch (drawingMode) {
        case DrawingMode.free:
          for (int i = 0; i < currentPoints.length - 1; i++) {
            canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
          }
          break;
        case DrawingMode.circle:
          if (currentPoints.length == 2) {
            final start = currentPoints[0];
            final end = currentPoints[1];
            final radius = (start - end).distance / 2 * 1.5;
            final center = Offset(
              (start.dx + end.dx) / 2,
              (start.dy + end.dy) / 2,
            );
            canvas.drawCircle(
              center,
              radius,
              paint..style = PaintingStyle.stroke,
            );
          }
          break;
        case DrawingMode.player:
          if (currentPoints.isNotEmpty) {
            _drawPersonRunningIcon(canvas, currentPoints[0], paint);
          }
          break;
        case DrawingMode.arrow:
          if (currentPoints.length == 2) {
            _drawArrow(canvas, currentPoints[0], currentPoints[1], paint);
          }
          break;
        case DrawingMode.none:
          break;
      }
    }
  }

  void _drawPersonRunningIcon(Canvas canvas, Offset position, Paint paint) {
    final double size = 30.0;
    canvas.drawCircle(position, size * 0.2, paint..style = PaintingStyle.fill);
    final Offset bodyStart = Offset(position.dx, position.dy + size * 0.2);
    final Offset bodyEnd = Offset(position.dx, position.dy + size * 0.8);
    canvas.drawLine(bodyStart, bodyEnd, paint);
    final Offset leftArmStart = Offset(
      position.dx - size * 0.3,
      position.dy + size * 0.4,
    );
    final Offset leftArmEnd = Offset(
      position.dx + size * 0.3,
      position.dy + size * 0.4,
    );
    canvas.drawLine(leftArmStart, leftArmEnd, paint);
    final Offset leftLegStart = Offset(
      position.dx - size * 0.2,
      position.dy + size * 0.8,
    );
    final Offset leftLegEnd = Offset(position.dx, position.dy + size * 1.2);
    canvas.drawLine(leftLegStart, leftLegEnd, paint);
    final Offset rightLegStart = Offset(
      position.dx + size * 0.2,
      position.dy + size * 0.8,
    );
    final Offset rightLegEnd = Offset(position.dx, position.dy + size * 1.2);
    canvas.drawLine(rightLegStart, rightLegEnd, paint);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 20.0;
    final path =
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            end.dx - arrowSize * cos(angle - pi / 6),
            end.dy - arrowSize * sin(angle - pi / 6),
          )
          ..lineTo(
            end.dx - arrowSize * cos(angle + pi / 6),
            end.dy - arrowSize * sin(angle + pi / 6),
          )
          ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
