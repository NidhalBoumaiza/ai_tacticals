// match_details_event.dart
part of 'match_details_bloc.dart';

sealed class MatchDetailsEvent extends Equatable {
  const MatchDetailsEvent();
}

class GetMatchDetailsEvent extends MatchDetailsEvent {
  final int matchId;

  const GetMatchDetailsEvent({required this.matchId});

  @override
  List<Object> get props => [matchId];
}