import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/matches_entities.dart';
import '../repositories/matches_repository.dart';

class GetMatchesPerTeam {
  final MatchesRepository repository;

  GetMatchesPerTeam(this.repository);

  Future<Either<Failure, MatchEventsPerTeamEntity>> call({
    required int uniqueTournamentId,
    required int seasonId,
  }) async {
    return await repository.getMatchesPerTeam(uniqueTournamentId, seasonId);
  }
}
