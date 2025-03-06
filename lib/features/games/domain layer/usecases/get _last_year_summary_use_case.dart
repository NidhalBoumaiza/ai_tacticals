// features/players/domain/usecases/get_last_year_summary_usecase.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/player_statics_entity.dart';
import '../repositories/player_details_repository.dart';

class GetLastYearSummaryUseCase {
  final PlayerDetailsRepository repository;

  GetLastYearSummaryUseCase(this.repository);

  Future<Either<Failure, List<MatchPerformanceEntity>>> call(
    int playerId,
  ) async {
    return await repository.getLastYearSummary(playerId);
  }
}
