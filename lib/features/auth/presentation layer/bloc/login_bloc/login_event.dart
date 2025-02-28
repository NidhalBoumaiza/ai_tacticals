part of 'login_bloc.dart';

@immutable
sealed class LoginEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginWithEmailAndPassword extends LoginEvent {
  final String email;
  final String password;

  LoginWithEmailAndPassword({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
