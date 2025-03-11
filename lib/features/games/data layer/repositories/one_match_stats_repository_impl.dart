import 'package:dartz/dartz.dart';
import 'package:get/get.dart'; // For showing snackbar

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/entities/manager_entity.dart';
import '../../domain layer/entities/one_match_statics_entity.dart'
    as one_match_entities;
import '../../domain layer/entities/player_per_match_entity.dart';
import '../../domain layer/repositories/one_match_stats_repository.dart';
import '../data sources/one match details/one_match_local_data_source_impl.dart';
import '../data sources/one match details/one_match_remote_data_source_impl.dart';
import '../models/manager_model.dart';
import '../models/one_match_statics_entity.dart';
import '../models/player_per_match_model.dart';

class OneMatchStatsRepositoryImpl implements OneMatchStatsRepository {
  final OneMatchRemoteDataSource remoteDataSource;
  final OneMatchLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  OneMatchStatsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, MatchDetails>> getMatchDetails(int matchId) async {
    if (await networkInfo.isConnected) {
      try {
        // Fetch data from remote source with timeout
        final remoteEvent = await remoteDataSource.getMatchEvent(matchId);
        final remoteStats = await remoteDataSource.getMatchStatistics(matchId);

        // Cache the data locally
        await localDataSource.cacheMatchDetails(
          remoteEvent,
          remoteStats,
          matchId,
        );

        // Convert JSON to entities
        final eventEntity = one_match_entities.MatchEventEntity.fromJson(
          remoteEvent,
        );
        final statsEntity = one_match_entities.MatchStatisticsEntity.fromJson(
          remoteStats,
        );

        // Convert to MatchDetails model
        return Right(MatchDetails.fromEntities(eventEntity, statsEntity));
      } on ServerException {
        return Left(ServerFailure());
      } on TimeoutException {
        Get.snackbar(
          'timeout_error_title'.tr, // Add to your translations
          'timeout_failure_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return Left(TimeoutFailure());
      } on ServerMessageException {
        return Left(ServerMessageFailure("No data available for this match"));
      }
    } else {
      try {
        // Fetch cached data from local source
        final localEvent = await localDataSource.getLastMatchEvent(matchId);
        final localStats = await localDataSource.getLastMatchStatistics(
          matchId,
        );

        // Convert JSON to entities
        final eventEntity = one_match_entities.MatchEventEntity.fromJson(
          localEvent,
        );
        final statsEntity = one_match_entities.MatchStatisticsEntity.fromJson(
          localStats,
        );

        // Convert to MatchDetails model
        return Right(MatchDetails.fromEntities(eventEntity, statsEntity));
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }

  // Rest of the code remains unchanged...

  @override
  Future<Either<Failure, Map<String, List<PlayerPerMatchEntity>>>>
  getPlayersPerMatch(int matchId) async {
    if (await networkInfo.isConnected) {
      try {
        // Fetch players data from remote source
        final remotePlayers = await remoteDataSource.getPlayersPerMatch(
          matchId,
        );

        // Extract home and away team IDs
        final homeTeamId =
            remotePlayers['home']?.isNotEmpty == true
                ? remotePlayers['home']![0].teamId
                : 0;
        final awayTeamId =
            remotePlayers['away']?.isNotEmpty == true
                ? remotePlayers['away']![0].teamId
                : 0;

        // Convert PlayerPerMatchModel lists to JSON (Map<String, dynamic>) for caching
        final homePlayersJson =
            (remotePlayers['home'] ?? [])
                .cast<PlayerPerMatchModel>() // Cast to PlayerPerMatchModel
                .map((player) => player.toJson())
                .toList();
        final awayPlayersJson =
            (remotePlayers['away'] ?? [])
                .cast<PlayerPerMatchModel>() // Cast to PlayerPerMatchModel
                .map((player) => player.toJson())
                .toList();

        // Cache the players data locally
        await localDataSource.cachePlayersPerMatch([
          ...homePlayersJson,
          ...awayPlayersJson,
        ], matchId);

        // Return the grouped players
        return Right(remotePlayers);
      } on ServerException {
        return Left(ServerFailure());
      } on TimeoutException {
        Get.snackbar(
          'timeout_error_title'.tr,
          'timeout_failure_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return Left(TimeoutFailure());
      }
    } else {
      try {
        // Fetch cached players data from local source
        final localPlayers = await localDataSource.getLastPlayersPerMatch(
          matchId,
        );

        // Extract home and away team IDs from the first player (if available)
        final homeTeamId =
            localPlayers.isNotEmpty
                ? localPlayers[0]['teamId'] as int? ?? 0
                : 0;
        final awayTeamId =
            localPlayers.length > 1
                ? localPlayers[1]['teamId'] as int? ?? 0
                : 0;

        // Convert to PlayerPerMatchEntity list
        final homePlayers =
            localPlayers
                .where((player) => player['teamId'] == homeTeamId)
                .map((player) => PlayerPerMatchModel.fromJson(player))
                .toList();

        final awayPlayers =
            localPlayers
                .where((player) => player['teamId'] == awayTeamId)
                .map((player) => PlayerPerMatchModel.fromJson(player))
                .toList();

        return Right({'home': homePlayers, 'away': awayPlayers});
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }

  @override
  Future<Either<Failure, Map<String, ManagerEntity>>> getManagersPerMatch(
    int matchId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        // Fetch managers data from remote source
        final remoteManagers = await remoteDataSource.getManagersPerMatch(
          matchId,
        );

        // Cache the managers data locally
        await localDataSource.cacheManagersPerMatch(remoteManagers, matchId);

        // Convert to ManagerEntity map
        final managersMap = {
          'homeManager': ManagerModel.fromJson(remoteManagers['homeManager']),
          'awayManager': ManagerModel.fromJson(remoteManagers['awayManager']),
        };
        return Right(managersMap);
      } on ServerException {
        return Left(ServerFailure());
      } on TimeoutException {
        Get.snackbar(
          'timeout_error_title'.tr,
          'timeout_failure_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return Left(TimeoutFailure());
      }
    } else {
      try {
        // Fetch cached managers data from local source
        final localManagers = await localDataSource.getLastManagersPerMatch(
          matchId,
        );

        // Convert to ManagerEntity map
        final managersMap = {
          'homeManager': ManagerModel.fromJson(localManagers['homeManager']),
          'awayManager': ManagerModel.fromJson(localManagers['awayManager']),
        };
        return Right(managersMap);
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }
}
