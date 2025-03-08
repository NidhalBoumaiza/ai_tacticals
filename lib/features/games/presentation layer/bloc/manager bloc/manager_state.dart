part of 'manager_bloc.dart';

@immutable
sealed class ManagerState extends Equatable {
  @override
  List<Object> get props => [];
}

final class ManagerInitial extends ManagerState {}

final class ManagerLoading extends ManagerState {}

final class ManagerSuccess extends ManagerState {
  final Map<String, ManagerEntity> managers;

  ManagerSuccess({required this.managers});

  @override
  List<Object> get props => [managers];
}

final class ManagerError extends ManagerState {
  final String message;

  ManagerError({required this.message});

  @override
  List<Object> get props => [message];
}
