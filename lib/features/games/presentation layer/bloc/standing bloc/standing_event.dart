// lib/features/standings/presentation_layer/bloc/standings_event.dart
part of 'standing_bloc.dart';

sealed class StandingEvent extends Equatable {
  const StandingEvent();

  @override
  List<Object> get props => [];
}

class GetStanding extends StandingEvent {
  final int leagueId;
  final int seasonId;

  const GetStanding({required this.leagueId, required this.seasonId});

  @override
  List<Object> get props => [leagueId, seasonId];
}
