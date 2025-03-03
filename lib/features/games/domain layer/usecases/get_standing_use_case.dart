import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/standing_entity.dart';
import '../repositories/standing_repository.dart';

class GetStandingsUseCase {
  final StandingsRepository repository;

  GetStandingsUseCase(this.repository);

  @override
  Future<Either<Failure, StandingsEntity>> call(
    int leagueId,
    int seasonId,
  ) async {
    return await repository.getStandings(leagueId, seasonId);
  }
}
