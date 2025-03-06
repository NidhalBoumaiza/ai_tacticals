// players_event.dart
part of 'players_bloc.dart';

sealed class PlayersEvent extends Equatable {
  const PlayersEvent();
}

class GetAllPlayersEvent extends PlayersEvent {
  final int teamId;

  const GetAllPlayersEvent({required this.teamId});

  @override
  List<Object> get props => [teamId];
}
