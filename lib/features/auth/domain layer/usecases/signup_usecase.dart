import 'package:analysis_ai/features/auth/domain%20layer/entities/userEntity.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/user_repository.dart';

class SignUpUseCase {
  final UserRepository userRepository;

  SignUpUseCase(this.userRepository);

  Future<Either<Failure, Unit>> call(UserEntity user) async {
    return await userRepository.signUp(user);
  }
}
