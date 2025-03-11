part of 'home_matches_bloc.dart';

abstract class HomeMatchesState extends Equatable {
  const HomeMatchesState();

  @override
  List<Object> get props => [];
}

class HomeMatchesInitial extends HomeMatchesState {}

class HomeMatchesLoading extends HomeMatchesState {}

class HomeMatchesLoaded extends HomeMatchesState {
  final MatchEventsPerTeamEntity matches;

  const HomeMatchesLoaded({required this.matches});

  @override
  List<Object> get props => [matches];
}

class HomeMatchesError extends HomeMatchesState {
  final String message;

  const HomeMatchesError({required this.message});

  @override
  List<Object> get props => [message];
}
