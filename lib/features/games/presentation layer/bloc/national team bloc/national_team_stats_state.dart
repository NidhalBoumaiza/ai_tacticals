part of 'national_team_stats_bloc.dart';

abstract class NationalTeamStatsState {}

class NationalTeamStatsInitial extends NationalTeamStatsState {}

class NationalTeamStatsLoading extends NationalTeamStatsState {}

class NationalTeamStatsLoaded extends NationalTeamStatsState {
  final NationalTeamEntity stats;

  NationalTeamStatsLoaded({required this.stats});
}

class NationalTeamStatsError extends NationalTeamStatsState {
  final String message;

  NationalTeamStatsError({required this.message});
}
