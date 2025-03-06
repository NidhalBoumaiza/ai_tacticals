import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/matches_entities.dart';

abstract class MatchesRepository {
  Future<Either<Failure, MatchEventsPerTeamEntity>> getMatchesPerTeam(
    int uniqueTournamentId,
    int seasonId,
  );
}
