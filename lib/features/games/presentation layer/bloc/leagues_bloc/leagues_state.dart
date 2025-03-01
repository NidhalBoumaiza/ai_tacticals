part of 'leagues_bloc.dart';

@immutable
sealed class LeaguesState extends Equatable {
  @override
  List<Object> get props => [];
}

final class LeaguesInitial extends LeaguesState {}

final class LeaguesLoading extends LeaguesState {}

final class LeaguesSuccess extends LeaguesState {
  final List<LeagueEntity> leagues;

  LeaguesSuccess({required this.leagues});

  @override
  List<Object> get props => [leagues];
}

final class LeaguesError extends LeaguesState {
  final String message;

  LeaguesError({required this.message});

  @override
  List<Object> get props => [message];
}
