// one_match_stats_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data layer/models/one_match_statics_entity.dart';

abstract class OneMatchStatsRepository {
  Future<Either<Failure, MatchDetails>> getMatchDetails(int matchId);
}