import 'package:analysis_ai/features/auth/domain%20layer/entities/userEntity.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/user_repository.dart';

class LoginUseCase {
  final UserRepository userRepository;

  LoginUseCase(this.userRepository);

  Future<Either<Failure, UserEntity>> call(
    String email,
    String password,
  ) async {
    return await userRepository.login(email, password);
  }
}
