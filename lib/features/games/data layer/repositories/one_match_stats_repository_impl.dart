import 'package:dartz/dartz.dart';
import 'package:get/get.dart'; // For showing snackbar
import 'package:flutter/foundation.dart'; // For compute

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/entities/manager_entity.dart';
import '../../domain layer/entities/one_match_statics_entity.dart' as one_match_entities;
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
        // Fetch data from remote source
        final remoteEvent = await remoteDataSource.getMatchEvent(matchId);
        final remoteStats = await remoteDataSource.getMatchStatistics(matchId);

        // Convert event JSON to entity
        final eventEntity = one_match_entities.MatchEventEntity.fromJson(remoteEvent);

        // Handle stats response
        late one_match_entities.MatchStatisticsEntity statsEntity;
        if (remoteStats.containsKey('error') && remoteStats['error']['code'] == 404) {
          // If stats return 404, use empty stats
          statsEntity = one_match_entities.MatchStatisticsEntity(statistics: []);
        } else {
          // Otherwise, parse the stats
          statsEntity = one_match_entities.MatchStatisticsEntity.fromJson(remoteStats);
        }

        // Cache the data locally (convert entities back to JSON for caching)
        await localDataSource.cacheMatchDetails(
          remoteEvent,  // Use original JSON for event
          remoteStats.containsKey('error') ? {'statistics': []} : remoteStats,  // Cache empty stats for 404
          matchId,
        );

        // Convert to MatchDetails model
        return Right(MatchDetails.fromEntities(eventEntity, statsEntity));
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
      } on ServerMessageException {
        return Left(ServerMessageFailure("No data available for this match"));
      }
    } else {
      try {
        // Fetch cached data from local source
        final localEvent = await localDataSource.getLastMatchEvent(matchId);
        final localStats = await localDataSource.getLastMatchStatistics(matchId);

        // Convert JSON to entities
        final eventEntity = one_match_entities.MatchEventEntity.fromJson(localEvent);
        final statsEntity = one_match_entities.MatchStatisticsEntity.fromJson(localStats);

        // Convert to MatchDetails model
        return Right(MatchDetails.fromEntities(eventEntity, statsEntity));
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }

  @override
  Future<Either<Failure, Map<String, List<PlayerPerMatchEntity>>>> getPlayersPerMatch(int matchId) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePlayers = await remoteDataSource.getPlayersPerMatch(matchId);

        final homeTeamId = remotePlayers['home']?.isNotEmpty == true ? remotePlayers['home']![0].teamId : 0;
        final awayTeamId = remotePlayers['away']?.isNotEmpty == true ? remotePlayers['away']![0].teamId : 0;

        final homePlayersJson = (remotePlayers['home'] ?? [])
            .cast<PlayerPerMatchModel>()
            .map((player) => player.toJson())
            .toList();
        final awayPlayersJson = (remotePlayers['away'] ?? [])
            .cast<PlayerPerMatchModel>()
            .map((player) => player.toJson())
            .toList();

        await localDataSource.cachePlayersPerMatch([...homePlayersJson, ...awayPlayersJson], matchId);

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
        final localPlayers = await localDataSource.getLastPlayersPerMatch(matchId);

        final homeTeamId = localPlayers.isNotEmpty ? localPlayers[0]['teamId'] as int? ?? 0 : 0;
        final awayTeamId = localPlayers.length > 1 ? localPlayers[1]['teamId'] as int? ?? 0 : 0;

        final homePlayers = localPlayers
            .where((player) => player['teamId'] == homeTeamId)
            .map((player) => PlayerPerMatchModel.fromJson(player))
            .toList();
        final awayPlayers = localPlayers
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
  Future<Either<Failure, Map<String, ManagerEntity>>> getManagersPerMatch(int matchId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteManagers = await remoteDataSource.getManagersPerMatch(matchId);

        await localDataSource.cacheManagersPerMatch(remoteManagers, matchId);

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
        final localManagers = await localDataSource.getLastManagersPerMatch(matchId);

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