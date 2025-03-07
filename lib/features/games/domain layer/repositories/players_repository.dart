import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/player_entity.dart';

abstract class PlayersRepository {
  Future<Either<Failure, List<PlayerEntityy>>> getAllPlayersInfos(int teamId);
}
