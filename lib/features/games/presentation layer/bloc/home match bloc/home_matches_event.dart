part of 'home_matches_bloc.dart';

abstract class HomeMatchesEvent extends Equatable {
  const HomeMatchesEvent();

  @override
  List<Object?> get props => [];
}

class FetchHomeMatches extends HomeMatchesEvent {
  final String date;
  final bool isInitial;

  FetchHomeMatches({required this.date, this.isInitial = false});

  @override
  List<Object?> get props => [date, isInitial];
}

class FetchLiveMatchUpdates extends HomeMatchesEvent {
  final String date;

  FetchLiveMatchUpdates({required this.date});

  @override
  List<Object?> get props => [date];
}
