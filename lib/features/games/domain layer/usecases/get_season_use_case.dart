// lib/features/standings/domain_layer/use_cases/get_seasons_use_case.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/season_entity.dart';
import '../repositories/standing_repository.dart';

class GetSeasonsUseCase {
  final StandingsRepository repository;

  GetSeasonsUseCase(this.repository);

  Future<Either<Failure, List<SeasonEntity>>> call(
    int uniqueTournamentId,
  ) async {
    return await repository.getSeasonsByTournamentId(uniqueTournamentId);
  }
}
