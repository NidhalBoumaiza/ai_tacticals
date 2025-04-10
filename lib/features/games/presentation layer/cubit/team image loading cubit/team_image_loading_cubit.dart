import 'package:flutter_bloc/flutter_bloc.dart';
import 'team_image_loading_state.dart';

class TeamImageLoadingCubit extends Cubit<TeamImageLoadingState> {
  final List<String> _imageQueue = [];
  final Set<String> _currentLoadingUrls = {};
  static const int _maxConcurrentLoads = 5;

  TeamImageLoadingCubit() : super(TeamImageLoadingInitial());

  void addImageToQueue(String url) {
    if (!_imageQueue.contains(url) && !_currentLoadingUrls.contains(url)) {
      print('Team queuing image: $url');
      _imageQueue.add(url);
      _tryLoadNextImage();
      // Force emit to ensure all queued images are processed
      emit(TeamImageLoadingInProgress(_currentLoadingUrls.toList()));
    } else {
      print('Image already queued or loading: $url');
    }
  }

  void markImageAsLoaded(String url) {
    print('Team image loaded: $url');
    if (_currentLoadingUrls.remove(url)) {
      _tryLoadNextImage();
    } else {
      print('Image not found in current loading URLs: $url');
    }
  }

  void _tryLoadNextImage() {
    while (_currentLoadingUrls.length < _maxConcurrentLoads && _imageQueue.isNotEmpty) {
      final nextUrl = _imageQueue.removeAt(0);
      _currentLoadingUrls.add(nextUrl);
      print('Team processing next image: $nextUrl');
      emit(TeamImageLoadingInProgress(_currentLoadingUrls.toList()));
    }
    if (_currentLoadingUrls.isEmpty && _imageQueue.isEmpty) {
      print('All images processed, switching to idle state');
      emit(TeamImageLoadingIdle());
    }
  }

  bool isLoading(String url) => _currentLoadingUrls.contains(url);
}