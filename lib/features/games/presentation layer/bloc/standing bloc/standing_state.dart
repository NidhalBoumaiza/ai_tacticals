// lib/features/standings/presentation_layer/bloc/standings_state.dart
part of 'standing_bloc.dart';

sealed class StandingsState extends Equatable {
  const StandingsState();

  @override
  List<Object> get props => [];
}

final class StandingsInitial extends StandingsState {}

final class StandingsLoading extends StandingsState {}

final class StandingsSuccess extends StandingsState {
  final StandingsEntity standings;

  const StandingsSuccess({required this.standings});

  @override
  List<Object> get props => [standings];
}

final class StandingsError extends StandingsState {
  final String message;

  const StandingsError({required this.message});

  @override
  List<Object> get props => [message];
}
