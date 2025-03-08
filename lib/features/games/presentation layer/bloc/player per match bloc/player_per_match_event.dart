part of 'player_per_match_bloc.dart';

@immutable
sealed class PlayerPerMatchEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class GetPlayersPerMatch extends PlayerPerMatchEvent {
  final int matchId;

  GetPlayersPerMatch({required this.matchId});

  @override
  List<Object> get props => [matchId];
}
