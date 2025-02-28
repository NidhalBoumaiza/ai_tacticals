import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/entities/userEntity.dart';
import '../../domain layer/repositories/user_repository.dart';
import '../data sources/user_local_data_source.dart';
import '../data sources/user_remote_data_source.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource userRemoteDataSource;
  final UserLocalDataSource userLocalDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.userRemoteDataSource,
    required this.userLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Unit>> signUp(UserEntity user) async {
    final UserModel userModel = UserModel(
      user.id ?? "",
      user.name,
      user.email,
      user.password,
      user.passwordConfirm,
    );
    if (await networkInfo.isConnected) {
      try {
        await userRemoteDataSource.signUp(userModel);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } on OfflineException catch (e) {
        return Left(OfflineFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final UserModel userModel = await userRemoteDataSource.login(
          email,
          password,
        );
        await userLocalDataSource.cacheUser(userModel);
        final UserEntity userEntity = UserEntity(
          userModel.id,
          userModel.name,
          userModel.email,
          userModel.password,
          userModel.passwordConfirm,
        );
        return Right(userEntity);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } on UnauthorizedException catch (e) {
        return Left(UnauthorizedFailure());
      } on OfflineException catch (e) {
        return Left(OfflineFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}
