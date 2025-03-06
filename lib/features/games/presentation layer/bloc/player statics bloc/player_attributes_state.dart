// features/players/presentation/bloc/player_attributes/player_attributes_state.dart
part of 'player_attributes_bloc.dart';

abstract class PlayerAttributesState {}

class PlayerAttributesInitial extends PlayerAttributesState {}

class PlayerAttributesLoading extends PlayerAttributesState {}

class PlayerAttributesLoaded extends PlayerAttributesState {
  final PlayerAttributesEntity attributes;

  PlayerAttributesLoaded({required this.attributes});
}

class PlayerAttributesError extends PlayerAttributesState {
  final String message;

  PlayerAttributesError({required this.message});
}
