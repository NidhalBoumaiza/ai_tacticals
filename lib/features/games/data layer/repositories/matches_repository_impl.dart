// lib/features/matches/data/repositories/matches_repository_impl.dart
import 'package:analysis_ai/core/network/network_info.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
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

  MatchEventsPerTeamEntity _convertToEntity(List<MatchEventModel> matches) {
    final Map<String, List<MatchEventModel>> groupedMatches = {};
    for (var match in matches) {
      // Group by homeTeam ID (or adjust logic based on your needs)
      final teamId = match.homeTeam?.id?.toString() ?? 'unknown';
      if (!groupedMatches.containsKey(teamId)) {
        groupedMatches[teamId] = [];
      }
      groupedMatches[teamId]!.add(match);
    }
    return MatchEventsPerTeamEntity(
      tournamentTeamEvents: groupedMatches.map(
        (key, value) => MapEntry(key, value.map((m) => m.toEntity()).toList()),
      ),
    );
  }
}
