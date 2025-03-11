// features/games/data layer/repositories/player_match_stats_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/entities/player_entity.dart';
import '../../domain layer/repositories/player_match_stats_repository.dart';
import '../data sources/player match stats/player_match_stats_local_data_source.dart';
import '../data sources/player match stats/player_match_stats_remote_data_source.dart';

class PlayerMatchStatsRepositoryImpl implements PlayerMatchStatsRepository {
  final PlayerMatchStatsRemoteDataSource remoteDataSource;
  final PlayerMatchStatsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PlayerMatchStatsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PlayerEntityy>> getPlayerMatchStats({
    required int matchId,
    required int playerId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Fetch from remote data source if online
        final remoteStats = await remoteDataSource.getPlayerMatchStats(
          matchId: matchId,
          playerId: playerId,
        );
        // Cache the data locally
        await localDataSource.cachePlayerMatchStats(
          matchId: matchId,
          playerId: playerId,
          playerStats: remoteStats,
        );
        // Convert the model to entity and return
        return Right(remoteStats.toEntity());
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException {
        return Left(ServerFailure());
      }
    } else {
      try {
        // Fetch from local data source if offline
        final localStats = await localDataSource.getCachedPlayerMatchStats(
          matchId: matchId,
          playerId: playerId,
        );
        return Right(localStats.toEntity());
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }
}
