part of 'matches_bloc.dart';

abstract class MatchesState extends Equatable {
  const MatchesState();

  @override
  List<Object> get props => [];
}

class MatchesInitial extends MatchesState {}

class MatchesLoading extends MatchesState {}

class MatchesLoaded extends MatchesState {
  final MatchEventsPerTeamEntity matches;

  const MatchesLoaded({required this.matches});

  @override
  List<Object> get props => [matches];
}

class MatchesError extends MatchesState {
  final String message;

  const MatchesError({required this.message});

  @override
  List<Object> get props => [message];
}
