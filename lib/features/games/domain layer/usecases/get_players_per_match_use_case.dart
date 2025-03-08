import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/player_per_match_entity.dart';
import '../repositories/one_match_stats_repository.dart';

class GetPlayersPerMatchUseCase {
  final OneMatchStatsRepository repository;

  GetPlayersPerMatchUseCase(this.repository);

  Future<Either<Failure, Map<String, List<PlayerPerMatchEntity>>>> call(
    int matchId,
  ) async {
    return await repository.getPlayersPerMatch(matchId);
  }
}
