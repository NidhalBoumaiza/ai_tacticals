part of 'national_team_stats_bloc.dart';

abstract class NationalTeamStatsEvent {}

class FetchNationalTeamStats extends NationalTeamStatsEvent {
  final int playerId;

  FetchNationalTeamStats(this.playerId);
}
