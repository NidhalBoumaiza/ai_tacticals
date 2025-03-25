import 'dart:io';
import 'dart:math';

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

  void togglePlayPause(BuildContext context) async {
    final controller = state.controller;
    if (controller == null) return;

    final currentTime = controller.value.position;

    if (controller.value.isPlaying) {
      controller.pause();
      final imagePath = await _saveCurrentFrame(currentTime.inMilliseconds);
      if (imagePath != null) {
        emit(state.copyWith(
          pauseStartTime: currentTime,
          playbackEvents: List.from(state.playbackEvents)
            ..add({
              'action': 'pause',
              'timestamp': currentTime.inMilliseconds,
              'imagePath': imagePath,
            }),
        ));
      }
    } else {
      if (state.pauseStartTime != null) {
        final pauseDuration = currentTime - state.pauseStartTime!;
        emit(state.copyWith(
          pauseSegments: List.from(state.pauseSegments)
            ..add(PauseSegment(
              position: state.pauseStartTime!,
              duration: pauseDuration,
            )),
          playbackEvents: List.from(state.playbackEvents)
            ..add({
              'action': 'play',
              'timestamp': currentTime.inMilliseconds,
              'pauseDuration': pauseDuration.inMilliseconds,
            }),
          pauseStartTime: null,
        ));
      }
      controller.play();
    }
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
      debugPrint('Saved frame at: ${file.path}, size: ${await file.length()} bytes');
      return file.path;
    } catch (e) {
      debugPrint('Error saving frame: $e');
      return null;
    }
  }

  // Drawing methods (unchanged for brevity)
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
    emit(state.copyWith(points: List.from(state.points)..add(point)));
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

    final startTime = controller.value.position;

    emit(state.copyWith(
      isRecording: true,
      recordingStartTime: startTime,
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

    final endTime = controller.value.position;
    controller.pause();

    if (state.pauseStartTime != null) {
      final pauseDuration = endTime - state.pauseStartTime!;
      emit(state.copyWith(
        pauseSegments: List.from(state.pauseSegments)
          ..add(PauseSegment(
            position: state.pauseStartTime!,
            duration: pauseDuration,
          )),
        playbackEvents: List.from(state.playbackEvents)
          ..add({
            'action': 'play',
            'timestamp': endTime.inMilliseconds,
            'pauseDuration': pauseDuration.inMilliseconds,
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
      debugPrint('Starting video processing...');

      if (!await File(state.originalVideoPath!).exists()) {
        throw Exception('Original video file not found');
      }

      final baseVideo = await _extractBaseVideoSegment(tempDir.path);
      final finalVideo = await _applyEffectsAndSave(baseVideo, tempDir.path);

      await _saveToDownloads(finalVideo);
      showSuccessSnackBar(context, "Video saved successfully!");
    } catch (e) {
      debugPrint('Error processing video: $e');
      showErrorSnackBar(context, "Failed to save video: $e");
    } finally {
      resetState();
    }
  }

  Future<String> _extractBaseVideoSegment(String tempDir) async {
    final outputPath = '$tempDir/base_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final duration = (state.recordingEndTime! - state.recordingStartTime!).inSeconds.toDouble();
    final cmd = '-y -i "${state.originalVideoPath}" '
        '-ss ${state.recordingStartTime!.inSeconds} '
        '-t $duration '
        '-c:v copy ' // Use copy to avoid re-encoding
        '-c:a aac -b:a 128k '
        '"$outputPath"';

    debugPrint('Extraction command: $cmd');
    final result = await FFmpegKit.execute(cmd);
    final returnCode = await result.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await result.getAllLogsAsString();
      debugPrint('FFmpeg extraction error: $logs');
      throw Exception('Video extraction failed: $logs');
    }

    final outputFile = File(outputPath);
    if (!await outputFile.exists() || await outputFile.length() == 0) {
      throw Exception('Base video file is empty or not created');
    }
    debugPrint('Base video created: $outputPath, size: ${await outputFile.length()} bytes');
    return outputPath;
  }

  Future<String> _applyEffectsAndSave(String baseVideo, String tempDir) async {
    final outputPath = '$tempDir/final_${DateTime.now().millisecondsSinceEpoch}.mp4';
    debugPrint('Starting effects processing...');

    final recordingDuration = state.recordingEndTime! - state.recordingStartTime!;
    debugPrint('Total recording duration: ${recordingDuration.inSeconds} seconds');

    if (state.pauseSegments.isEmpty) {
      final cmd = '-y -i "$baseVideo" '
          '-c:v copy '
          '-c:a aac '
          '"$outputPath"';
      debugPrint('No pauses, copying video: $cmd');
      final result = await FFmpegKit.execute(cmd);
      if (!ReturnCode.isSuccess(await result.getReturnCode())) {
        throw Exception('Failed to process video: ${await result.getOutput()}');
      }
      return outputPath;
    }

    final sortedPauses = List<PauseSegment>.from(state.pauseSegments)
      ..sort((a, b) => a.position.compareTo(b.position));
    final videoSegments = <String>[];
    final pauseVideos = <String>[];
    Duration lastEnd = Duration.zero;

    debugPrint('Processing ${sortedPauses.length} pause segments');

    for (int i = 0; i < sortedPauses.length; i++) {
      final pause = sortedPauses[i];
      final segmentStart = pause.position - state.recordingStartTime!;
      final segmentDuration = segmentStart - lastEnd;

      if (segmentDuration.inMilliseconds > 0) {
        final segmentPath = '$tempDir/segment_$i.mp4';
        final cmd = '-y -i "$baseVideo" '
            '-ss ${lastEnd.inSeconds} '
            '-t ${segmentDuration.inSeconds} '
            '-c:v copy '
            '-c:a aac -b:a 128k '
            '"$segmentPath"';
        debugPrint('Creating segment $i: $cmd');
        final result = await FFmpegKit.execute(cmd);
        if (!ReturnCode.isSuccess(await result.getReturnCode())) {
          throw Exception('Failed to create segment $i: ${await result.getOutput()}');
        }

        final segmentFile = File(segmentPath);
        if (!await segmentFile.exists() || await segmentFile.length() == 0) {
          throw Exception('Segment $i is empty or not created');
        }
        debugPrint('Segment $i created, size: ${await segmentFile.length()} bytes');
        videoSegments.add(segmentPath);
      }

      final pauseEvent = state.playbackEvents.firstWhere(
            (e) => e['action'] == 'pause' && e['timestamp'] == pause.position.inMilliseconds,
        orElse: () => throw Exception('Pause event not found for ${pause.position.inMilliseconds}ms'),
      );

      final pausePath = '$tempDir/pause_${pause.position.inMilliseconds}.mp4';
      final pauseDuration = pause.duration.inSeconds > 0 ? pause.duration.inSeconds : 2;
      final pauseCmd = '-y -loop 1 -i "${pauseEvent['imagePath']}" '
          '-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 '
          '-c:v mpeg4 -b:v 1000k ' // Use mpeg4 instead of libx264
          '-c:a aac -b:a 128k '
          '-t $pauseDuration '
          '-vf "scale=640:360,setpts=PTS-STARTPTS" '
          '-r 25 "$pausePath"';
      debugPrint('Creating pause segment: $pauseCmd');
      final pauseResult = await FFmpegKit.execute(pauseCmd);
      if (!ReturnCode.isSuccess(await pauseResult.getReturnCode())) {
        throw Exception('Failed to create pause segment: ${await pauseResult.getOutput()}');
      }

      final pauseFile = File(pausePath);
      if (!await pauseFile.exists() || await pauseFile.length() == 0) {
        throw Exception('Pause segment is empty or not created');
      }
      debugPrint('Pause segment created, size: ${await pauseFile.length()} bytes');
      pauseVideos.add(pausePath);

      lastEnd = pause.position + pause.duration - state.recordingStartTime!;
    }

    final remainingDuration = recordingDuration - lastEnd;
    if (remainingDuration.inMilliseconds > 0) {
      final remainingPath = '$tempDir/segment_final.mp4';
      final cmd = '-y -i "$baseVideo" '
          '-ss ${lastEnd.inSeconds} '
          '-t ${remainingDuration.inSeconds} '
          '-c:v copy '
          '-c:a aac -b:a 128k '
          '"$remainingPath"';
      debugPrint('Creating final segment: $cmd');
      final result = await FFmpegKit.execute(cmd);
      if (!ReturnCode.isSuccess(await result.getReturnCode())) {
        throw Exception('Failed to create final segment: ${await result.getOutput()}');
      }

      final remainingFile = File(remainingPath);
      if (!await remainingFile.exists() || await remainingFile.length() == 0) {
        throw Exception('Final segment is empty or not created');
      }
      debugPrint('Final segment created, size: ${await remainingFile.length()} bytes');
      videoSegments.add(remainingPath);
    }

    final concatList = <String>[];
    for (int i = 0; i < videoSegments.length; i++) {
      concatList.add("file '${videoSegments[i]}'");
      if (i < pauseVideos.length) {
        concatList.add("file '${pauseVideos[i]}'");
      }
    }

    final concatFilePath = '$tempDir/concat.txt';
    await File(concatFilePath).writeAsString(concatList.join('\n'));
    debugPrint('Concatenation list:\n${concatList.join('\n')}');

    final concatCmd = '-y -f concat -safe 0 -i "$concatFilePath" '
        '-c:v mpeg4 -b:v 1000k ' // Re-encode to mpeg4 for compatibility
        '-c:a aac '
        '-movflags +faststart '
        '"$outputPath"';
    debugPrint('Concatenation command: $concatCmd');
    final concatResult = await FFmpegKit.execute(concatCmd);
    if (!ReturnCode.isSuccess(await concatResult.getReturnCode())) {
      throw Exception('Failed to concatenate segments: ${await concatResult.getOutput()}');
    }

    final outputFile = File(outputPath);
    if (!await outputFile.exists() || await outputFile.length() == 0) {
      throw Exception('Final video is empty or not created');
    }
    debugPrint('Final video created: $outputPath, size: ${await outputFile.length()} bytes');

    await Future.wait([
      ...pauseVideos.map((path) => File(path).delete()),
      ...videoSegments.map((path) => File(path).delete()),
      File(concatFilePath).delete(),
    ]);
    debugPrint('Temporary files cleaned up');

    return outputPath;
  }

  Future<void> _saveToDownloads(String filePath) async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final destPath = '${downloadsDir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await File(filePath).copy(destPath);
      debugPrint('Video saved to: $destPath');
    } catch (e) {
      debugPrint('Error saving to downloads: $e');
      rethrow;
    }
  }

  void resetState() {
    state.controller?.dispose();
    emit(VideoEditingState());
  }

  // Other methods (unchanged for brevity)
  void undo() => emit(state.copyWith(lines: [], redoLines: []));
  void redo() {}
  void clearDrawings() => emit(state.copyWith(lines: [], redoLines: [], selectedDrawingIndex: null));
  void selectDrawing(Offset position) {}
  bool _isPointInDrawing(Map<String, dynamic> drawing, Offset point) => false;
  bool _pointNearLine(Offset point, Offset start, Offset end) => false;
  void toggleTimeline() => emit(state.copyWith(showTimeline: !state.showTimeline));
  void moveSelectedDrawing(Offset newPosition) {}
  void deselectDrawing() => emit(state.copyWith(selectedDrawingIndex: null));
  void seekBackward() {
    if (state.controller == null) return;
    final newPosition = max(0, state.controller!.value.position.inMilliseconds - 10000);
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
  void stopDrawing() => emit(state.copyWith(isDrawing: false, drawingMode: DrawingMode.none, points: []));
  void changeDrawingColor(Color color) => emit(state.copyWith(drawingColor: color));
  List<Map<String, dynamic>> getDrawingsForCurrentFrame() => [];
}

class PauseSegment {
  final Duration position;
  final Duration duration;
  PauseSegment({required this.position, required this.duration});
}