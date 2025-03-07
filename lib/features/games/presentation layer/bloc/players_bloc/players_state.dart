// players_state.dart
part of 'players_bloc.dart';

sealed class PlayersState extends Equatable {
  const PlayersState();
}

class PlayersInitial extends PlayersState {
  @override
  List<Object> get props => [];
}

class PlayersLoading extends PlayersState {
  @override
  List<Object> get props => [];
}

class PlayersLoaded extends PlayersState {
  final List<PlayerEntityy> players;

  const PlayersLoaded({required this.players});

  @override
  List<Object> get props => [players];
}

class PlayersError extends PlayersState {
  final String message;

  const PlayersError(this.message);

  @override
  List<Object> get props => [message];
}
