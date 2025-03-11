import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/matches_entities.dart';
import '../repositories/matches_repository.dart';

class GetHomeMatchesUseCase {
  final MatchesRepository repository;

  GetHomeMatchesUseCase(this.repository);

  Future<Either<Failure, MatchEventsPerTeamEntity>> call(String date) async {
    return await repository.getHomeMatches(date);
  }
}
