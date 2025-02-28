part of 'signup_bloc.dart';

@immutable
sealed class SignupState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class SignupInitial extends SignupState {}

final class SignupLoading extends SignupState {}

final class SignupSuccess extends SignupState {}

final class SignupError extends SignupState {
  final String message;

  SignupError({required this.message});

  @override
  List<Object?> get props => [message];
}
