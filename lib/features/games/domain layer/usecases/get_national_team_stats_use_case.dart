// features/players/domain/usecases/get_national_team_stats_usecase.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/player_statics_entity.dart';
import '../repositories/player_details_repository.dart';

class GetNationalTeamStatsUseCase {
  final PlayerDetailsRepository repository;

  GetNationalTeamStatsUseCase(this.repository);

  Future<Either<Failure, NationalTeamEntity>> call(int playerId) async {
    return await repository.getNationalTeamStats(playerId);
  }
}
