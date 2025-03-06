// features/players/domain/repositories/player_details_repository.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/player_statics_entity.dart';

abstract class PlayerDetailsRepository {
  Future<Either<Failure, PlayerAttributesEntity>> getPlayerAttributes(
    int playerId,
  );

  Future<Either<Failure, NationalTeamEntity>> getNationalTeamStats(
    int playerId,
  );

  Future<Either<Failure, List<MatchPerformanceEntity>>> getLastYearSummary(
    int playerId,
  );

  Future<Either<Failure, List<TransferEntity>>> getTransferHistory(
    int playerId,
  );

  Future<Either<Failure, List<MediaEntity>>> getMedia(int playerId);
}
