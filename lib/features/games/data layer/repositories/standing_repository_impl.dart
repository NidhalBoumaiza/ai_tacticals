// lib/features/standings/data_layer/repositories/standings_repository_impl.dart
import 'package:analysis_ai/core/error/exceptions.dart';
import 'package:analysis_ai/core/error/failures.dart';
import 'package:analysis_ai/core/network/network_info.dart';
import 'package:analysis_ai/features/games/domain%20layer/entities/season_entity.dart';
import 'package:dartz/dartz.dart';

import '../../domain layer/entities/standing_entity.dart';
import '../../domain layer/repositories/standing_repository.dart';
import '../data sources/standing/standing_local_data_source.dart';
import '../data sources/standing/standing_remote_date_source.dart';

class StandingsRepositoryImpl implements StandingsRepository {
  final StandingsRemoteDataSource remoteDataSource;
  final StandingsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  StandingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, StandingsEntity>> getStandings(
    int leagueId,
    int seasonId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteStandings = await remoteDataSource.getStandings(
          leagueId,
          seasonId,
        );
        await localDataSource.cacheStandings(
          remoteStandings,
          leagueId,
          seasonId,
        );
        return Right(remoteStandings);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localStandings = await localDataSource.getLastStandings(
          leagueId,
          seasonId,
        );
        return Right(localStandings);
      } on EmptyCacheException {
        return Left(
          OfflineFailure(),
        ); // Return OfflineFailure if no cache and offline
      }
    }
  }

  @override
  Future<Either<Failure, List<SeasonEntity>>> getSeasonsByTournamentId(
    int uniqueTournamentId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final seasons = await remoteDataSource.getSeasonsByTournamentId(
          uniqueTournamentId,
        );
        return Right(seasons);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}
