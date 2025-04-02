import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  static const MethodChannel _channel = MethodChannel('com.example.analysis_ai/recording');

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

  void togglePlayPause(BuildContext context, {GlobalKey? videoKey}) async {
    final controller = state.controller;
    if (controller == null) return;

    final currentTime = controller.value.position;

    if (controller.value.isPlaying) {
      controller.pause();
      String? imagePath;
      if (state.isRecording && videoKey != null) {
        imagePath = await _captureFrameWithDrawing(context, videoKey, currentTime.inMilliseconds);
      } else {
        imagePath = await _saveCurrentFrame(currentTime.inMilliseconds);
      }
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

  Future<String?> _captureFrameWithDrawing(BuildContext context, GlobalKey videoKey, int timestamp) async {
    try {
      final boundary = videoKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/annotated_frame_$timestamp.png');
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error capturing annotated frame: $e');
      return null;
    }
  }

  void addDrawing(DrawingItem drawing, int timestamp) {
    emit(state.copyWith(
      lines: List.from(state.lines)..add({'drawing': drawing, 'timestamp': timestamp}),
    ));
  }

  Future<void> startRecording(BuildContext context, Rect videoRect) async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await _channel.invokeMethod('startScreenRecording', {
        'left': videoRect.left.toInt(),
        'top': videoRect.top.toInt(),
        'width': videoRect.width.toInt(),
        'height': videoRect.height.toInt(),
      });
      emit(state.copyWith(
        isRecording: true,
        recordingStartTime: controller.value.position,
        playbackEvents: [],
        pauseSegments: [],
      ));
      controller.play();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      showErrorSnackBar(context, "Failed to start recording: $e");
    }
  }

  Future<void> stopRecording(BuildContext context) async {
    final controller = state.controller;
    if (controller == null || !state.isRecording) return;

    try {
      final String? outputPath = await _channel.invokeMethod('stopScreenRecording');
      controller.pause();
      emit(state.copyWith(
        isRecording: false,
        recordingEndTime: controller.value.position,
      ));
      if (outputPath != null) {
        await _saveToAiTacticals(outputPath, context);
        showSuccessSnackBar(context, "Video saved successfully!");
        debugPrint('Recording saved to: $outputPath');
      } else {
        showErrorSnackBar(context, "No output path returned from recording");
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      showErrorSnackBar(context, "Failed to stop recording: $e");
    } finally {
      resetState();
    }
  }
  Future<void> _saveToAiTacticals(String filePath, BuildContext context) async {
    try {
      final dir = Directory('/storage/emulated/0/aiTacticals');
      if (!await dir.exists()) await dir.create(recursive: true);
      final destPath = '${dir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await File(filePath).copy(destPath);
      debugPrint('Video saved to: $destPath');
    } catch (e) {
      debugPrint('Error saving to aiTacticals: $e');
      showErrorSnackBar(context, 'Failed to save video: $e');
    }
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