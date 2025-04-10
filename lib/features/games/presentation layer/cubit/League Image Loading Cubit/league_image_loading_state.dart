abstract class LeagueImageLoadingState {}

class LeagueImageLoadingInitial extends LeagueImageLoadingState {}

class LeagueImageLoadingIdle extends LeagueImageLoadingState {}

class LeagueImageLoadingInProgress extends LeagueImageLoadingState {
  final List<String> currentUrls;

  LeagueImageLoadingInProgress(this.currentUrls);
}