import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoEditingState {
  final VideoPlayerController? controller;
  final bool isPickerActive;
  final bool isPlaying;
  final bool showTimeline;
  final String? originalVideoPath;
  final bool isRecording;
  final Duration? recordingStartTime;
  final Duration? recordingEndTime;
  final List<Map<String, dynamic>> playbackEvents;
  final List<PauseSegment> pauseSegments;
  final Duration? pauseStartTime;
  final List<Map<String, dynamic>> lines;

  VideoEditingState({
    this.controller,
    this.isPickerActive = false,
    this.isPlaying = false,
    this.showTimeline = false,
    this.originalVideoPath,
    this.isRecording = false,
    this.recordingStartTime,
    this.recordingEndTime,
    this.playbackEvents = const [],
    this.pauseSegments = const [],
    this.pauseStartTime,
    this.lines = const [],
  });

  VideoEditingState copyWith({
    VideoPlayerController? controller,
    bool? isPickerActive,
    bool? isPlaying,
    bool? showTimeline,
    String? originalVideoPath,
    bool? isRecording,
    Duration? recordingStartTime,
    Duration? recordingEndTime,
    List<Map<String, dynamic>>? playbackEvents,
    List<PauseSegment>? pauseSegments,
    Duration? pauseStartTime,
    List<Map<String, dynamic>>? lines,
  }) {
    return VideoEditingState(
      controller: controller ?? this.controller,
      isPickerActive: isPickerActive ?? this.isPickerActive,
      isPlaying: isPlaying ?? this.isPlaying,
      showTimeline: showTimeline ?? this.showTimeline,
      originalVideoPath: originalVideoPath ?? this.originalVideoPath,
      isRecording: isRecording ?? this.isRecording,
      recordingStartTime: recordingStartTime ?? this.recordingStartTime,
      recordingEndTime: recordingEndTime ?? this.recordingEndTime,
      playbackEvents: playbackEvents ?? this.playbackEvents,
      pauseSegments: pauseSegments ?? this.pauseSegments,
      pauseStartTime: pauseStartTime ?? this.pauseStartTime,
      lines: lines ?? this.lines,
    );
  }
}

class PauseSegment {
  final Duration position;
  final Duration duration;
  PauseSegment({required this.position, required this.duration});
}