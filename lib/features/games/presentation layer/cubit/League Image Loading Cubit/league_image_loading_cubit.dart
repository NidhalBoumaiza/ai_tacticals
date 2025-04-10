import 'package:flutter_bloc/flutter_bloc.dart';

import 'league_image_loading_state.dart';

class LeagueImageLoadingCubit extends Cubit<LeagueImageLoadingState> {
  final List<String> _imageQueue = [];
  final Set<String> _currentLoadingUrls = {};
  static const int _maxConcurrentLoads = 10; // Higher limit for LeagueScreen

  LeagueImageLoadingCubit() : super(LeagueImageLoadingInitial());

  void addImageToQueue(String url) {
    if (!_imageQueue.contains(url) && !_currentLoadingUrls.contains(url)) {
      print('League queuing image: $url');
      _imageQueue.add(url);
      _tryLoadNextImage();
    }
  }

  void markImageAsLoaded(String url) {
    print('League image loaded: $url');
    if (_currentLoadingUrls.remove(url)) {
      _tryLoadNextImage();
    }
  }

  void _tryLoadNextImage() {
    while (_currentLoadingUrls.length < _maxConcurrentLoads && _imageQueue.isNotEmpty) {
      final nextUrl = _imageQueue.removeAt(0);
      _currentLoadingUrls.add(nextUrl);
      emit(LeagueImageLoadingInProgress(_currentLoadingUrls.toList()));
    }
    if (_currentLoadingUrls.isEmpty && _imageQueue.isEmpty) {
      emit(LeagueImageLoadingIdle());
    }
  }

  bool isLoading(String url) => _currentLoadingUrls.contains(url);
}