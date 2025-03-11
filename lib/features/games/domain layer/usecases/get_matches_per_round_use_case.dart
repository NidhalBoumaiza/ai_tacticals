// lib/features/games/domain layer/usecases/get_matches_per_round_use_case.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:analysis_ai/features/games/domain layer/entities/matches_entities.dart';
import 'package:analysis_ai/features/games/domain layer/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class GetMatchesPerRound {
  final MatchesRepository repository;

  GetMatchesPerRound(this.repository);

  Future<Either<Failure, List<MatchEventEntity>>> call({
    required int leagueId,
    required int seasonId,
    required int round,
  }) async {
    return await repository.getMatchesPerRound(leagueId, seasonId, round);
  }
}
