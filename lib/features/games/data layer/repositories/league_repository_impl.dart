import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/entities/league_entity.dart';
import '../../domain layer/repositories/league_repository.dart';
import '../data sources/leagues/leagues_local_data_source.dart';
import '../data sources/leagues/leagues_remote_data_source.dart';
import '../models/league_model.dart';

class LeaguesRepositoryImpl implements LeaguesRepository {
  final LeaguesRemoteDataSource leaguesRemoteDataSource;
  final LeaguesLocalDataSource leaguesLocalDataSource;
  final NetworkInfo networkInfo;

  LeaguesRepositoryImpl({
    required this.leaguesRemoteDataSource,
    required this.leaguesLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<LeagueEntity>>> getLeaguesByCountryId(
    int countryId,
  ) async {
    // First, check if leagues for this country are already cached
    try {
      final List<LeagueModel> cachedLeagues = await leaguesLocalDataSource
          .getCachedLeagues(countryId);
      final List<LeagueEntity> leagues =
          cachedLeagues
              .map(
                (leagueModel) =>
                    LeagueEntity(id: leagueModel.id, name: leagueModel.name),
              )
              .toList();
      return Right(leagues); // Return cached leagues if available
    } on EmptyCacheException {
      // If no cached leagues, proceed with network request if connected
      if (await networkInfo.isConnected) {
        try {
          final List<LeagueModel> leagueModels = await leaguesRemoteDataSource
              .getLeaguesByCountryId(countryId);
          // Cache the leagues locally for offline access
          await leaguesLocalDataSource.cacheLeagues(leagueModels, countryId);
          // Convert LeagueModel list to LeagueEntity list
          final List<LeagueEntity> leagues =
              leagueModels
                  .map(
                    (leagueModel) => LeagueEntity(
                      id: leagueModel.id,
                      name: leagueModel.name,
                    ),
                  )
                  .toList();
          return Right(leagues);
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
        // If no internet and no cached data, return OfflineFailure
        return Left(OfflineFailure());
      }
    }
  }
}
