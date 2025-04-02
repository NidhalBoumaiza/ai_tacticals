import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../../core/utils/custom_snack_bar.dart';
import '../lineup drawing cubut/drawing__cubit.dart';
import '../lineup drawing cubut/drawing__state.dart';
import 'video_editing_state.dart';

class VideoEditingCubit extends Cubit<VideoEditingState> {
  final ImagePicker _picker = ImagePicker();

  VideoEditingCubit() : super(VideoEditingState());

  void updateControllerState() {
    final controller = state.controller;
    if (controller != null && controller.value.isPlaying) {
      emit(state.copyWith(isPlaying: true));
    } else {
      emit(state.copyWith(isPlaying: false));
    }
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
            ..add({'action': 'pause', 'timestamp': currentTime.inMilliseconds, 'imagePath': imagePath}),
        ));
      }
    } else {
      if (state.pauseStartTime != null) {
        final pauseDuration = currentTime - state.pauseStartTime!;
        emit(state.copyWith(
          pauseSegments: List.from(state.pauseSegments)
            ..add(PauseSegment(position: state.pauseStartTime!, duration: pauseDuration)),
          playbackEvents: List.from(state.playbackEvents)
            ..add({'action': 'play', 'timestamp': currentTime.inMilliseconds, 'pauseDuration': pauseDuration.inMilliseconds}),
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
      return file.path;
    } catch (e) {
      debugPrint('Error saving frame: $e');
      return null;
    }
  }

  void addDrawing(DrawingItem drawing, int timestamp) {
    emit(state.copyWith(
      lines: List.from(state.lines)..add({'drawing': drawing, 'timestamp': timestamp}),
    ));
  }

  Future<void> startRecording() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;

    final startTime = controller.value.position;
    emit(state.copyWith(
      isRecording: true,
      recordingStartTime: startTime,
      playbackEvents: [],
      lines: [],
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
          ..add(PauseSegment(position: state.pauseStartTime!, duration: pauseDuration)),
        playbackEvents: List.from(state.playbackEvents)
          ..add({'action': 'play', 'timestamp': endTime.inMilliseconds, 'pauseDuration': pauseDuration.inMilliseconds}),
        pauseStartTime: null,
      ));
    }

    emit(state.copyWith(isRecording: false, recordingEndTime: endTime));
    await _processAndSaveRecording(context);
  }

  Future<void> _processAndSaveRecording(BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final baseVideo = await _extractBaseVideoSegment(tempDir.path);
      final finalVideo = await _applyEffectsAndSave(baseVideo, tempDir.path, context.read<DrawingCubit>().state.drawings);
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
        '-c:v copy '
        '-c:a aac -b:a 128k '
        '"$outputPath"';
    final result = await FFmpegKit.execute(cmd);
    if (!ReturnCode.isSuccess(await result.getReturnCode())) {
      throw Exception('Video extraction failed: ${await result.getOutput()}');
    }
    return outputPath;
  }

  Future<String> _applyEffectsAndSave(String baseVideo, String tempDir, List<DrawingItem> drawings) async {
    final outputPath = '$tempDir/final_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final recordingDuration = state.recordingEndTime! - state.recordingStartTime!;
    final sortedPauses = List<PauseSegment>.from(state.pauseSegments)..sort((a, b) => a.position.compareTo(b.position));
    final videoSegments = <String>[];
    final pauseVideos = <String>[];
    Duration lastEnd = Duration.zero;

    for (int i = 0; i <= sortedPauses.length; i++) {
      final segmentStart = i == 0 ? Duration.zero : sortedPauses[i - 1].position + sortedPauses[i - 1].duration - state.recordingStartTime!;
      final segmentEnd = i < sortedPauses.length ? sortedPauses[i].position - state.recordingStartTime! : recordingDuration;
      final segmentDuration = segmentEnd - segmentStart;

      if (segmentDuration.inMilliseconds > 0) {
        final segmentPath = '$tempDir/segment_$i.mp4';
        String overlayCmd = '-y -i "$baseVideo" '
            '-ss ${segmentStart.inSeconds} '
            '-t ${segmentDuration.inSeconds} '
            '-c:v mpeg4 -b:v 1000k '
            '-c:a aac -b:a 128k ';

        final segmentDrawings = state.lines.where((line) {
          final timestamp = line['timestamp'] as int;
          return timestamp >= segmentStart.inMilliseconds + state.recordingStartTime!.inMilliseconds &&
              timestamp < segmentEnd.inMilliseconds + state.recordingStartTime!.inMilliseconds;
        }).map((line) => line['drawing'] as DrawingItem).toList();

        for (var drawing in segmentDrawings) {
          final timeOffset = (drawing.points.first.dx - segmentStart.inMilliseconds) / 1000.0;
          switch (drawing.type) {
            case DrawingMode.free:
              overlayCmd += '-vf "drawtext=text=\'Free\':fontcolor=${drawing.color.value.toRadixString(16)}:fontsize=20:x=${drawing.points.first.dx}:y=${drawing.points.first.dy}:enable=\'gte(t,$timeOffset)\'" ';
              break;
            case DrawingMode.circle:
              overlayCmd += '-vf "drawcircle=x=${drawing.points.first.dx}:y=${drawing.points.first.dy}:r=${(drawing.points[1] - drawing.points[0]).distance / 2}:color=${drawing.color.value.toRadixString(16)}:enable=\'gte(t,$timeOffset)\'" ';
              break;
            case DrawingMode.player:
              overlayCmd += '-vf "drawtext=text=\'P\':fontcolor=${drawing.color.value.toRadixString(16)}:fontsize=20:x=${drawing.points.first.dx}:y=${drawing.points.first.dy}:enable=\'gte(t,$timeOffset)\'" ';
              break;
            case DrawingMode.arrow:
              overlayCmd += '-vf "drawarrow=from_x=${drawing.points[0].dx}:from_y=${drawing.points[0].dy}:to_x=${drawing.points[1].dx}:to_y=${drawing.points[1].dy}:color=${drawing.color.value.toRadixString(16)}:enable=\'gte(t,$timeOffset)\'" ';
              break;
            case DrawingMode.none:
              break;
          }
        }

        overlayCmd += '"$segmentPath"';
        final result = await FFmpegKit.execute(overlayCmd);
        if (!ReturnCode.isSuccess(await result.getReturnCode())) {
          throw Exception('Failed to create segment $i: ${await result.getOutput()}');
        }
        videoSegments.add(segmentPath);
      }

      if (i < sortedPauses.length) {
        final pause = sortedPauses[i];
        final pauseEvent = state.playbackEvents.firstWhere((e) => e['action'] == 'pause' && e['timestamp'] == pause.position.inMilliseconds);
        final pausePath = '$tempDir/pause_${pause.position.inMilliseconds}.mp4';
        final pauseDuration = pause.duration.inSeconds > 0 ? pause.duration.inSeconds : 2;
        final pauseCmd = '-y -loop 1 -i "${pauseEvent['imagePath']}" '
            '-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 '
            '-c:v mpeg4 -b:v 1000k '
            '-c:a aac -b:a 128k '
            '-t $pauseDuration '
            '-vf "scale=640:360,setpts=PTS-STARTPTS" '
            '-r 25 "$pausePath"';
        final pauseResult = await FFmpegKit.execute(pauseCmd);
        if (!ReturnCode.isSuccess(await pauseResult.getReturnCode())) {
          throw Exception('Failed to create pause segment: ${await pauseResult.getOutput()}');
        }
        pauseVideos.add(pausePath);
      }
    }

    final concatList = <String>[];
    for (int i = 0; i < videoSegments.length; i++) {
      concatList.add("file '${videoSegments[i]}'");
      if (i < pauseVideos.length) concatList.add("file '${pauseVideos[i]}'");
    }

    final concatFilePath = '$tempDir/concat.txt';
    await File(concatFilePath).writeAsString(concatList.join('\n'));
    final concatCmd = '-y -f concat -safe 0 -i "$concatFilePath" '
        '-c:v mpeg4 -b:v 1000k '
        '-c:a aac '
        '-movflags +faststart '
        '"$outputPath"';
    final concatResult = await FFmpegKit.execute(concatCmd);
    if (!ReturnCode.isSuccess(await concatResult.getReturnCode())) {
      throw Exception('Failed to concatenate segments: ${await concatResult.getOutput()}');
    }

    await Future.wait([
      ...pauseVideos.map((path) => File(path).delete()),
      ...videoSegments.map((path) => File(path).delete()),
      File(concatFilePath).delete(),
    ]);

    return outputPath;
  }

  Future<void> _saveToDownloads(String filePath) async {
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);
    final destPath = '${downloadsDir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await File(filePath).copy(destPath);
  }

  void resetState() {
    state.controller?.dispose();
    emit(VideoEditingState());
  }

  void seekBackward() {
    if (state.controller == null) return;
    final newPosition = (state.controller!.value.position.inMilliseconds - 10000).clamp(0, state.controller!.value.duration.inMilliseconds);
    state.controller!.seekTo(Duration(milliseconds: newPosition));
  }

  void seekForward() {
    if (state.controller == null) return;
    final newPosition = (state.controller!.value.position.inMilliseconds + 10000).clamp(0, state.controller!.value.duration.inMilliseconds);
    state.controller!.seekTo(Duration(milliseconds: newPosition));
  }
}