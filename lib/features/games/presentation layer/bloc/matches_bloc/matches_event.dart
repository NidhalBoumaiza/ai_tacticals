part of 'matches_bloc.dart';

abstract class MatchesEvent extends Equatable {
  const MatchesEvent();

  @override
  List<Object> get props => [];
}

class GetMatchesEvent extends MatchesEvent {
  final int uniqueTournamentId;
  final int seasonId;

  const GetMatchesEvent({
    required this.uniqueTournamentId,
    required this.seasonId,
  });

  @override
  List<Object> get props => [uniqueTournamentId, seasonId];
}
