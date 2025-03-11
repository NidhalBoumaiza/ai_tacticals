import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/player_entity.dart';

abstract class PlayerMatchStatsRepository {
  Future<Either<Failure, PlayerEntityy>> getPlayerMatchStats({
    required int matchId,
    required int playerId,
  });
}
