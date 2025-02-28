import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/userEntity.dart';

abstract class UserRepository {
  Future<Either<Failure, Unit>> signUp(UserEntity user);

  Future<Either<Failure, UserEntity>> login(String email, String password);
}
