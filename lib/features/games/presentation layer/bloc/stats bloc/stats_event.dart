part of 'stats_bloc.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object> get props => [];
}

class GetStats extends StatsEvent {
  final int teamId;
  final int tournamentId;
  final int seasonId;

  const GetStats({
    required this.teamId,
    required this.tournamentId,
    required this.seasonId,
  });

  @override
  List<Object> get props => [teamId, tournamentId, seasonId];
}
