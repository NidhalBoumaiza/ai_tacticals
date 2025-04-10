abstract class TeamImageLoadingState {}

class TeamImageLoadingInitial extends TeamImageLoadingState {}

class TeamImageLoadingInProgress extends TeamImageLoadingState {
  final List<String> currentUrls;

  TeamImageLoadingInProgress(this.currentUrls);
}

class TeamImageLoadingIdle extends TeamImageLoadingState {}