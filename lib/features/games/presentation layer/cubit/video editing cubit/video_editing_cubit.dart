import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../../screen_recorder.dart';
import 'video_editing_state.dart';

class VideoEditingCubit extends Cubit<VideoEditingState> {
  final ImagePicker _picker = ImagePicker();

  VideoEditingCubit() : super(VideoEditingState());

  void updateControllerState() {
    final controller = state.controller;
    if (controller != null && controller.value.isPlaying && state.isDrawing) {
      emit(state.copyWith(isDrawing: false, points: []));
    }
    emit(state.copyWith(isPlaying: controller?.value.isPlaying ?? false));
  }

  Future<void> pickVideo() async {
    if (state.isPickerActive) return;
    emit(state.copyWith(isPickerActive: true));
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final tempDir = await getTemporaryDirectory();
        final persistentPath =
            '${tempDir.path}/picked_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final videoFile = File(video.path);
        await videoFile.copy(persistentPath);

        final controller = VideoPlayerController.file(File(persistentPath));
        await controller.initialize();
        controller.addListener(updateControllerState);
        controller.play();
        emit(
          state.copyWith(
            controller: controller,
            originalVideoPath: persistentPath,
            isPlaying: true,
            isPickerActive: false,
            lines: [],
            redoLines: [],
            selectedDrawingIndex: null,
          ),
        );
      } else {
        emit(state.copyWith(isPickerActive: false));
      }
    } catch (e) {
      emit(state.copyWith(isPickerActive: false));
    }
  }

  void togglePlayPause() {
    final controller = state.controller;
    if (controller != null) {
      final currentTime = controller.value.position.inMilliseconds;
      if (controller.value.isPlaying) {
        controller.pause();
        if (state.isRecording) {
          emit(
            state.copyWith(
              playbackEvents: List.from(state.playbackEvents)
                ..add({'action': 'pause', 'timestamp': currentTime}),
            ),
          );
        }
      } else {
        controller.play();
        if (state.isRecording) {
          emit(
            state.copyWith(
              playbackEvents: List.from(state.playbackEvents)
                ..add({'action': 'play', 'timestamp': currentTime}),
            ),
          );
        }
      }
      updateControllerState();
    }
  }

  void seekBackward() {
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      final currentPosition = controller.value.position;
      final newPosition = Duration(
        milliseconds: max(0, currentPosition.inMilliseconds - 10000),
      );
      controller.seekTo(newPosition).then((_) {
        updateControllerState();
      });
    }
  }

  void seekForward() {
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      final currentPosition = controller.value.position;
      final duration = controller.value.duration;
      final newPosition = Duration(
        milliseconds: min(
          duration.inMilliseconds,
          currentPosition.inMilliseconds + 10000,
        ),
      );
      controller.seekTo(newPosition).then((_) {
        updateControllerState();
      });
    }
  }

  void toggleTimeline() {
    emit(state.copyWith(showTimeline: !state.showTimeline));
  }

  void setDrawingMode(DrawingMode mode, BuildContext context) {
    if (state.controller != null && !state.controller!.value.isPlaying) {
      emit(
        state.copyWith(
          drawingMode: mode,
          isDrawing: true,
          points: [],
          selectedDrawingIndex: null,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please pause the video to draw.")),
      );
    }
  }

  void stopDrawing() {
    emit(
      state.copyWith(
        isDrawing: false,
        points: [],
        drawingMode: DrawingMode.none,
        selectedDrawingIndex: null,
      ),
    );
  }

  void addPoint(Offset point) {
    if (!state.isDrawing) return;

    switch (state.drawingMode) {
      case DrawingMode.free:
        emit(state.copyWith(points: List.from(state.points)..add(point)));
        break;
      case DrawingMode.circle:
      case DrawingMode.player:
      case DrawingMode.arrow:
        if (state.points.isEmpty) {
          emit(state.copyWith(points: [point]));
        } else if (state.points.length == 1 &&
            state.drawingMode != DrawingMode.player) {
          emit(state.copyWith(points: List.from(state.points)..add(point)));
        }
        break;
      case DrawingMode.none:
        break;
    }
  }

  void endDrawing() {
    if (!state.isDrawing || state.controller == null) {
      return;
    }

    final timestamp = state.controller!.value.position.inMilliseconds;
    Map<String, dynamic> newLine;

    switch (state.drawingMode) {
      case DrawingMode.free:
        if (state.points.isNotEmpty) {
          newLine = {
            'points': List<Offset>.from(state.points),
            'timestamp': timestamp,
            'type': 'free',
          };
        } else {
          return;
        }
        break;
      case DrawingMode.circle:
        if (state.points.length == 2) {
          final start = state.points[0];
          final end = state.points[1];
          final radius = (start - end).distance / 2;
          final center = Offset(
            (start.dx + end.dx) / 2,
            (start.dy + end.dy) / 2,
          );
          newLine = {
            'center': center,
            'radius': radius,
            'timestamp': timestamp,
            'type': 'circle',
          };
        } else {
          return;
        }
        break;
      case DrawingMode.player:
        if (state.points.length == 1) {
          newLine = {
            'position': state.points[0],
            'timestamp': timestamp,
            'type': 'player',
          };
        } else {
          return;
        }
        break;
      case DrawingMode.arrow:
        if (state.points.length == 2) {
          final start = state.points[0];
          final end = state.points[1];
          newLine = {
            'start': start,
            'end': end,
            'timestamp': timestamp,
            'type': 'arrow',
          };
        } else {
          return;
        }
        break;
      case DrawingMode.none:
        return;
    }

    emit(
      state.copyWith(
        lines: List.from(state.lines)..add(newLine),
        points: [],
        isDrawing: false,
        drawingMode: DrawingMode.none,
        selectedDrawingIndex: null,
      ),
    );
  }

  void undo() {
    if (state.lines.isNotEmpty) {
      final lastLine = state.lines.last;
      emit(
        state.copyWith(
          lines: List.from(state.lines)..removeLast(),
          redoLines: List.from(state.redoLines)..add(lastLine),
          selectedDrawingIndex: null,
        ),
      );
    }
  }

  void redo() {
    if (state.redoLines.isNotEmpty) {
      final lastRedo = state.redoLines.last;
      emit(
        state.copyWith(
          lines: List.from(state.lines)..add(lastRedo),
          redoLines: List.from(state.redoLines)..removeLast(),
          selectedDrawingIndex: null,
        ),
      );
    }
  }

  void clearDrawings() {
    emit(state.copyWith(lines: [], redoLines: [], selectedDrawingIndex: null));
  }

  Future<void> startRecording(BuildContext context) async {
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/screen_record_${DateTime.now().millisecondsSinceEpoch}.mp4';

      try {
        await ScreenRecorder.startRecording(outputPath);
        emit(
          state.copyWith(
            isRecording: true,
            recordingStartTime: controller.value.position.inMilliseconds,
            recordingEndTime: null,
            // Don't clear playbackEvents unless necessary
            selectedDrawingIndex: null,
            screenRecordingPath: outputPath,
          ),
        );
        if (controller.value.isPlaying) {
          emit(
            state.copyWith(
              playbackEvents: List.from(state.playbackEvents)..add({
                'action': 'play',
                'timestamp': controller.value.position.inMilliseconds,
              }),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error starting screen recording: $e");
        emit(state.copyWith(isRecording: false));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start screen recording: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No video loaded to record.")));
    }
  }

  Future<void> stopRecording(BuildContext context) async {
    final controller = state.controller;
    if (controller != null &&
        controller.value.isInitialized &&
        state.isRecording) {
      try {
        final recordedPath = await ScreenRecorder.stopRecording();
        emit(
          state.copyWith(
            isRecording: false,
            recordingEndTime: controller.value.position.inMilliseconds,
            screenRecordingPath: recordedPath ?? state.screenRecordingPath,
            selectedDrawingIndex: null,
          ),
        );
      } catch (e) {
        debugPrint("Error stopping screen recording: $e");
        emit(state.copyWith(isRecording: false));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to stop screen recording: $e")),
        );
      }
    }
  }

  List<Map<String, dynamic>> getDrawingsForCurrentFrame() {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) {
      return [];
    }

    final currentMs = controller.value.position.inMilliseconds;

    final drawings =
        state.lines.where((line) {
          final lineTimestamp = line['timestamp'] as int;
          final isVisible = lineTimestamp == currentMs;
          return isVisible;
        }).toList();

    return drawings;
  }

  void selectDrawing(Offset tapPosition) {
    final currentTime = state.controller?.value.position.inMilliseconds ?? 0;
    final visibleDrawings = getDrawingsForCurrentFrame();

    if (visibleDrawings.isEmpty) {
      emit(state.copyWith(selectedDrawingIndex: null));
      return;
    }

    Map<String, dynamic>? selectedDrawing;
    int? selectedIndex;
    double minDistance = double.infinity;

    for (int i = 0; i < visibleDrawings.length; i++) {
      final drawing = visibleDrawings[i];
      double distance;

      switch (drawing['type']) {
        case 'player':
          final position = drawing['position'] as Offset;
          distance = (position - tapPosition).distance;
          if (distance < 40 && distance < minDistance) {
            selectedDrawing = drawing;
            selectedIndex = state.lines.indexOf(drawing);
            minDistance = distance;
          }
          break;
        case 'arrow':
          final start = drawing['start'] as Offset;
          final end = drawing['end'] as Offset;
          distance = _distanceToLine(tapPosition, start, end);
          if (distance < 40 && distance < minDistance) {
            selectedDrawing = drawing;
            selectedIndex = state.lines.indexOf(drawing);
            minDistance = distance;
          }
          break;
        case 'circle':
          final center = drawing['center'] as Offset;
          final radius = drawing['radius'] as double;
          distance = (center - tapPosition).distance;
          if (distance < radius + 20 && distance < minDistance) {
            selectedDrawing = drawing;
            selectedIndex = state.lines.indexOf(drawing);
            minDistance = distance;
          }
          break;
        case 'free':
          final points = drawing['points'] as List<Offset>;
          for (int j = 0; j < points.length - 1; j++) {
            distance = _distanceToLine(tapPosition, points[j], points[j + 1]);
            if (distance < 40 && distance < minDistance) {
              selectedDrawing = drawing;
              selectedIndex = state.lines.indexOf(drawing);
              minDistance = distance;
            }
          }
          break;
      }
    }

    if (selectedDrawing != null && selectedIndex != null) {
      emit(state.copyWith(selectedDrawingIndex: selectedIndex));
    } else {
      emit(state.copyWith(selectedDrawingIndex: null));
    }
  }

  void moveSelectedDrawing(Offset newPosition) {
    final index = state.selectedDrawingIndex;
    if (index == null || index < 0 || index >= state.lines.length) {
      return;
    }

    final drawing = state.lines[index];
    final updatedLines = List<Map<String, dynamic>>.from(state.lines);

    switch (drawing['type']) {
      case 'player':
        updatedLines[index] = {...drawing, 'position': newPosition};
        break;
      case 'arrow':
        final start = drawing['start'] as Offset;
        final end = drawing['end'] as Offset;
        final midpoint = _midpoint(start, end);
        final delta = newPosition - midpoint;
        updatedLines[index] = {
          ...drawing,
          'start': Offset(start.dx + delta.dx, start.dy + delta.dy),
          'end': Offset(end.dx + delta.dx, end.dy + delta.dy),
        };
        break;
      case 'circle':
        final center = drawing['center'] as Offset;
        final radius = drawing['radius'] as double;
        final delta = newPosition - center;
        updatedLines[index] = {
          ...drawing,
          'center': Offset(center.dx + delta.dx, center.dy + delta.dy),
        };
        break;
      case 'free':
        final points = drawing['points'] as List<Offset>;
        final delta = newPosition - _calculateFreeDrawingCenter(points);
        final updatedPoints = points.map((point) => point + delta).toList();
        updatedLines[index] = {...drawing, 'points': updatedPoints};
        break;
    }

    emit(state.copyWith(lines: updatedLines));
  }

  Offset _calculateFreeDrawingCenter(List<Offset> points) {
    double sumX = 0, sumY = 0;
    for (final point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / points.length, sumY / points.length);
  }

  void deselectDrawing() {
    emit(state.copyWith(selectedDrawingIndex: null));
  }

  double _distanceToLine(Offset point, Offset start, Offset end) {
    final lineLength = (end - start).distance;
    if (lineLength == 0) return (point - start).distance;

    final t =
        ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        (lineLength * lineLength);
    final tClamped = t.clamp(0.0, 1.0);
    final closest = Offset(
      start.dx + tClamped * (end.dx - start.dx),
      start.dy + tClamped * (end.dy - start.dy),
    );
    return (point - closest).distance;
  }

  Offset _midpoint(Offset start, Offset end) {
    return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  }

  @override
  Future<void> close() async {
    state.controller?.removeListener(updateControllerState);
    state.controller?.dispose();
    if (state.originalVideoPath != null) {
      final file = File(state.originalVideoPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    if (state.screenRecordingPath != null) {
      final file = File(state.screenRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    return super.close();
  }

  void changeDrawingColor(Color color) {
    emit(state.copyWith(drawingColor: color));
  }
}
