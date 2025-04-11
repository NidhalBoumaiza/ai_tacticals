import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

import 'image_loading_state.dart';


class ImageLoadingCubit extends Cubit<ImageLoadingState> {
  final int maxConcurrentLoads = 5;
  final Set<String> _imageQueue = {};
  final Set<String> _currentUrls = {};
  final Set<String> _loadedUrls = {};

  ImageLoadingCubit() : super(ImageLoadingInitial()) {
    _processQueue();
  }

  void addImageToQueue(String url) {
    if (!_loadedUrls.contains(url) && !_imageQueue.contains(url) && !_currentUrls.contains(url)) {
      _imageQueue.add(url);
      if (kDebugMode) {
        print('Queuing image: $url (Queue: ${_imageQueue.length}, Loading: ${_currentUrls.length})');
      }
      _processQueue();
    }
  }

  void markImageAsLoaded(String url) {
    _currentUrls.remove(url);
    _loadedUrls.add(url);
    if (kDebugMode) {
      print('Marked $url as loaded. Current: ${_currentUrls.length}, Queue: ${_imageQueue.length}');
    }
    _processQueue();
  }

  void _processQueue() async {
    while (_imageQueue.isNotEmpty && _currentUrls.length < maxConcurrentLoads) {
      final url = _imageQueue.first;
      _imageQueue.remove(url);
      _currentUrls.add(url);
      if (kDebugMode) {
        print('Processing image: $url (Current: ${_currentUrls.length})');
      }
      emit(ImageLoadingInProgress(Set.from(_currentUrls)));
      // Wait a small delay to allow the widget to pick up the state change
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (_currentUrls.isEmpty && _imageQueue.isEmpty) {
      emit(ImageLoadingIdle());
    }
  }

  @override
  Future<void> close() {
    _imageQueue.clear();
    _currentUrls.clear();
    _loadedUrls.clear();
    return super.close();
  }
}

