// lib/features/games/presentation/bloc/matches_per_round_bloc/matches_per_round_event.dart
part of 'matches_per_round_bloc.dart';

abstract class MatchesPerRoundEvent extends Equatable {
  const MatchesPerRoundEvent();

  @override
  List<Object> get props => [];
}

class FetchMatchesPerRound extends MatchesPerRoundEvent {
  final int leagueId;
  final int seasonId;
  final int round;
  final bool isRefresh;

  const FetchMatchesPerRound({
    required this.leagueId,
    required this.seasonId,
    required this.round,
    this.isRefresh = false,
  });

  @override
  List<Object> get props => [leagueId, seasonId, round, isRefresh];
}

class FetchCurrentAndNextRounds extends MatchesPerRoundEvent {
  final int leagueId;
  final int seasonId;

  const FetchCurrentAndNextRounds({
    required this.leagueId,
    required this.seasonId,
  });

  @override
  List<Object> get props => [leagueId, seasonId];
}
