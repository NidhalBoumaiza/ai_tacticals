part of 'player_match_stats_bloc.dart';

abstract class PlayerMatchStatsState extends Equatable {
  const PlayerMatchStatsState();

  @override
  List<Object> get props => [];
}

class PlayerMatchStatsInitial extends PlayerMatchStatsState {}

class PlayerMatchStatsLoading extends PlayerMatchStatsState {}

class PlayerMatchStatsLoaded extends PlayerMatchStatsState {
  final PlayerEntityy playerStats;

  const PlayerMatchStatsLoaded({required this.playerStats});

  @override
  List<Object> get props => [playerStats];
}

class PlayerMatchStatsError extends PlayerMatchStatsState {
  final String message;

  const PlayerMatchStatsError({required this.message});

  @override
  List<Object> get props => [message];
}
