import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data layer/models/one_match_statics_entity.dart';
import '../entities/manager_entity.dart';
import '../entities/player_per_match_entity.dart';

abstract class OneMatchStatsRepository {
  // Existing method
  Future<Either<Failure, MatchDetails>> getMatchDetails(int matchId);

  // Updated method for fetching players
  Future<Either<Failure, Map<String, List<PlayerPerMatchEntity>>>>
  getPlayersPerMatch(int matchId);

  // New method for fetching managers
  Future<Either<Failure, Map<String, ManagerEntity>>> getManagersPerMatch(
    int matchId,
  );
}
