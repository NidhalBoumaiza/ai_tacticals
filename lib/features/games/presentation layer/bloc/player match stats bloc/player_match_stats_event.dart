part of 'player_match_stats_bloc.dart';

abstract class PlayerMatchStatsEvent extends Equatable {
  const PlayerMatchStatsEvent();

  @override
  List<Object> get props => [];
}

class FetchPlayerMatchStats extends PlayerMatchStatsEvent {
  final int matchId;
  final int playerId;

  const FetchPlayerMatchStats(this.matchId, this.playerId);

  @override
  List<Object> get props => [matchId, playerId];
}
