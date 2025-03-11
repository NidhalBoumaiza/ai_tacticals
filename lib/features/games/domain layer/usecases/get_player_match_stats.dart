import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/player_entity.dart';
import '../repositories/player_match_stats_repository.dart';

class GetPlayerMatchStats {
  final PlayerMatchStatsRepository repository;

  GetPlayerMatchStats(this.repository);

  Future<Either<Failure, PlayerEntityy>> call({
    required int matchId,
    required int playerId,
  }) async {
    return await repository.getPlayerMatchStats(
      matchId: matchId,
      playerId: playerId,
    );
  }
}
