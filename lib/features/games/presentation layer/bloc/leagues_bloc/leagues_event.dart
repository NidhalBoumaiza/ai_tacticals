part of 'leagues_bloc.dart';

@immutable
sealed class LeaguesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class GetLeaguesByCountry extends LeaguesEvent {
  final int countryId;

  GetLeaguesByCountry({required this.countryId});

  @override
  List<Object> get props => [countryId];
}
