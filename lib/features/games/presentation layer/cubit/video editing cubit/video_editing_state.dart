import 'dart:ui';

import 'package:analysis_ai/features/games/presentation%20layer/cubit/video%20editing%20cubit/video_editing_cubit.dart';
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
  final Duration? recordingStartTime; // Changed to Duration?
  final Duration? recordingEndTime; // Changed to Duration?
  final List<Map<String, dynamic>> playbackEvents;
  final DrawingMode drawingMode;
  final int? selectedDrawingIndex;
  final Color drawingColor;
  final bool showSnackbar;
  final String? snackbarMessage;
  final List<PauseSegment> pauseSegments;
  final Duration? pauseStartTime; // Changed to Duration?

  VideoEditingState({
    this.showSnackbar = false,
    this.snackbarMessage,
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
    this.drawingColor = Colors.green,
    this.pauseSegments = const [],
    this.pauseStartTime,
  });

  VideoEditingState copyWith({
    bool? showSnackbar,
    String? snackbarMessage,
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
    Duration? recordingStartTime,
    Duration? recordingEndTime,
    List<Map<String, dynamic>>? playbackEvents,
    DrawingMode? drawingMode,
    int? selectedDrawingIndex,
    Color? drawingColor,
    List<PauseSegment>? pauseSegments,
    Duration? pauseStartTime,
  }) {
    return VideoEditingState(
      showSnackbar: showSnackbar ?? this.showSnackbar,
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
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
      pauseSegments: pauseSegments ?? this.pauseSegments,
      pauseStartTime: pauseStartTime ?? this.pauseStartTime,
    );
  }
}