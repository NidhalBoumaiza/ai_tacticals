part of 'player_per_match_bloc.dart';

@immutable
sealed class PlayerPerMatchState extends Equatable {
  @override
  List<Object> get props => [];
}

final class PlayerPerMatchInitial extends PlayerPerMatchState {}

final class PlayerPerMatchLoading extends PlayerPerMatchState {}

final class PlayerPerMatchSuccess extends PlayerPerMatchState {
  final Map<String, List<PlayerPerMatchEntity>> players;

  PlayerPerMatchSuccess({required this.players});

  @override
  List<Object> get props => [players];
}

final class PlayerPerMatchError extends PlayerPerMatchState {
  final String message;

  PlayerPerMatchError({required this.message});

  @override
  List<Object> get props => [message];
}
