part of 'home_matches_bloc.dart';

abstract class HomeMatchesEvent extends Equatable {
  const HomeMatchesEvent();

  @override
  List<Object?> get props => [];
}

class FetchHomeMatches extends HomeMatchesEvent {
  final String date;

  FetchHomeMatches({required this.date});

  @override
  List<Object?> get props => [date];
}
