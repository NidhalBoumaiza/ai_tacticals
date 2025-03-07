// one_match_stats_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart'; // For showing snackbar

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/repositories/one_match_stats_repository.dart';
import '../data sources/one match details/one_match_local_data_source_impl.dart';
import '../data sources/one match details/one_match_remote_data_source_impl.dart';
import '../models/one_match_statics_entity.dart';


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
        await localDataSource.cacheMatchDetails(remoteEvent, remoteStats, matchId);

        // Convert to MatchDetails model
        return Right(MatchDetails.fromEntities(remoteEvent, remoteStats));
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
      }
    } else {
      try {
        // Fetch cached data from local source
        final localEvent = await localDataSource.getLastMatchEvent(matchId);
        final localStats = await localDataSource.getLastMatchStatistics(matchId);

        // Convert to MatchDetails model
        return Right(MatchDetails.fromEntities(localEvent, localStats));
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }
}