part of 'manager_bloc.dart';

@immutable
sealed class ManagerEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class GetManagers extends ManagerEvent {
  final int matchId;

  GetManagers({required this.matchId});

  @override
  List<Object> get props => [matchId];
}
