import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manager_entity.dart';
import '../repositories/one_match_stats_repository.dart';

class GetManagersPerMatchUseCase {
  final OneMatchStatsRepository repository;

  GetManagersPerMatchUseCase(this.repository);

  Future<Either<Failure, Map<String, ManagerEntity>>> call(int matchId) async {
    return await repository.getManagersPerMatch(matchId);
  }
}
