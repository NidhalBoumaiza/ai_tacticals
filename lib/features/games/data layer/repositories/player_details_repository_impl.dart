// features/players/data_layer/repositories/player_details_repository_impl.dart
import 'package:analysis_ai/core/error/exceptions.dart';
import 'package:analysis_ai/core/error/failures.dart';
import 'package:analysis_ai/core/network/network_info.dart';
import 'package:dartz/dartz.dart';

import '../../domain layer/entities/player_statics_entity.dart';
import '../../domain layer/repositories/player_details_repository.dart';
import '../data sources/player details/player_details_local_data_source.dart';
import '../data sources/player details/player_details_remote_data_source.dart';

class PlayerDetailsRepositoryImpl implements PlayerDetailsRepository {
  final PlayerDetailsRemoteDataSource remoteDataSource;
  final PlayerDetailsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PlayerDetailsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PlayerAttributesEntity>> getPlayerAttributes(
    int playerId,
  ) async {
    // First, try to get cached attributes
    try {
      final cachedAttributes = await localDataSource.getCachedPlayerAttributes(
        playerId,
      );
      return Right(cachedAttributes);
    } on EmptyCacheException {
      // If no cached data, fetch from remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteAttributes = await remoteDataSource.getPlayerAttributes(
            playerId,
          );
          final entity = remoteAttributes.toEntity();
          // Cache the fetched attributes
          await localDataSource.cachePlayerAttributes(entity, playerId);
          return Right(entity);
        } on ServerException {
          return Left(ServerFailure());
        } on ServerMessageException catch (e) {
          return Left(ServerMessageFailure(e.message));
        } on OfflineException {
          return Left(OfflineFailure());
        }
      } else {
        return Left(OfflineFailure());
      }
    }
  }

  @override
  Future<Either<Failure, NationalTeamEntity>> getNationalTeamStats(
    int playerId,
  ) async {
    // First, try to get cached national team stats
    try {
      final cachedStats = await localDataSource.getCachedNationalTeamStats(
        playerId,
      );
      return Right(cachedStats);
    } on EmptyCacheException {
      // If no cached data, fetch from remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteStats = await remoteDataSource.getNationalTeamStats(
            playerId,
          );
          final entity = remoteStats.toEntity();
          // Cache the fetched stats
          await localDataSource.cacheNationalTeamStats(entity, playerId);
          return Right(entity);
        } on ServerException {
          return Left(ServerFailure());
        } on ServerMessageException catch (e) {
          return Left(ServerMessageFailure(e.message));
        } on OfflineException {
          return Left(OfflineFailure());
        }
      } else {
        return Left(OfflineFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<MatchPerformanceEntity>>> getLastYearSummary(
    int playerId,
  ) async {
    // First, try to get cached summary
    try {
      final cachedSummary = await localDataSource.getCachedLastYearSummary(
        playerId,
      );
      return Right(cachedSummary);
    } on EmptyCacheException {
      // If no cached data, fetch from remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteSummary = await remoteDataSource.getLastYearSummary(
            playerId,
          );
          final entities =
              remoteSummary.map((model) => model.toEntity()).toList();
          // Cache the fetched summary
          await localDataSource.cacheLastYearSummary(entities, playerId);
          return Right(entities);
        } on ServerException {
          return Left(ServerFailure());
        } on ServerMessageException catch (e) {
          return Left(ServerMessageFailure(e.message));
        } on OfflineException {
          return Left(OfflineFailure());
        }
      } else {
        return Left(OfflineFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<TransferEntity>>> getTransferHistory(
    int playerId,
  ) async {
    // First, try to get cached transfer history
    try {
      final cachedTransfers = await localDataSource.getCachedTransferHistory(
        playerId,
      );
      return Right(cachedTransfers);
    } on EmptyCacheException {
      // If no cached data, fetch from remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteTransfers = await remoteDataSource.getTransferHistory(
            playerId,
          );
          final entities =
              remoteTransfers.map((model) => model.toEntity()).toList();
          // Cache the fetched transfers
          await localDataSource.cacheTransferHistory(entities, playerId);
          return Right(entities);
        } on ServerException {
          return Left(ServerFailure());
        } on ServerMessageException catch (e) {
          return Left(ServerMessageFailure(e.message));
        } on OfflineException {
          return Left(OfflineFailure());
        }
      } else {
        return Left(OfflineFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<MediaEntity>>> getMedia(int playerId) async {
    // First, try to get cached media
    try {
      final cachedMedia = await localDataSource.getCachedMedia(playerId);
      return Right(cachedMedia);
    } on EmptyCacheException {
      // If no cached data, fetch from remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteMedia = await remoteDataSource.getMedia(playerId);
          final entities =
              remoteMedia.map((model) => model.toEntity()).toList();
          // Cache the fetched media
          await localDataSource.cacheMedia(entities, playerId);
          return Right(entities);
        } on ServerException {
          return Left(ServerFailure());
        } on ServerMessageException catch (e) {
          return Left(ServerMessageFailure(e.message));
        } on OfflineException {
          return Left(OfflineFailure());
        }
      } else {
        return Left(OfflineFailure());
      }
    }
  }
}
