import 'package:flutter_bloc/flutter_bloc.dart';

import 'image_loading_state.dart';

class ImageLoadingCubit extends Cubit<ImageLoadingState> {
  final List<String> _imageQueue = [];
  final Set<String> _currentLoadingUrls = {};
  static const int _maxConcurrentLoads = 4; // Load up to 2 images at a time

  ImageLoadingCubit() : super(ImageLoadingInitial());

  void addImageToQueue(String url) {
    if (!_imageQueue.contains(url) && !_currentLoadingUrls.contains(url)) {
      _imageQueue.add(url);
      _tryLoadNextImage();
    }
  }

  void markImageAsLoaded(String url) {
    if (_currentLoadingUrls.remove(url)) {
      _tryLoadNextImage();
    }
  }

  void _tryLoadNextImage() {
    while (_currentLoadingUrls.length < _maxConcurrentLoads && _imageQueue.isNotEmpty) {
      final nextUrl = _imageQueue.removeAt(0);
      _currentLoadingUrls.add(nextUrl);
      emit(ImageLoadingInProgress(_currentLoadingUrls.toList()));
    }
    if (_currentLoadingUrls.isEmpty && _imageQueue.isEmpty) {
      emit(ImageLoadingIdle());
    }
  }

  bool isLoading(String url) => _currentLoadingUrls.contains(url);
}