// matches_repository_impl.dart
import 'package:analysis_ai/core/network/network_info.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../domain layer/entities/matches_entities.dart';
import '../../domain layer/repositories/matches_repository.dart';
import '../data sources/matches/matches_local_data_source.dart';
import '../data sources/matches/matches_remote_data_source.dart';
import '../models/matches_models.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  final MatchesRemoteDataSource remoteDataSource;
  final MatchesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  MatchesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, MatchEventsPerTeamEntity>> getMatchesPerTeam(
    int uniqueTournamentId,
    int seasonId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMatches = await remoteDataSource.getMatchesPerTeam(
          uniqueTournamentId,
          seasonId,
        );
        final entity = _convertToEntity(remoteMatches);

        await localDataSource.cacheMatchesPerTeam(
          entity,
          uniqueTournamentId,
          seasonId,
        );
        return Right(entity);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localMatches = await localDataSource.getLastMatchesPerTeam(
          uniqueTournamentId,
          seasonId,
        );
        return Right(localMatches);
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }

  @override
  Future<Either<Failure, MatchEventsPerTeamEntity>> getHomeMatches(
    String date,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMatches = await remoteDataSource.getHomeMatches(date);
        final entity = _convertToEntity(remoteMatches);
        await localDataSource.cacheHomeMatches(entity, date);
        return Right(entity);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localMatches = await localDataSource.getLastHomeMatches(date);
        return Right(localMatches);
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<MatchEventEntity>>> getMatchesPerRound(
    int leagueId,
    int seasonId,
    int round,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMatches = await remoteDataSource.getMatchesPerRound(
          leagueId,
          seasonId,
          round,
        );
        await localDataSource.cacheMatchesPerRound(
          remoteMatches,
          leagueId,
          seasonId,
          round,
        );
        return Right(remoteMatches.map((model) => model.toEntity()).toList());
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localMatches = await localDataSource.getLastMatchesPerRound(
          leagueId,
          seasonId,
          round,
        );
        return Right(localMatches);
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }

  MatchEventsPerTeamEntity _convertToEntity(MatchEventsPerTeamModel matches) {
    return matches.toEntity();
  }
}
