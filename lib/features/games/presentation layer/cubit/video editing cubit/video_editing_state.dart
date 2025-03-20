import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

enum DrawingMode { none, free, circle, player, arrow }

class VideoEditingState {
  final VideoPlayerController? controller;
  final bool isPickerActive;
  final bool isPlaying;
  final bool showTimeline;
  final bool isDrawing;
  final List<Offset> points;
  final List<Map<String, dynamic>> lines;
  final List<Map<String, dynamic>> redoLines;
  final String? originalVideoPath;
  final bool isRecording;
  final int? recordingStartTime;
  final int? recordingEndTime;
  final List<Map<String, dynamic>> playbackEvents;
  final DrawingMode drawingMode;
  final int? selectedDrawingIndex;
  final Color drawingColor;

  VideoEditingState({
    this.controller,
    this.isPickerActive = false,
    this.isPlaying = false,
    this.showTimeline = false,
    this.isDrawing = false,
    this.points = const [],
    this.lines = const [],
    this.redoLines = const [],
    this.originalVideoPath,
    this.isRecording = false,
    this.recordingStartTime,
    this.recordingEndTime,
    this.playbackEvents = const [],
    this.drawingMode = DrawingMode.none,
    this.selectedDrawingIndex,
    this.drawingColor = Colors.green, // Default color
  });

  VideoEditingState copyWith({
    VideoPlayerController? controller,
    bool? isPickerActive,
    bool? isPlaying,
    bool? showTimeline,
    bool? isDrawing,

    List<Offset>? points,
    List<Map<String, dynamic>>? lines,
    List<Map<String, dynamic>>? redoLines,
    String? originalVideoPath,
    bool? isRecording,
    int? recordingStartTime,
    int? recordingEndTime,
    List<Map<String, dynamic>>? playbackEvents,
    DrawingMode? drawingMode,
    int? selectedDrawingIndex,
    Color? drawingColor,
  }) {
    return VideoEditingState(
      controller: controller ?? this.controller,
      isPickerActive: isPickerActive ?? this.isPickerActive,
      isPlaying: isPlaying ?? this.isPlaying,
      showTimeline: showTimeline ?? this.showTimeline,
      isDrawing: isDrawing ?? this.isDrawing,
      points: points ?? this.points,
      lines: lines ?? this.lines,
      redoLines: redoLines ?? this.redoLines,
      originalVideoPath: originalVideoPath ?? this.originalVideoPath,
      isRecording: isRecording ?? this.isRecording,
      recordingStartTime: recordingStartTime ?? this.recordingStartTime,
      recordingEndTime: recordingEndTime ?? this.recordingEndTime,
      playbackEvents: playbackEvents ?? this.playbackEvents,
      drawingMode: drawingMode ?? this.drawingMode,
      selectedDrawingIndex: selectedDrawingIndex ?? this.selectedDrawingIndex,
      drawingColor: drawingColor ?? this.drawingColor,
    );
  }

  // Optional: Add a toString method for easier debugging
  @override
  String toString() {
    return 'VideoEditingState(isPlaying: $isPlaying, isDrawing: $isDrawing, drawingMode: $drawingMode, lines: ${lines.length}, points: ${points.length}, redoLines: ${redoLines.length}, isRecording: $isRecording, selectedDrawingIndex: $selectedDrawingIndex)';
  }
}
