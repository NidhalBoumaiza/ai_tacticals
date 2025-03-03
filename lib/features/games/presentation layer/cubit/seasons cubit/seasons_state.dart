part of 'seasons_cubit.dart';

@immutable
sealed class SeasonsState extends Equatable {
  @override
  List<Object> get props => [];
}

final class SeasonsInitial extends SeasonsState {}

final class SeasonsLoading extends SeasonsState {}

final class SeasonsLoaded extends SeasonsState {
  final List<SeasonEntity> seasons;

  SeasonsLoaded(this.seasons);

  @override
  List<Object> get props => [seasons];
}

final class SeasonsError extends SeasonsState {
  final String message;

  SeasonsError(this.message);

  @override
  List<Object> get props => [message];
}
