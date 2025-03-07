// match_details_state.dart
part of 'match_details_bloc.dart';

sealed class MatchDetailsState extends Equatable {
  const MatchDetailsState();
}

class MatchDetailsInitial extends MatchDetailsState {
  @override
  List<Object> get props => [];
}

class MatchDetailsLoading extends MatchDetailsState {
  @override
  List<Object> get props => [];
}

class MatchDetailsLoaded extends MatchDetailsState {
  final MatchDetails matchDetails;

  const MatchDetailsLoaded({required this.matchDetails});

  @override
  List<Object> get props => [matchDetails];
}

class MatchDetailsError extends MatchDetailsState {
  final String message;

  const MatchDetailsError(this.message);

  @override
  List<Object> get props => [message];
}