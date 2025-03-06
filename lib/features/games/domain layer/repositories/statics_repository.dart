import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/statics_entity.dart';

abstract class StaticsRepository {
  Future<Either<Failure, StatsEntity>> getTeamStats(
    int teamId,
    int tournamentId,
    int seasonId,
  );
}
