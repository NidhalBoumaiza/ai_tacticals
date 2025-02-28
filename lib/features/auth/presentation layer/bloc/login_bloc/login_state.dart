part of 'login_bloc.dart';

@immutable
sealed class LoginState extends Equatable {
  @override
  List<Object> get props => [];
}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final UserEntity user;

  LoginSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

final class LoginError extends LoginState {
  final String message;

  LoginError({required this.message});

  @override
  List<Object> get props => [message];
}
