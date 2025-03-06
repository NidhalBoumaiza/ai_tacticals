import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/statics_entity.dart';
import '../repositories/statics_repository.dart';

class GetTeamStatsUseCAse {
  final StaticsRepository repository;

  GetTeamStatsUseCAse(this.repository);

  Future<Either<Failure, StatsEntity>> call(
    int teamId,
    int tournamentId,
    int seasonId,
  ) async {
    return await repository.getTeamStats(teamId, tournamentId, seasonId);
  }
}
