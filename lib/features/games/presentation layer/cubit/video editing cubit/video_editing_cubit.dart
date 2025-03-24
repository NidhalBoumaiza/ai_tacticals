import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../../core/utils/custom_snack_bar.dart';
import 'video_editing_state.dart';

class VideoEditingCubit extends Cubit<VideoEditingState> {
  final ImagePicker _picker = ImagePicker();

  VideoEditingCubit() : super(VideoEditingState());

  // Core methods
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
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null) {
        emit(state.copyWith(isPickerActive: false));
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final persistentPath = '${tempDir.path}/picked_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await File(video.path).copy(persistentPath);

      final controller = VideoPlayerController.file(File(persistentPath));
      await controller.initialize();
      controller.addListener(updateControllerState);
      controller.play();

      emit(state.copyWith(
        controller: controller,
        originalVideoPath: persistentPath,
        isPlaying: true,
        isPickerActive: false,
        lines: [],
        redoLines: [],
        selectedDrawingIndex: null,
        pauseSegments: [],
        playbackEvents: [],
        pauseStartTime: null,
      ));
    } catch (e) {
      emit(state.copyWith(isPickerActive: false));
      debugPrint('Error picking video: $e');
    }
  }

  void togglePlayPause(BuildContext context) {
    final controller = state.controller;
    if (controller == null) return;

    final currentTime = controller.value.position.inMilliseconds;

    if (controller.value.isPlaying) {
      // Pausing the video
      controller.pause();

      // Save the current frame as an image
      _saveCurrentFrame(currentTime).then((imagePath) {
        if (imagePath != null) {
          emit(state.copyWith(
            pauseStartTime: currentTime,
            playbackEvents: List.from(state.playbackEvents)
              ..add({
                'action': 'pause',
                'timestamp': currentTime,
                'imagePath': imagePath
              }),
          ));
        }
      });
    } else {
      // Playing the video
      final pauseEndTime = currentTime;
      final pauseDuration = pauseEndTime - (state.pauseStartTime ?? pauseEndTime);

      if (state.pauseStartTime != null) {
        emit(state.copyWith(
          pauseSegments: List.from(state.pauseSegments)
            ..add(PauseSegment(
              position: Duration(milliseconds: state.pauseStartTime!),
              duration: Duration(milliseconds: pauseDuration),
            )),
          playbackEvents: List.from(state.playbackEvents)
            ..add({
              'action': 'play',
              'timestamp': pauseEndTime,
              'pauseDuration': pauseDuration
            }),
          pauseStartTime: null,
        ));
      }

      controller.play();
    }
    updateControllerState();
  }

  Future<String?> _saveCurrentFrame(int timestamp) async {
    try {
      if (state.controller == null || state.originalVideoPath == null) return null;

      final image = await VideoThumbnail.thumbnailData(
        video: state.originalVideoPath!,
        imageFormat: ImageFormat.PNG,
        quality: 100,
        timeMs: timestamp,
      );

      if (image == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pause_frame_$timestamp.png');
      await file.writeAsBytes(image);
      return file.path;
    } catch (e) {
      debugPrint('Error saving frame: $e');
      return null;
    }
  }

  // Drawing methods
  void setDrawingMode(DrawingMode mode, BuildContext context) {
    if (state.controller == null || state.controller!.value.isPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pause the video to draw.")),
      );
      return;
    }
    emit(state.copyWith(
      drawingMode: mode,
      isDrawing: true,
      points: [],
      selectedDrawingIndex: null,
    ));
  }

  void addPoint(Offset point) {
    if (!state.isDrawing) return;

    final newPoints = List<Offset>.from(state.points);
    newPoints.add(point);
    emit(state.copyWith(points: newPoints));
  }

  void endDrawing() {
    if (!state.isDrawing || state.controller == null) return;

    final timestamp = state.controller!.value.position.inMilliseconds;
    final newLine = _createDrawingObject(timestamp);
    if (newLine == null) return;

    emit(state.copyWith(
      lines: List.from(state.lines)..add(newLine),
      points: [],
      isDrawing: false,
      drawingMode: DrawingMode.none,
    ));
  }

  Map<String, dynamic>? _createDrawingObject(int timestamp) {
    switch (state.drawingMode) {
      case DrawingMode.free:
        if (state.points.isEmpty) return null;
        return {
          'points': List<Offset>.from(state.points),
          'timestamp': timestamp,
          'type': 'free',
        };
      case DrawingMode.circle:
        if (state.points.length < 2) return null;
        final start = state.points[0];
        final end = state.points[1];
        return {
          'center': Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
          'radius': (start - end).distance / 2,
          'timestamp': timestamp,
          'type': 'circle',
        };
      case DrawingMode.player:
        if (state.points.isEmpty) return null;
        return {
          'position': state.points[0],
          'timestamp': timestamp,
          'type': 'player',
        };
      case DrawingMode.arrow:
        if (state.points.length < 2) return null;
        return {
          'start': state.points[0],
          'end': state.points[1],
          'timestamp': timestamp,
          'type': 'arrow',
        };
      default:
        return null;
    }
  }

  // Video processing
  Future<void> startRecording() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;

    emit(state.copyWith(
      isRecording: true,
      recordingStartTime: controller.value.position.inMilliseconds,
      playbackEvents: [],
      lines: [],
      redoLines: [],
      pauseSegments: [],
    ));
    controller.play();
  }

  Future<void> stopRecording(BuildContext context) async {
    final controller = state.controller;
    if (controller == null || !state.isRecording) return;

    final endTime = controller.value.position.inMilliseconds;
    controller.pause();

    // Add any final pause segment if video was paused when stopping
    if (state.pauseStartTime != null) {
      final pauseDuration = endTime - state.pauseStartTime!;
      emit(state.copyWith(
        pauseSegments: List.from(state.pauseSegments)
          ..add(PauseSegment(
            position: Duration(milliseconds: state.pauseStartTime!),
            duration: Duration(milliseconds: pauseDuration),
          )),
        playbackEvents: List.from(state.playbackEvents)
          ..add({
            'action': 'play',
            'timestamp': endTime,
            'pauseDuration': pauseDuration
          }),
        pauseStartTime: null,
      ));
    }

    emit(state.copyWith(
      isRecording: false,
      recordingEndTime: endTime,
    ));

    await _processAndSaveRecording(context);
  }

  Future<void> _processAndSaveRecording(BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final baseVideo = await _extractBaseVideoSegment(tempDir.path);
      final finalVideo = await _applyEffectsAndSave(baseVideo, tempDir.path);

      await _saveToDownloads(finalVideo);
      showSuccessSnackBar(context, "Video saved successfully!");
    } catch (e) {
      showErrorSnackBar(context, "Failed to save video: ${e.toString()}");
    } finally {
      resetState();
    }
  }

  Future<String> _extractBaseVideoSegment(String tempDir) async {
    final outputPath = '$tempDir/base_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final cmd = '-y -i "${state.originalVideoPath}" '
        '-ss ${state.recordingStartTime!/1000} '
        '-to ${state.recordingEndTime!/1000} '
        '-c copy "$outputPath"';

    final result = await FFmpegKit.execute(cmd);
    if (!ReturnCode.isSuccess(await result.getReturnCode())) {
      throw Exception('Video extraction failed');
    }
    return outputPath;
  }

  Future<String> _applyEffectsAndSave(String baseVideo, String tempDir) async {
    final outputPath = '$tempDir/final_${DateTime.now().millisecondsSinceEpoch}.mp4';
    debugPrint('Starting _applyEffectsAndSave with baseVideo: $baseVideo');

    if (state.pauseSegments.isEmpty) {
      debugPrint('No pause segments, copying base video directly');
      final result = await FFmpegKit.execute('-y -i "$baseVideo" -c copy "$outputPath"');
      final output = await result.getOutput();
      debugPrint('Copy result: $output');
      if (!ReturnCode.isSuccess(await result.getReturnCode())) {
        throw Exception('Failed to copy base video: $output');
      }
      return outputPath;
    }

    final sortedPauses = List<PauseSegment>.from(state.pauseSegments)
      ..sort((a, b) => a.position.compareTo(b.position));
    final pauseVideos = <String>[];
    final videoSegments = <String>[];
    int lastEnd = 0;

    debugPrint('Processing ${sortedPauses.length} pause segments');
    for (int i = 0; i < sortedPauses.length; i++) {
      final segment = sortedPauses[i];
      if (segment.position.inMilliseconds <= lastEnd) continue;

      // Video segment before pause
      final segmentPath = '$tempDir/segment_$i.mp4';
      final duration = (segment.position.inMilliseconds - lastEnd) / 1000.0;
      final cmd = '-y -i "$baseVideo" '
          '-ss ${lastEnd / 1000.0} '
          '-t $duration '
          '-c:v mpeg4 -b:v 1000k -c:a aac -b:a 128k -r 25 "$segmentPath"';
      debugPrint('Splitting video segment $i: $cmd');
      final segmentResult = await FFmpegKit.execute(cmd);
      final segmentOutput = await segmentResult.getOutput();
      debugPrint('Segment $i result: $segmentOutput');
      if (!ReturnCode.isSuccess(await segmentResult.getReturnCode())) {
        throw Exception('Failed to split video segment $i: $segmentOutput');
      }
      debugPrint('Segment $i size: ${File(segmentPath).existsSync() ? await File(segmentPath).length() : "Not found"} bytes');
      videoSegments.add(segmentPath);

      // Pause segment with silent audio
      final pauseEvent = state.playbackEvents.firstWhere(
            (e) => e['action'] == 'pause' && e['timestamp'] == segment.position.inMilliseconds,
      );
      final pauseImagePath = pauseEvent['imagePath'] as String;
      final pauseVideoPath = '$tempDir/pause_${segment.position.inMilliseconds}.mp4';
      final pauseDuration = 2; // Default to 2 seconds if duration is missing
      final pauseCmd = '-y -loop 1 -i "$pauseImagePath" '
          '-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 '
          '-c:v mpeg4 -b:v 1000k -c:a aac -b:a 128k '
          '-t $pauseDuration '
          '-vf "scale=640:360,setpts=PTS-STARTPTS" '
          '-r 25 '
          '"$pauseVideoPath"';
      debugPrint('Creating pause segment at ${segment.position.inMilliseconds}ms: $pauseCmd');
      final pauseResult = await FFmpegKit.execute(pauseCmd);
      final pauseOutput = await pauseResult.getOutput();
      debugPrint('Pause segment result: $pauseOutput');
      if (!ReturnCode.isSuccess(await pauseResult.getReturnCode())) {
        throw Exception('Failed to create pause segment: $pauseOutput');
      }
      debugPrint('Pause segment size: ${File(pauseVideoPath).existsSync() ? await File(pauseVideoPath).length() : "Not found"} bytes');
      pauseVideos.add(pauseVideoPath);
      lastEnd = segment.position.inMilliseconds + (pauseDuration * 1000);
    }

    // Remaining video (if any)
    final baseDurationResult = await FFmpegKit.execute('-i "$baseVideo" -f null -');
    final baseDurationOutput = await baseDurationResult.getOutput();
    final durationMatch = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})').firstMatch(baseDurationOutput ?? '');
    if (durationMatch != null) {
      final hours = int.parse(durationMatch.group(1)!);
      final minutes = int.parse(durationMatch.group(2)!);
      final seconds = double.parse(durationMatch.group(3)!);
      final baseDurationMs = (hours * 3600 + minutes * 60 + seconds) * 1000;
      if (lastEnd < baseDurationMs) {
        final remainingPath = '$tempDir/segment_final.mp4';
        final remainingCmd = '-y -i "$baseVideo" '
            '-ss ${lastEnd / 1000.0} '
            '-c:v mpeg4 -b:v 1000k -c:a aac -b:a 128k -r 25 "$remainingPath"';
        debugPrint('Extracting remaining video: $remainingCmd');
        final remainingResult = await FFmpegKit.execute(remainingCmd);
        final remainingOutput = await remainingResult.getOutput();
        debugPrint('Remaining segment result: $remainingOutput');
        if (!ReturnCode.isSuccess(await remainingResult.getReturnCode())) {
          throw Exception('Failed to extract remaining video: $remainingOutput');
        }
        debugPrint('Remaining segment size: ${File(remainingPath).existsSync() ? await File(remainingPath).length() : "Not found"} bytes');
        videoSegments.add(remainingPath);
      }
    }

    // Concatenation
    final concatList = <String>[];
    for (int i = 0; i < videoSegments.length; i++) {
      concatList.add("file '${videoSegments[i]}'");
      if (i < pauseVideos.length) {
        concatList.add("file '${pauseVideos[i]}'");
      }
    }
    final concatFilePath = '$tempDir/concat.txt';
    await File(concatFilePath).writeAsString(concatList.join('\n'));
    debugPrint('Concat list: ${concatList.join('\n')}');

    final concatCmd = '-y -f concat -safe 0 -i "$concatFilePath" '
        '-c:v mpeg4 -b:v 1000k -c:a aac -b:a 128k -r 25 "$outputPath"';
    debugPrint('Concatenating segments: $concatCmd');
    final concatResult = await FFmpegKit.execute(concatCmd);
    final concatOutput = await concatResult.getOutput();
    debugPrint('Concatenation result: $concatOutput');
    if (!ReturnCode.isSuccess(await concatResult.getReturnCode())) {
      throw Exception('Failed to concatenate video segments: $concatOutput');
    }
    debugPrint('Final output size: ${File(outputPath).existsSync() ? await File(outputPath).length() : "Not found"} bytes');

    // Clean up
    debugPrint('Cleaning up temporary files');
    await Future.wait([
      ...pauseVideos.map((path) => File(path).delete().catchError((_) => debugPrint('Failed to delete $path'))),
      ...videoSegments.map((path) => File(path).delete().catchError((_) => debugPrint('Failed to delete $path'))),
      File(concatFilePath).delete().catchError((_) => debugPrint('Failed to delete $concatFilePath')),
    ]);

    return outputPath;
  }


  Future<String> _createPauseSegment(String imagePath, Duration duration, String outputPath) async {
    final cmd = '-y -loop 1 -i "$imagePath" '
        '-c:v mpeg4 -t ${duration.inSeconds} '  // Changed from libx264 to mpeg4
        '-pix_fmt yuv420p "$outputPath"';

    final result = await FFmpegKit.execute(cmd);
    if (!ReturnCode.isSuccess(await result.getReturnCode())) {
      throw Exception('Failed to create pause segment');
    }
    return outputPath;
  }
  Future<void> _saveToDownloads(String filePath) async {
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final destPath = '${downloadsDir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await File(filePath).copy(destPath);
  }

  // Drawing utility methods
  void undo() {
    if (state.lines.isEmpty) return;
    final lastLine = state.lines.last;
    emit(state.copyWith(
      lines: List.from(state.lines)..removeLast(),
      redoLines: List.from(state.redoLines)..add(lastLine),
    ));
  }

  void redo() {
    if (state.redoLines.isEmpty) return;
    final lastRedo = state.redoLines.last;
    emit(state.copyWith(
      lines: List.from(state.lines)..add(lastRedo),
      redoLines: List.from(state.redoLines)..removeLast(),
    ));
  }

  void clearDrawings() {
    emit(state.copyWith(
      lines: [],
      redoLines: [],
      selectedDrawingIndex: null,
    ));
  }

  void selectDrawing(Offset position) {
    for (int i = state.lines.length - 1; i >= 0; i--) {
      final drawing = state.lines[i];
      if (_isPointInDrawing(drawing, position)) {
        emit(state.copyWith(selectedDrawingIndex: i));
        return;
      }
    }
    emit(state.copyWith(selectedDrawingIndex: null));
  }

  bool _isPointInDrawing(Map<String, dynamic> drawing, Offset point) {
    switch (drawing['type']) {
      case 'free':
        final points = drawing['points'] as List<Offset>;
        for (final p in points) {
          if ((p - point).distance < 20) return true;
        }
        return false;
      case 'circle':
        final center = drawing['center'] as Offset;
        final radius = drawing['radius'] as double;
        return (point - center).distance <= radius;
      case 'player':
        final pos = drawing['position'] as Offset;
        return (point - pos).distance < 30;
      case 'arrow':
        final start = drawing['start'] as Offset;
        final end = drawing['end'] as Offset;
        return _pointNearLine(point, start, end);
      default:
        return false;
    }
  }

  bool _pointNearLine(Offset point, Offset start, Offset end) {
    final lineLength = (end - start).distance;
    if (lineLength == 0) return (point - start).distance < 10;

    final t = ((point.dx - start.dx) * (end.dx - start.dx) +
        (point.dy - start.dy) * (end.dy - start.dy)) /
        (lineLength * lineLength);
    final tClamped = t.clamp(0.0, 1.0);
    final projection = Offset(
      start.dx + tClamped * (end.dx - start.dx),
      start.dy + tClamped * (end.dy - start.dy),
    );
    return (point - projection).distance < 15;
  }

  void toggleTimeline() {
    emit(state.copyWith(showTimeline: !state.showTimeline));
  }

  void moveSelectedDrawing(Offset newPosition) {
    if (state.selectedDrawingIndex == null) return;

    final updatedLines = List<Map<String, dynamic>>.from(state.lines);
    final drawing = updatedLines[state.selectedDrawingIndex!];

    switch (drawing['type']) {
      case 'player':
        updatedLines[state.selectedDrawingIndex!] = {
          ...drawing,
          'position': newPosition,
        };
        break;
      case 'arrow':
        final offset = newPosition - (drawing['position'] as Offset);
        updatedLines[state.selectedDrawingIndex!] = {
          ...drawing,
          'start': (drawing['start'] as Offset) + offset,
          'end': (drawing['end'] as Offset) + offset,
        };
        break;
      case 'circle':
        updatedLines[state.selectedDrawingIndex!] = {
          ...drawing,
          'center': newPosition,
        };
        break;
      case 'free':
        final points = List<Offset>.from(drawing['points']);
        for (int i = 0; i < points.length; i++) {
          points[i] = points[i] + (newPosition - (drawing['position'] as Offset));
        }
        updatedLines[state.selectedDrawingIndex!] = {
          ...drawing,
          'points': points,
          'position': newPosition,
        };
        break;
    }

    emit(state.copyWith(lines: updatedLines));
  }

  void deselectDrawing() {
    emit(state.copyWith(selectedDrawingIndex: null));
  }

  void seekBackward() {
    if (state.controller == null) return;
    final newPosition = max(
      0,
      state.controller!.value.position.inMilliseconds - 10000,
    );
    state.controller!.seekTo(Duration(milliseconds: newPosition));
  }

  void seekForward() {
    if (state.controller == null) return;
    final newPosition = min(
      state.controller!.value.duration.inMilliseconds,
      state.controller!.value.position.inMilliseconds + 10000,
    );
    state.controller!.seekTo(Duration(milliseconds: newPosition));
  }

  void stopDrawing() {
    emit(state.copyWith(
      isDrawing: false,
      drawingMode: DrawingMode.none,
      points: [],
    ));
  }

  void changeDrawingColor(Color color) {
    emit(state.copyWith(drawingColor: color));
  }

  List<Map<String, dynamic>> getDrawingsForCurrentFrame() {
    if (state.controller == null) return [];
    final currentTime = state.controller!.value.position.inMilliseconds;
    return state.lines.where((line) {
      return (line['timestamp'] as int) == currentTime;
    }).toList();
  }

  // Cleanup
  void resetState() {
    state.controller?.dispose();
    emit(VideoEditingState());
  }
}

class PauseSegment {
  final Duration position;
  final Duration duration;
  PauseSegment({required this.position, required this.duration});
}