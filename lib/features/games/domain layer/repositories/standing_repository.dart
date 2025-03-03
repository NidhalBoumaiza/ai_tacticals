// lib/features/standings/domain_layer/repositories/standings_repository.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/season_entity.dart';
import '../entities/standing_entity.dart';

abstract class StandingsRepository {
  Future<Either<Failure, StandingsEntity>> getStandings(
    int leagueId,
    int seasonId,
  );

  Future<Either<Failure, List<SeasonEntity>>> getSeasonsByTournamentId(
    int uniqueTournamentId,
  ); // Added
}
