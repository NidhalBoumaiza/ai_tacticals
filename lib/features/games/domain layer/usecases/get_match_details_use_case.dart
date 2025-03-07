// get_match_details_use_case.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data layer/models/one_match_statics_entity.dart';
import '../repositories/one_match_stats_repository.dart';


class GetMatchDetailsUseCase {
  final OneMatchStatsRepository repository;

  GetMatchDetailsUseCase(this.repository);

  Future<Either<Failure, MatchDetails>> call(int matchId) async {
    return await repository.getMatchDetails(matchId);
  }
}