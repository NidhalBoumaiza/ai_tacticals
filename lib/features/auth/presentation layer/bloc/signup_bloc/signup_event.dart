part of 'signup_bloc.dart';

@immutable
sealed class SignupEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SignupEventWithAllInfos extends SignupEvent {
  final UserEntity user;

  SignupEventWithAllInfos({required this.user});

  @override
  List<Object> get props => [user];
}
