// stats_repository_impl.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/entities/statics_entity.dart';
import '../../domain layer/repositories/statics_repository.dart';
import '../data sources/statics/statics_local_data_source.dart';
import '../data sources/statics/statics_remote_data_source.dart';

class StatsRepositoryImpl implements StaticsRepository {
  final StatsRemoteDataSource remoteDataSource;
  final StatsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  StatsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, StatsEntity>> getTeamStats(
    int teamId,
    int tournamentId,
    int seasonId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteStats = await remoteDataSource.getTeamStats(
          teamId,
          tournamentId,
          seasonId,
        );
        await localDataSource.cacheStats(
          remoteStats,
          teamId,
          tournamentId,
          seasonId,
        );
        return Right(remoteStats.toEntity());
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localStats = await localDataSource.getLastStats(
          teamId,
          tournamentId,
          seasonId,
        );
        return Right(localStats);
      } on EmptyCacheException {
        return Left(OfflineFailure());
      } on EmptyCacheException {
        return Left(EmptyCacheFailure());
      }
    }
  }
}
