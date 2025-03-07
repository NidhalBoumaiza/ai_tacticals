import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/entities/player_entity.dart';
import '../../domain layer/repositories/players_repository.dart';
import '../data sources/players/player_local_data_source.dart';
import '../data sources/players/players_remote_data_source.dart';

class PlayersRepositoryImpl implements PlayersRepository {
  final PlayersRemoteDataSource remoteDataSource;
  final PlayersLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PlayersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<PlayerEntityy>>> getAllPlayersInfos(
    int teamId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePlayers = await remoteDataSource.getPlayers(teamId);
        await localDataSource.cachePlayers(remotePlayers, teamId);
        return Right(remotePlayers.map((model) => model.toEntity()).toList());
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localPlayers = await localDataSource.getLastPlayers(teamId);
        return Right(localPlayers);
      } on EmptyCacheException {
        return Left(OfflineFailure());
      }
    }
  }
}
