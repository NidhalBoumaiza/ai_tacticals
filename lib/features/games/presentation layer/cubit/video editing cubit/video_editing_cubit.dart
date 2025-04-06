import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../../core/utils/custom_snack_bar.dart';
import '../lineup drawing cubut/drawing__cubit.dart';
import '../lineup drawing cubut/drawing__state.dart';
import 'video_editing_state.dart';

class VideoEditingCubit extends Cubit<VideoEditingState> {
  final ImagePicker _picker = ImagePicker();
  static const MethodChannel _channel = MethodChannel('com.example.analysis_ai/recording');
  static const MethodChannel _gallerySaverChannel = MethodChannel('com.example.analysis_ai/gallery_saver'); // New channel for gallery saving
  int? _lastTimestamp;
  bool _isStopping = false;

  VideoEditingCubit() : super(VideoEditingState());

  void updateControllerState() {
    final controller = state.controller;
    if (controller != null && controller.value.isPlaying) {
      emit(state.copyWith(isPlaying: true));
    } else {
      emit(state.copyWith(isPlaying: false));
    }
    final currentTimestamp = controller?.value.position.inMilliseconds ?? 0;
    _lastTimestamp = currentTimestamp;
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
    final updatedLines = List<Map<String, dynamic>>.from(state.lines);
    updatedLines.add({'drawing': drawing, 'timestamp': timestamp});
    emit(state.copyWith(lines: updatedLines));
  }

  Future<void> startRecording(BuildContext context, Rect videoRect) async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;

    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      showErrorSnackBar(context, "Storage permission denied. Please grant permission in settings.");
      openAppSettings();
      return;
    }

    try {
      debugPrint('Starting recording with rect: $videoRect');
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
      emit(state.copyWith(isRecording: false));
    }
  }

  Future<void> stopRecording(BuildContext context) async {
    final controller = state.controller;
    if (controller == null || !state.isRecording || _isStopping) return;

    _isStopping = true;
    debugPrint('Stopping recording...');

    try {
      final String? outputPath = await _channel.invokeMethod('stopScreenRecording');
      debugPrint('Received outputPath: $outputPath');
      controller.pause();

      if (outputPath != null && File(outputPath).existsSync()) {
        bool? saved = await _saveVideoToGallery(outputPath, albumName: 'aiTacticals');
        if (saved == true) {
          showSuccessSnackBar(context, "Video saved to gallery in aiTacticals album");
        } else {
          throw Exception("Failed to save video to gallery");
        }
        await File(outputPath).delete();
        debugPrint('Temporary file deleted: $outputPath');
      } else {
        throw Exception("Recording output file not found: $outputPath");
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      showErrorSnackBar(context, "Failed to save recording: $e");
    } finally {
      _isStopping = false;
      resetState();
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _saveVideoToGallery(String path, {String? albumName}) async {
    if (path.isEmpty) {
      throw ArgumentError('Please provide valid file path.');
    }
    if (!await File(path).exists()) {
      throw ArgumentError('File does not exist at path: $path');
    }

    try {
      bool? result = await _gallerySaverChannel.invokeMethod(
        'saveVideo',
        <String, dynamic>{
          'path': path,
          'albumName': albumName ?? 'aiTacticals',
          'toDcim': false,
        },
      );
      debugPrint('Gallery save result: $result');
      return result;
    } catch (e) {
      debugPrint('Error saving video to gallery: $e');
      rethrow;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final bool isAndroid13OrHigher = await _isAndroid13OrHigher();
      if (isAndroid13OrHigher) {
        var videoStatus = await Permission.videos.request();
        var micStatus = await Permission.microphone.request();
        debugPrint('Android 13+: Videos: $videoStatus, Microphone: $micStatus');
        return videoStatus.isGranted && micStatus.isGranted;
      } else {
        var storageStatus = await Permission.storage.request();
        var micStatus = await Permission.microphone.request();
        debugPrint('Android < 13: Storage: $storageStatus, Microphone: $micStatus');
        return storageStatus.isGranted && micStatus.isGranted;
      }
    }
    return true;
  }

  Future<bool> _isAndroid13OrHigher() async {
    const platform = MethodChannel('com.example.analysis_ai/platform');
    try {
      final int sdkVersion = await platform.invokeMethod('getSdkVersion');
      return sdkVersion >= 33;
    } catch (e) {
      debugPrint('Error checking Android version: $e');
      return false;
    }
  }

  void resetState() {
    state.controller?.dispose();
    emit(VideoEditingState());
  }

  void seekBackward() {
    if (state.controller == null) return;
    final newPosition = (state.controller!.value.position.inMilliseconds - 10000)
        .clamp(0, state.controller!.value.duration.inMilliseconds);
    state.controller!.seekTo(Duration(milliseconds: newPosition));
  }

  void seekForward() {
    if (state.controller == null) return;
    final newPosition = (state.controller!.value.position.inMilliseconds + 10000)
        .clamp(0, state.controller!.value.duration.inMilliseconds);
    state.controller!.seekTo(Duration(milliseconds: newPosition));
  }

  void removeDrawingForTimestamp(DrawingItem drawing, int timestamp) {
    final updatedLines = List<Map<String, dynamic>>.from(state.lines)
      ..removeWhere((line) => line['timestamp'] == timestamp && line['drawing'] == drawing);
    emit(state.copyWith(lines: updatedLines));
  }
}