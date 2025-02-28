import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  late final String id;
  late String name;
  late String email;
  late String password;
  late String passwordConfirm;

  UserEntity(
    this.id,
    this.name,
    this.email,
    this.password,
    this.passwordConfirm,
  );

  UserEntity.create({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  }) {
    id = '';
  }

  @override
  List<Object?> get props => [id, name, email, password, passwordConfirm];
}
