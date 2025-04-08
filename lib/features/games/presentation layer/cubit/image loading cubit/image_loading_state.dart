abstract class ImageLoadingState {}

class ImageLoadingInitial extends ImageLoadingState {}

class ImageLoadingIdle extends ImageLoadingState {}

class ImageLoadingInProgress extends ImageLoadingState {
  final List<String> currentUrls;

  ImageLoadingInProgress(this.currentUrls);
}