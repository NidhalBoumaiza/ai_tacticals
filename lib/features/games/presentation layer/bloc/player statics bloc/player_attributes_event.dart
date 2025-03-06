// features/players/presentation/bloc/player_attributes/player_attributes_bloc.dart
part of 'player_attributes_bloc.dart';

abstract class PlayerAttributesEvent {}

class FetchPlayerAttributes extends PlayerAttributesEvent {
  final int playerId;

  FetchPlayerAttributes(this.playerId);
}
