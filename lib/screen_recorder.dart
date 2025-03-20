import 'package:flutter/services.dart';

class ScreenRecorder {
  static const MethodChannel _channel = MethodChannel(
    'com.example.analysis_ai/screen_recorder',
  );

  static Future<void> startRecording(String outputPath) async {
    try {
      await _channel.invokeMethod('startRecording', {'outputPath': outputPath});
    } on PlatformException catch (e) {
      throw 'Failed to start recording: ${e.message}';
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final String? result = await _channel.invokeMethod('stopRecording');
      return result;
    } on PlatformException catch (e) {
      throw 'Failed to stop recording: ${e.message}';
    }
  }
}
